import os
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication, QSurfaceFormat
from PySide6.QtQuick import QQuickWindow
from PySide6.QtQml import QQmlApplicationEngine

from talya.app.app_state import AppState
from talya.infrastructure.macos_vibrancy import apply_vibrancy


def main() -> int:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    surface_format = QSurfaceFormat()
    surface_format.setAlphaBufferSize(8)
    QSurfaceFormat.setDefaultFormat(surface_format)
    QQuickWindow.setDefaultAlphaBuffer(True)
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    app_state = AppState()
    engine.rootContext().setContextProperty("appState", app_state)

    qml_file = Path(__file__).parent / "ui" / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    window = engine.rootObjects()[0]
    apply_vibrancy(
        int(window.winId()),
        app_state.sidebarWidth,
        app_state.darkMode,
        app_state.sidebarBlurOpacity,
    )

    def handle_sidebar_width_changed() -> None:
        apply_vibrancy(
            int(window.winId()),
            app_state.sidebarWidth,
            app_state.darkMode,
            app_state.sidebarBlurOpacity,
        )

    app_state.sidebarWidthChanged.connect(handle_sidebar_width_changed)
    app_state.darkModeChanged.connect(handle_sidebar_width_changed)
    app_state.sidebarBlurOpacityChanged.connect(handle_sidebar_width_changed)

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
