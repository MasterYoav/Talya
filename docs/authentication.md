# Authentication

## Current Approach

Talya uses a browser-based Google OAuth flow with a fixed loopback callback and
client secret. The app opens the system browser and receives the auth code on a
local callback.

- Redirect URI: `http://127.0.0.1:8764/oauth/google`
- OAuth flow: Authorization Code + PKCE
- Token storage: OS keychain via `keyring`

## Why This Path

- Works with standard Google Web clients.
- Keeps browser login without embedding a web view.

## Config

Set these environment variables (use `.env` based on `.env.example`):

- `TALYA_GOOGLE_CLIENT_ID`
- `TALYA_GOOGLE_CLIENT_SECRET`

If you need a different port, set `TALYA_GOOGLE_REDIRECT_PORT`.

## Dependencies

- `requests`
- `keyring`

## Next Steps (GitHub)

GitHub OAuth now uses a browser-based OAuth app flow with a fixed loopback
callback. Set:

- `TALYA_GITHUB_CLIENT_ID`
- `TALYA_GITHUB_CLIENT_SECRET`

The callback URL is:
`http://127.0.0.1:8765/oauth/github`

If you need a different port, set `TALYA_GITHUB_REDIRECT_PORT`.
