import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from talya.app.app_state import AppState


def main() -> int:
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    app_state = AppState()
    engine.rootContext().setContextProperty("appState", app_state)

    qml_file = Path(__file__).parent / "ui" / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
