from __future__ import annotations

import sys

_authorized = False


def _request_authorization(center) -> None:
    global _authorized
    if _authorized:
        return
    try:
        from UserNotifications import (
            UNAuthorizationOptionAlert,
            UNAuthorizationOptionSound,
        )
    except Exception:
        return
    options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound
    center.requestAuthorizationWithOptions_completionHandler_(options, None)
    _authorized = True


def send_notification(title: str, body: str) -> None:
    if sys.platform != "darwin":
        return

    try:
        from Foundation import NSObject
        from UserNotifications import (
            UNMutableNotificationContent,
            UNNotificationRequest,
            UNUserNotificationCenter,
            UNTimeIntervalNotificationTrigger,
        )
    except Exception:
        return

    class _Delegate(NSObject):
        pass

    center = UNUserNotificationCenter.currentNotificationCenter()
    _request_authorization(center)

    content = UNMutableNotificationContent.alloc().init()
    content.setTitle_(title)
    content.setBody_(body)

    trigger = UNTimeIntervalNotificationTrigger.triggerWithTimeInterval_repeats_(1, False)
    request = UNNotificationRequest.requestWithIdentifier_content_trigger_(
        f"talya-{title}-{body}",
        content,
        trigger,
    )

    center.addNotificationRequest_withCompletionHandler_(request, None)
