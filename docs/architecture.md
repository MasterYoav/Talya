# Architecture

Talya uses a local-first architecture:

- Desktop client built with Python + PySide6 + QML
- Local persistence with SQLite (per-account databases + local fallback, lists + tasks)
- macOS vibrancy via NSVisualEffectView (sidebar translucency)
- macOS emoji picker integration for list icons
- reminder system with launchd background helper (macOS)
- Account-scoped data stored in per-account SQLite databases
- Browser-based OAuth with local loopback callback and PKCE (Google)
- Backend API with FastAPI (JWT, OAuth identity linking)
- Server validates OAuth access tokens before issuing JWT
- JWT expiry is not enforced in dev (server accepts expired tokens)
- Cloud sync storage with PostgreSQL (lists, tasks, settings)
- Client sync uses `/sync/merge` with last-write-wins
- Calendar providers: Apple EventKit + Google Calendar API
- Calendar UI in client: month/day/year views with event editor and all-day handling
- Settings UI uses tabbed navigation with theme/preferences/calendar sections
- App supports user-selectable fonts and live theme switching
- Sidebar collapse is driven by app icon button (top of sidebar)
