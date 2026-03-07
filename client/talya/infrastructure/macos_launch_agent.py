from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def _plist_path() -> Path:
    return Path.home() / "Library" / "LaunchAgents" / "com.talya.reminders.plist"


def _build_plist(executable: str, project_root: Path) -> str:
    python_path = str(project_root)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.talya.reminders</string>
    <key>ProgramArguments</key>
    <array>
        <string>{executable}</string>
        <string>-m</string>
        <string>talya.reminder_daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PYTHONPATH</key>
        <string>{python_path}</string>
    </dict>
    <key>WorkingDirectory</key>
    <string>{project_root}</string>
</dict>
</plist>
"""


def install_launch_agent(project_root: Path) -> None:
    if sys.platform != "darwin":
        return
    plist_path = _plist_path()
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_path.write_text(_build_plist(sys.executable, project_root))
    uid = os.getuid()
    subprocess.run(
        ["launchctl", "bootstrap", f"gui/{uid}", str(plist_path)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def uninstall_launch_agent() -> None:
    if sys.platform != "darwin":
        return
    plist_path = _plist_path()
    if plist_path.exists():
        uid = os.getuid()
        subprocess.run(
            ["launchctl", "bootout", f"gui/{uid}", str(plist_path)],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        plist_path.unlink(missing_ok=True)
