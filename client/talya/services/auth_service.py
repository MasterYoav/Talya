from __future__ import annotations

import base64
import hashlib
import os
import threading
import time
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer

import requests

from talya.infrastructure.token_store import TokenStore


class OAuthCallbackServer:
    def __init__(self, port: int = 0, path: str = "/oauth/callback") -> None:
        self.code: str | None = None
        self.error: str | None = None
        self.state: str | None = None
        self._event = threading.Event()
        self._httpd: HTTPServer | None = None
        self._port = port
        self._path = path

    def start(self) -> str:
        self._httpd = HTTPServer(("127.0.0.1", self._port), self._build_handler())
        thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        thread.start()
        host, port = self._httpd.server_address[:2]
        return f"http://{host}:{port}{self._path}"

    def wait(self, timeout: int = 180) -> bool:
        return self._event.wait(timeout)

    def shutdown(self) -> None:
        if self._httpd is not None:
            self._httpd.shutdown()

    def _build_handler(self) -> type[BaseHTTPRequestHandler]:
        outer = self

        class CallbackHandler(BaseHTTPRequestHandler):
            def do_GET(self) -> None:
                parsed = urllib.parse.urlparse(self.path)
                if parsed.path != outer._path:
                    self.send_response(404)
                    self.end_headers()
                    return

                params = urllib.parse.parse_qs(parsed.query)
                outer.code = params.get("code", [None])[0]
                outer.state = params.get("state", [None])[0]
                outer.error = params.get("error", [None])[0]

                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(
                    b"<html><body><h2>You can close this window.</h2></body></html>"
                )
                outer._event.set()

            def log_message(self, format: str, *args: object) -> None:
                return

        return CallbackHandler


class AuthService:
    GOOGLE_CLIENT_ID = os.getenv("TALYA_GOOGLE_CLIENT_ID", "")
    GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
    GOOGLE_DEVICE_CODE_URL = "https://oauth2.googleapis.com/device/code"
    GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"
    GOOGLE_SCOPES = [
        "openid",
        "email",
        "profile",
        "https://www.googleapis.com/auth/calendar",
    ]
    GOOGLE_CLIENT_SECRET = os.getenv("TALYA_GOOGLE_CLIENT_SECRET", "")
    GOOGLE_REDIRECT_PORT = int(os.getenv("TALYA_GOOGLE_REDIRECT_PORT", "8764"))
    GITHUB_CLIENT_ID = os.getenv("TALYA_GITHUB_CLIENT_ID", "")
    GITHUB_CLIENT_SECRET = os.getenv("TALYA_GITHUB_CLIENT_SECRET", "")
    GITHUB_AUTH_URL = "https://github.com/login/oauth/authorize"
    GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token"
    GITHUB_USER_URL = "https://api.github.com/user"
    GITHUB_EMAILS_URL = "https://api.github.com/user/emails"
    GITHUB_SCOPES = ["read:user", "user:email"]
    GITHUB_REDIRECT_PORT = int(os.getenv("TALYA_GITHUB_REDIRECT_PORT", "8765"))

    def __init__(self) -> None:
        self._token_store = TokenStore()

    def authenticate_with_google(self) -> dict:
        verifier = self._generate_code_verifier()
        challenge = self._generate_code_challenge(verifier)
        state = self._generate_state()

        if not self.GOOGLE_CLIENT_SECRET:
            return {"error": "Google OAuth client secret is missing."}

        callback_server = OAuthCallbackServer(
            port=self.GOOGLE_REDIRECT_PORT, path="/oauth/google"
        )
        try:
            redirect_uri = callback_server.start()
        except OSError:
            return {"error": f"Port {self.GOOGLE_REDIRECT_PORT} is already in use."}

        auth_params = {
            "client_id": self.GOOGLE_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(self.GOOGLE_SCOPES),
            "state": state,
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "access_type": "offline",
            "prompt": "consent",
        }
        auth_url = f"{self.GOOGLE_AUTH_URL}?{urllib.parse.urlencode(auth_params)}"
        webbrowser.open(auth_url, new=1, autoraise=True)

        if not callback_server.wait():
            callback_server.shutdown()
            return {"error": "Login timed out. Try again."}

        callback_server.shutdown()

        if callback_server.error:
            return {"error": f"Login failed: {callback_server.error}"}
        if callback_server.state != state:
            return {"error": "Login failed: invalid state."}
        if not callback_server.code:
            return {"error": "Login failed: missing authorization code."}

        token_payload = {
            "client_id": self.GOOGLE_CLIENT_ID,
            "code": callback_server.code,
            "code_verifier": verifier,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        }
        token_payload["client_secret"] = self.GOOGLE_CLIENT_SECRET
        token_response = requests.post(
            self.GOOGLE_TOKEN_URL,
            data=token_payload,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=30,
        )
        if token_response.status_code != 200:
            return {
                "error": (
                    "Token exchange failed. "
                    f"Status {token_response.status_code}: {token_response.text}"
                )
            }
        tokens = token_response.json()

        access_token = tokens.get("access_token")
        if not access_token:
            return {"error": "Token exchange failed: missing access token."}

        profile_response = requests.get(
            self.GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=30,
        )
        if profile_response.status_code != 200:
            return {"error": "Failed to fetch profile."}
        profile = profile_response.json()

        name = profile.get("name", "").strip() or "Google User"
        email = profile.get("email", "").strip()
        provider_user_id = str(profile.get("sub", "")).strip()

        self._token_store.save("google_tokens", tokens)
        self._token_store.save("profile", {"name": name, "email": email})
        self._token_store.save(
            "identity",
            {
                "provider": "google",
                "provider_user_id": provider_user_id,
            },
        )

        return {
            "name": name,
            "email": email,
            "provider": "google",
            "provider_user_id": provider_user_id,
            "account_id": email or name,
        }

    def authenticate_google_calendar(self) -> dict:
        verifier = self._generate_code_verifier()
        challenge = self._generate_code_challenge(verifier)
        state = self._generate_state()

        if not self.GOOGLE_CLIENT_SECRET:
            return {"error": "Google OAuth client secret is missing."}

        callback_server = OAuthCallbackServer(
            port=self.GOOGLE_REDIRECT_PORT, path="/oauth/google"
        )
        try:
            redirect_uri = callback_server.start()
        except OSError:
            return {"error": f"Port {self.GOOGLE_REDIRECT_PORT} is already in use."}

        auth_params = {
            "client_id": self.GOOGLE_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(self.GOOGLE_SCOPES),
            "state": state,
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "access_type": "offline",
            "prompt": "consent",
        }
        auth_url = f"{self.GOOGLE_AUTH_URL}?{urllib.parse.urlencode(auth_params)}"
        webbrowser.open(auth_url, new=1, autoraise=True)

        if not callback_server.wait():
            callback_server.shutdown()
            return {"error": "Login timed out. Try again."}

        callback_server.shutdown()

        if callback_server.error:
            return {"error": f"Login failed: {callback_server.error}"}
        if callback_server.state != state:
            return {"error": "Login failed: invalid state."}
        if not callback_server.code:
            return {"error": "Login failed: missing authorization code."}

        token_payload = {
            "client_id": self.GOOGLE_CLIENT_ID,
            "code": callback_server.code,
            "code_verifier": verifier,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        }
        token_payload["client_secret"] = self.GOOGLE_CLIENT_SECRET
        token_response = requests.post(
            self.GOOGLE_TOKEN_URL,
            data=token_payload,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=30,
        )
        if token_response.status_code != 200:
            return {
                "error": (
                    "Token exchange failed. "
                    f"Status {token_response.status_code}: {token_response.text}"
                )
            }
        tokens = token_response.json()
        access_token = tokens.get("access_token")
        if not access_token:
            return {"error": "Token exchange failed: missing access token."}

        self._token_store.save("google_calendar_tokens", tokens)
        return {"status": "ok"}

    def start_google_device_flow(self) -> dict:
        payload = {
            "client_id": self.GOOGLE_CLIENT_ID,
            "scope": " ".join(self.GOOGLE_SCOPES),
        }
        response = requests.post(
            self.GOOGLE_DEVICE_CODE_URL,
            data=payload,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=30,
        )
        if response.status_code != 200:
            return {
                "error": (
                    "Device flow start failed. "
                    f"Status {response.status_code}: {response.text}"
                )
            }
        return response.json()

    def poll_google_device_flow(
        self, device_code: str, interval: int, expires_in: int
    ) -> dict:
        deadline = time.time() + expires_in
        current_interval = max(interval, 1)
        while time.time() < deadline:
            token_payload = {
                "client_id": self.GOOGLE_CLIENT_ID,
                "device_code": device_code,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            }
            if self.GOOGLE_CLIENT_SECRET:
                token_payload["client_secret"] = self.GOOGLE_CLIENT_SECRET
            token_response = requests.post(
                self.GOOGLE_TOKEN_URL,
                data=token_payload,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=30,
            )
            if token_response.status_code == 200:
                tokens = token_response.json()
                access_token = tokens.get("access_token")
                if not access_token:
                    return {"error": "Token exchange failed: missing access token."}

                profile_response = requests.get(
                    self.GOOGLE_USERINFO_URL,
                    headers={"Authorization": f"Bearer {access_token}"},
                    timeout=30,
                )
                if profile_response.status_code != 200:
                    return {"error": "Failed to fetch profile."}
                profile = profile_response.json()

                name = profile.get("name", "").strip() or "Google User"
                email = profile.get("email", "").strip()

                self._token_store.save("google_tokens", tokens)
                self._token_store.save("profile", {"name": name, "email": email})

                return {"name": name, "email": email}

            if token_response.status_code == 400:
                error_payload = token_response.json()
                error = error_payload.get("error")
                if error == "authorization_pending":
                    time.sleep(current_interval)
                    continue
                if error == "slow_down":
                    current_interval += 5
                    time.sleep(current_interval)
                    continue
                if error == "access_denied":
                    return {"error": "Google sign-in was denied."}
                if error == "expired_token":
                    return {"error": "Google sign-in expired. Try again."}

            return {
                "error": (
                    "Token exchange failed. "
                    f"Status {token_response.status_code}: {token_response.text}"
                )
            }

        return {"error": "Google sign-in timed out. Try again."}

    def authenticate_with_github(self) -> dict:
        if not self.GITHUB_CLIENT_ID:
            return {"error": "GitHub OAuth client ID is missing."}
        if not self.GITHUB_CLIENT_SECRET:
            return {"error": "GitHub OAuth client secret is missing."}

        state = self._generate_state()
        callback_server = OAuthCallbackServer(
            port=self.GITHUB_REDIRECT_PORT, path="/oauth/github"
        )
        try:
            redirect_uri = callback_server.start()
        except OSError:
            return {"error": f"Port {self.GITHUB_REDIRECT_PORT} is already in use."}

        auth_params = {
            "client_id": self.GITHUB_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(self.GITHUB_SCOPES),
            "state": state,
        }
        auth_url = f"{self.GITHUB_AUTH_URL}?{urllib.parse.urlencode(auth_params)}"
        webbrowser.open(auth_url, new=1, autoraise=True)

        if not callback_server.wait():
            callback_server.shutdown()
            return {"error": "Login timed out. Try again."}

        callback_server.shutdown()

        if callback_server.error:
            return {"error": f"Login failed: {callback_server.error}"}
        if callback_server.state != state:
            return {"error": "Login failed: invalid state."}
        if not callback_server.code:
            return {"error": "Login failed: missing authorization code."}

        token_payload = {
            "client_id": self.GITHUB_CLIENT_ID,
            "client_secret": self.GITHUB_CLIENT_SECRET,
            "code": callback_server.code,
            "redirect_uri": redirect_uri,
        }
        token_response = requests.post(
            self.GITHUB_TOKEN_URL,
            data=token_payload,
            headers={"Accept": "application/json"},
            timeout=30,
        )
        if token_response.status_code != 200:
            return {
                "error": (
                    "Token exchange failed. "
                    f"Status {token_response.status_code}: {token_response.text}"
                )
            }
        tokens = token_response.json()
        access_token = tokens.get("access_token")
        if not access_token:
            return {"error": "Token exchange failed: missing access token."}

        profile_response = requests.get(
            self.GITHUB_USER_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/vnd.github+json",
            },
            timeout=30,
        )
        if profile_response.status_code != 200:
            return {"error": "Failed to fetch GitHub profile."}
        profile = profile_response.json()

        name = (profile.get("name") or profile.get("login") or "GitHub User").strip()
        email = (profile.get("email") or "").strip()
        provider_user_id = str(profile.get("id") or "").strip()

        if not email:
            emails_response = requests.get(
                self.GITHUB_EMAILS_URL,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Accept": "application/vnd.github+json",
                },
                timeout=30,
            )
            if emails_response.status_code == 200:
                emails = emails_response.json()
                primary = next(
                    (
                        entry
                        for entry in emails
                        if entry.get("primary") and entry.get("verified")
                    ),
                    None,
                )
                if primary:
                    email = primary.get("email", "").strip()

        self._token_store.save("github_tokens", tokens)
        self._token_store.save("profile", {"name": name, "email": email})
        self._token_store.save(
            "identity",
            {
                "provider": "github",
                "provider_user_id": provider_user_id,
            },
        )

        return {
            "name": name,
            "email": email,
            "provider": "github",
            "provider_user_id": provider_user_id,
            "account_id": email or name,
        }

    def load_cached_profile(self) -> dict | None:
        return self._token_store.load("profile")

    def load_cached_identity(self) -> dict | None:
        return self._token_store.load("identity")

    def load_cached_provider_tokens(self, provider: str) -> dict | None:
        if provider == "google":
            return self._token_store.load("google_tokens")
        if provider == "github":
            return self._token_store.load("github_tokens")
        return None

    def load_google_calendar_tokens(self) -> dict | None:
        return self._token_store.load("google_calendar_tokens")

    def save_profile(self, name: str, email: str) -> None:
        self._token_store.save("profile", {"name": name, "email": email})

    def clear_profile(self) -> None:
        self._token_store.clear("profile")
        self._token_store.clear("google_tokens")
        self._token_store.clear("github_tokens")
        self._token_store.clear("identity")
        self._token_store.clear("server_token")
        self._token_store.clear("google_calendar_tokens")

    @staticmethod
    def _generate_code_verifier() -> str:
        return base64.urlsafe_b64encode(os.urandom(64)).decode("utf-8").rstrip("=")

    @staticmethod
    def _generate_code_challenge(verifier: str) -> str:
        digest = hashlib.sha256(verifier.encode("utf-8")).digest()
        return base64.urlsafe_b64encode(digest).decode("utf-8").rstrip("=")

    @staticmethod
    def _generate_state() -> str:
        return base64.urlsafe_b64encode(os.urandom(32)).decode("utf-8").rstrip("=")
