import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> int:
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    qml_file = Path(__file__).parent / "ui" / "qml" / "Main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
