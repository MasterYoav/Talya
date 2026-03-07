from __future__ import annotations

import sys
from pathlib import Path


def _icon_path(choice: str) -> Path:
    project_root = Path(__file__).resolve().parents[2]
    base = project_root / "media"
    if choice == "light":
        return base / "light.xcassets" / "AppIcon.appiconset" / "1024-mac.png"
    return base / "dark.xcassets" / "AppIcon.appiconset" / "1024-mac.png"


def apply_app_icon(choice: str) -> None:
    if sys.platform != "darwin":
        return

    try:
        from Cocoa import NSApplication, NSImage
    except Exception:
        return

    icon_path = _icon_path(choice)
    if not icon_path.exists():
        return

    image = NSImage.alloc().initWithContentsOfFile_(str(icon_path))
    if image is None:
        return

    app = NSApplication.sharedApplication()
    app.setApplicationIconImage_(image)
