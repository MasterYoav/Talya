from PySide6.QtCore import Property, QObject, Signal, Slot


class AppState(QObject):
    currentSectionChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._current_section = "Today"

    def get_current_section(self) -> str:
        return self._current_section

    def set_current_section(self, section: str) -> None:
        if section == self._current_section:
            return

        self._current_section = section
        self.currentSectionChanged.emit()

    @Property(str, notify=currentSectionChanged)
    def currentSection(self) -> str:
        return self.get_current_section()

    @Slot(str)
    def selectSection(self, section: str) -> None:
        self.set_current_section(section)
