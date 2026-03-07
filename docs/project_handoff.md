# Talya — Project Handoff

## Project Summary

**Talya** is a local-first desktop productivity app being built with:

- **Python**
- **PySide6**
- **QML**
- **SQLite**

The long-term product goal is to become a focused desktop app for:
- tasks
- reminders
- timeline organization
- future calendar integrations
- future cloud sync
- future assistant features

The app is currently in the **desktop local-first MVP foundation phase**.

---

## Core Product Direction

Talya is meant to feel like a modern, premium productivity app in the style of:
- Things 3
- TickTick

But the current priority is **solid architecture and functionality**, not visual perfection.

At this stage, the app already supports:
- local task creation
- local task editing
- local task deletion
- completion toggling
- SQLite persistence
- task detail popup
- task notes persistence
- section-based task organization
- settings page
- dark/light mode toggle
- collapsible sidebar
- Google OAuth sign-in (browser-based loopback with client secret)
- GitHub OAuth sign-in (browser-based)
- account-scoped local data (per-account SQLite databases)
- macOS vibrancy sidebar (NSVisualEffectView)
- sidebar blur slider (saved per account)

---

## Current Tech Stack

### Desktop App
- **Python**
- **PySide6**
- **QML**

### Local Storage
- **SQLite**

### Planned Later
- FastAPI backend
- PostgreSQL cloud DB
- sync engine
- auth
- calendar integrations
- reminders
- due dates / timeline logic

---

## Repository Structure

```text
Talya/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── product_vision.md
│   └── project_handoff.md
├── client/
│   ├── README.md
│   ├── requirements.txt
│   ├── data/
│   │   └── talya.db
│   └── talya/
│       ├── __init__.py
│       ├── main.py
│       ├── app/
│       │   ├── __init__.py
│       │   └── app_state.py
│       ├── domain/
│       │   ├── __init__.py
│       │   └── task.py
│       ├── infrastructure/
│       │   ├── __init__.py
│       │   ├── database.py
│       │   ├── migrations.py
│       │   └── task_repository.py
│       ├── services/
│       │   ├── __init__.py
│       │   └── task_service.py
│       └── ui/
│           └── qml/
│               ├── Main.qml
│               ├── AppShell.qml
│               └── components/
│                   ├── ContentView.qml
│                   ├── SettingsView.qml
│                   ├── Sidebar.qml
│                   └── SidebarItem.qml
└── server/
    └── README.md
```

---

## Folder-by-Folder Explanation

### `docs/`

Contains documentation and planning files.

#### `architecture.md`
High-level architecture notes.

#### `product_vision.md`
Defines what Talya is supposed to become.

#### `project_handoff.md`
This file. It is meant to help future work continue cleanly.

---

### `client/`

Contains the desktop app code.

#### `client/data/talya.db`
Local SQLite database file. This is where tasks are currently persisted.

This file should **not** be committed.

---

### `client/talya/`

Main Python package for the desktop app.

---

## File-by-File Explanation

### `client/talya/main.py`

**Purpose:** Desktop app entry point.

Responsibilities:
- creates the Qt application
- creates the QML engine
- injects `appState` into QML context
- loads `Main.qml`

This is the boot file for the client.

---

### `client/talya/app/app_state.py`

**Purpose:** Central UI/application state exposed to QML.

This is currently the most important application-state object.

Responsibilities:
- stores current section (`Inbox`, `Today`, `Upcoming`, `Settings`, `Profile`)
- exposes the current task list to QML
- tracks selected task
- tracks dark mode
- tracks sidebar collapsed state
- tracks edit mode
- tracks authentication state and profile
- exposes slots callable from QML

Current QML-facing responsibilities include:
- selecting a section
- adding a task
- toggling task completion
- updating task title
- updating task notes
- deleting a task
- selecting a task
- clearing selected task
- switching theme
- toggling sidebar collapse
- toggling edit mode
- login/register/logout for local auth
- login with Google (OAuth)
- update profile info

This class is currently the bridge between:
- QML UI
- service layer

---

### `client/talya/domain/task.py`

### `client/talya/services/auth_service.py`

**Purpose:** Handles OAuth flows and profile caching.

Responsibilities:
- starts Google OAuth via browser + loopback callback
- starts Google OAuth via device authorization flow
- polls for tokens after user completes browser step
- fetches Google profile data
- starts GitHub OAuth via browser + loopback callback
- exchanges GitHub auth code for tokens
- fetches GitHub profile + email data
- caches tokens/profile in keychain

### `client/talya/infrastructure/token_store.py`

**Purpose:** Secure local token/profile storage.

Responsibilities:
- stores/retrieves JSON payloads in OS keychain via `keyring`

---

### `client/talya/infrastructure/macos_vibrancy.py`

**Purpose:** macOS-only translucent background.

Responsibilities:
- attaches an `NSVisualEffectView` behind the Qt window content
**Purpose:** Domain model for a task.

Current fields:
- `id`
- `title`
- `section`
- `is_completed`
- `created_at`
- `updated_at`
- `notes`
- `due_date`
- `reminder_at`

This is the pure data representation of a task.

It currently includes:
- a static constructor `Task.create(title, section)`

---

### `client/talya/infrastructure/database.py`

**Purpose:** SQLite database setup and connection management.

Responsibilities:
- determine DB path (account-scoped)
- create SQLite connection
- initialize base `tasks` table
- initialize settings table
- run migrations

This is the DB bootstrap layer.

Account paths:
- signed-out local data uses `client/data/talya.db`
- signed-in accounts use `client/data/accounts/<hash>/talya.db`

---

### `client/talya/infrastructure/settings_repository.py`

**Purpose:** Store per-account app settings.

Responsibilities:
- get and set settings like `dark_mode` and `sidebar_collapsed`
- persist `sidebar_blur_opacity`

---

### `client/talya/infrastructure/migrations.py`

**Purpose:** Minimal SQLite schema migration system.

Current responsibilities:
- ensure a `schema_version` table exists
- detect current schema version
- migrate from v1 to v2

Current migration adds:
- `notes`
- `due_date`
- `reminder_at`
- `updated_at`

This exists to avoid destructive schema changes as the app evolves.

---

### `client/talya/infrastructure/task_repository.py`

**Purpose:** SQLite repository for tasks.

Responsibilities:
- load tasks from SQLite
- insert tasks
- update completion status
- update title
- update notes
- delete tasks

This file is the persistence layer between SQLite and the Python domain model.

Important helper:
- `parse_optional_datetime(...)`

---

### `client/talya/services/task_service.py`

**Purpose:** Business logic layer for tasks.

Responsibilities:
- add task
- list tasks
- list tasks by section
- get task by ID
- toggle completion
- update title
- update notes
- delete task

This layer works on `Task` objects and delegates persistence to `TaskRepository`.

Current design:
- loads all tasks into memory on startup
- keeps an in-memory list
- updates SQLite through repository calls

This is fine for current MVP size.

---

### `client/talya/ui/qml/Main.qml`

**Purpose:** Top-level QML window entry.

Currently:
- creates `ApplicationWindow`
- loads `AppShell`

This file should stay small.

---

### `client/talya/ui/qml/AppShell.qml`

**Purpose:** Top-level desktop shell layout.

Responsibilities:
- main app background
- sidebar placement
- choosing which major page/view to show
- overlay sidebar behavior

Current behavior:
- sidebar is an overlay/floating panel
- content shifts right depending on sidebar width
- shows one of:
  - `ContentView`
  - `SettingsView`
  - `Profile` placeholder view

---

### `client/talya/ui/qml/components/Sidebar.qml`

**Purpose:** Navigation sidebar.

Responsibilities:
- render app navigation
- show collapse button
- show major sections:
  - Inbox
  - Today
  - Upcoming
  - Settings
  - Profile
- forward section clicks into `appState`

Current behavior:
- collapsible
- overlay panel
- translucent/glass-like styling attempt
- no true native blur yet

---

### `client/talya/ui/qml/components/SidebarItem.qml`

**Purpose:** Reusable sidebar row component.

Responsibilities:
- render label + icon
- handle hover state
- handle selected state
- support collapsed sidebar mode

Used by `Sidebar.qml`.

---

### `client/talya/ui/qml/components/ContentView.qml`

**Purpose:** Main task screen.

This is the most important current QML file.

Responsibilities:
- show current section title
- quick-add task bar
- edit-mode button
- task list
- task detail popup

Important current behaviors:
- clicking a task opens popup
- popup allows editing:
  - title
  - notes
- Save persists data to SQLite
- popup closes and selected task clears

Current popup behavior:
- explicit Save button
- top-right X close button
- no side detail pane anymore

---

### `client/talya/ui/qml/components/SettingsView.qml`

**Purpose:** Full-page settings screen.

Current behavior:
- rendered as a full app section, not popup
- allows switching:
  - Light mode
  - Dark mode
- has placeholder Connections section

---

## What Has Been Implemented So Far

### Phase 1 — Repo and project setup
Completed:
- GitHub repo created
- base folder structure created
- initial docs added

### Phase 2 — Desktop shell setup
Completed:
- Python environment created
- PySide6 installed
- QML app window launches

### Phase 3 — QML structure
Completed:
- split UI into reusable QML files
- app shell + sidebar + content view structure

### Phase 4 — App state bridge
Completed:
- Python `AppState` exposed to QML
- navigation state moved out of pure QML

### Phase 5 — Basic tasks
Completed:
- task model added
- in-memory task creation
- tasks shown in UI

### Phase 6 — Task sections and completion
Completed:
- sections (`Inbox`, `Today`, `Upcoming`)
- completion toggle
- section-based filtering

### Phase 7 — SQLite persistence
Completed:
- SQLite local DB
- tasks table
- repository layer
- persistence across app restarts

### Phase 8 — Task editing and deletion
Completed:
- update title
- delete task
- timestamps displayed

### Phase 9 — Settings, sidebar, theming shell
Completed:
- collapsible sidebar
- settings page
- theme switching
- profile placeholder

### Phase 10 — Schema evolution / real data model prep
Completed:
- migration system
- richer task schema:
  - notes
  - due date
  - reminder
  - updated_at

### Phase 11 — Selected task flow
Completed:
- selected task support in app state
- task detail popup instead of side panel
- title save to SQLite
- notes save to SQLite

---

## Current Task Database Schema

From `PRAGMA table_info(tasks);`

Current columns:

- `id TEXT PRIMARY KEY`
- `title TEXT NOT NULL`
- `section TEXT NOT NULL`
- `is_completed INTEGER NOT NULL DEFAULT 0`
- `created_at TEXT NOT NULL`
- `notes TEXT`
- `due_date TEXT`
- `reminder_at TEXT`
- `updated_at TEXT`

This is the current working local schema.

---

## Current Architecture Notes

### Pattern currently used
Roughly:
- QML UI
- `AppState` as QML/Python bridge
- service layer for task logic
- repository layer for DB operations
- SQLite persistence

### Current flow example
For task creation:

1. User types into quick add field
2. QML calls `appState.addTask(...)`
3. `AppState` calls `TaskService.add_task(...)`
4. `TaskService` creates `Task`
5. `TaskRepository` inserts into SQLite
6. `AppState.tasksChanged` emitted
7. QML redraws task list

That same layered flow is used for:
- completion toggling
- task title updates
- task notes updates
- delete

---

## Known Current Limitations

These are not bugs unless stated otherwise; many are just not implemented yet.

### Visual
- sidebar is only **glass-like**, not true macOS native blur
- icons are temporary Unicode symbols
- UI polish is still unfinished

### Data model
- due date exists in schema but has no UI yet
- reminder exists in schema but has no UI yet

### Task details
- popup currently edits:
  - title
  - notes
- no due date/reminder controls yet

### Section logic
Current sections are still manual buckets:
- Inbox
- Today
- Upcoming

They are not yet driven by due-date logic.

### Settings persistence
Theme/sidebar state is not yet persisted between restarts unless implemented later.
(Depending on current branch state, verify before assuming.)

### Backend / sync
Not implemented yet:
- FastAPI
- PostgreSQL
- auth
- sync
- calendar connections

---

## Important Recent Bug Fixes

### QML alpha color bug
Earlier there was a major visual bug caused by using 8-digit hex colors as if QML used CSS-style `#RRGGBBAA`.

In QML the format is:

- `#AARRGGBB`

This caused accidental yellow-ish outlines and wrong translucent colors.

This was fixed by either:
- correcting alpha color ordering
- or removing dark-mode borders entirely

### Notes not saving in popup
Bug cause:
- popup reloaded selected task state during save
- draft notes were overwritten before being saved

Fix:
- explicit Save button
- draft values stored first
- notes saved before title
- popup then closed

---

## What Should Be Built Next

### Recommended next step
**Add due date and reminder editing to the task popup**

That means:
- editable due date field
- editable reminder field
- repository/service support for saving them
- app state exposure
- basic formatting in UI

This is the next real step because:
- schema already supports it
- popup architecture already exists
- it moves Talya toward real timeline logic

### After that
Recommended order:

1. due date + reminder support
2. make Today/Upcoming intelligent based on due dates
3. persist UI settings locally
4. add reminder scheduling logic
5. later: backend/sync/auth/calendar

---

## Practical Rules For Continuing Work

### 1. Keep QML mostly presentation-focused
Do not move business logic into QML.

### 2. Keep persistence in repository layer
Do not let `AppState` talk directly to SQLite.

### 3. Keep task logic in `TaskService`
Validation and update behavior belong there.

### 4. Use migrations for schema changes
Do not silently change the schema and hope old DBs survive.

### 5. Prefer explicit Save behavior for important edits
This already proved more reliable than passive focus-based saving.

---

## Current Major Files To Read First

If a new agent/tool continues this project, the best reading order is:

1. `client/talya/app/app_state.py`
2. `client/talya/services/task_service.py`
3. `client/talya/infrastructure/task_repository.py`
4. `client/talya/domain/task.py`
5. `client/talya/ui/qml/components/ContentView.qml`
6. `client/talya/ui/qml/AppShell.qml`
7. `client/talya/ui/qml/components/Sidebar.qml`
8. `client/talya/infrastructure/migrations.py`

That order gives the fastest understanding of the project.

---

## Current State Summary

Talya is currently a **working local-first desktop task app foundation** with:

- clean Python/QML bridge
- SQLite persistence
- evolving task schema
- section navigation
- detail popup
- editable notes/title
- settings page
- theme switching
- good architectural base for due dates, reminders, and later sync

It is no longer a toy shell.  
It is now in the early stage of being a real desktop productivity system.
