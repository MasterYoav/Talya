from __future__ import annotations

import sys


def apply_vibrancy(
    window_id: int, sidebar_width: int, dark_mode: bool, opacity: float
) -> None:
    if sys.platform != "darwin":
        return

    try:
        from Cocoa import (
            NSVisualEffectView,
            NSViewWidthSizable,
            NSViewHeightSizable,
            NSVisualEffectStateActive,
            NSVisualEffectMaterialSidebar,
            NSApplication,
            NSColor,
            NSWindowBelow,
            NSAppearance,
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua,
        )
    except Exception:
        return

    try:
        app = NSApplication.sharedApplication()
        windows = app.windows()
        if not windows:
            return
        window = app.keyWindow() or windows[0]
        if window is None:
            return

        window.setOpaque_(False)
        window.setBackgroundColor_(NSColor.clearColor())
        window.setTitlebarAppearsTransparent_(False)
        window.setTitleVisibility_(0)

        content_view = window.contentView()
        if content_view is None:
            return

        container_view = content_view.superview() or content_view
        for view in list(container_view.subviews()):
            if view.isKindOfClass_(NSVisualEffectView):
                view.removeFromSuperview()

        if opacity <= 0.0:
            return

        frame = content_view.bounds()
        frame.size.width = sidebar_width
        effect = NSVisualEffectView.alloc().initWithFrame_(frame)
        effect.setAutoresizingMask_(NSViewHeightSizable)
        effect.setState_(NSVisualEffectStateActive)
        effect.setMaterial_(NSVisualEffectMaterialSidebar)
        effect.setBlendingMode_(0)
        effect.setAlphaValue_(opacity)
        appearance_name = NSAppearanceNameDarkAqua if dark_mode else NSAppearanceNameAqua
        appearance = NSAppearance.appearanceNamed_(appearance_name)
        if appearance is not None:
            effect.setAppearance_(appearance)

        container_view.addSubview_positioned_relativeTo_(
            effect, NSWindowBelow, content_view
        )
    except Exception:
        return
