from __future__ import annotations

import sys


def show_emoji_picker() -> None:
    if sys.platform != "darwin":
        return
    try:
        from Cocoa import NSApplication  # type: ignore
    except Exception:
        return

    app = NSApplication.sharedApplication()
    if app is None:
        return
    app.orderFrontCharacterPalette_(None)
