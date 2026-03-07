# Architecture

Talya uses a local-first architecture:

- Desktop client built with Python + PySide6 + QML
- Local persistence with SQLite (per-account databases + local fallback)
- macOS vibrancy via NSVisualEffectView (sidebar translucency)
- reminder system with launchd background helper (macOS)
- Account-scoped data stored in per-account SQLite databases
- Browser-based OAuth with local loopback callback and PKCE (Google)
- Backend API with FastAPI
- Cloud sync storage with PostgreSQL
