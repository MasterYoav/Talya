from __future__ import annotations

from datetime import datetime
import threading

import requests

try:
    import EventKit
    import Foundation
except Exception:  # pragma: no cover - optional on non-macOS
    EventKit = None
    Foundation = None


class CalendarService:
    GOOGLE_CALENDAR_LIST_URL = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
    GOOGLE_EVENTS_URL = "https://www.googleapis.com/calendar/v3/calendars/{calendar_id}/events"

    def __init__(self) -> None:
        self._apple_store = (
            EventKit.EKEventStore.alloc().init() if EventKit else None
        )
        self._apple_access: bool | None = None

    def ensure_apple_access(self) -> bool:
        if self._apple_store is None:
            return False
        if self._apple_access is not None:
            return self._apple_access
        event = threading.Event()
        result = {"granted": False}

        def handler(granted: bool, _error: object) -> None:
            result["granted"] = bool(granted)
            event.set()

        self._apple_store.requestAccessToEntityType_completion_(
            EventKit.EKEntityTypeEvent,
            handler,
        )
        event.wait(10)
        self._apple_access = result["granted"]
        return self._apple_access

    def list_apple_calendars(self) -> list[dict]:
        if self._apple_store is None:
            return []
        if not self.ensure_apple_access():
            return []
        calendars = self._apple_store.calendarsForEntityType_(EventKit.EKEntityTypeEvent)
        return [
            {
                "id": cal.calendarIdentifier(),
                "name": cal.title(),
                "provider": "apple",
            }
            for cal in calendars or []
        ]

    def list_google_calendars(self, access_token: str) -> list[dict]:
        if not access_token:
            return []
        response = requests.get(
            self.GOOGLE_CALENDAR_LIST_URL,
            headers={"Authorization": f"Bearer {access_token}"},
            timeout=20,
        )
        if response.status_code != 200:
            return []
        items = response.json().get("items", [])
        return [
            {
                "id": item.get("id", ""),
                "name": item.get("summary", "Calendar"),
                "provider": "google",
                "primary": bool(item.get("primary")),
            }
            for item in items
            if item.get("id")
        ]

    def list_events(
        self,
        apple_calendar_ids: list[str],
        google_calendar_ids: list[str],
        start_dt: datetime,
        end_dt: datetime,
        google_access_token: str,
    ) -> list[dict]:
        events: list[dict] = []
        if self._apple_store is not None and apple_calendar_ids:
            if self.ensure_apple_access():
                calendars = [
                    cal
                    for cal in self._apple_store.calendarsForEntityType_(
                        EventKit.EKEntityTypeEvent
                    )
                    if cal.calendarIdentifier() in apple_calendar_ids
                ]
                start = Foundation.NSDate.dateWithTimeIntervalSince1970_(
                    start_dt.timestamp()
                )
                end = Foundation.NSDate.dateWithTimeIntervalSince1970_(
                    end_dt.timestamp()
                )
                predicate = self._apple_store.predicateForEventsWithStartDate_endDate_calendars_(
                    start, end, calendars
                )
                matches = self._apple_store.eventsMatchingPredicate_(predicate) or []
                for item in matches:
                    is_all_day = False
                    if hasattr(item, "isAllDay"):
                        try:
                            is_all_day = bool(item.isAllDay())
                        except Exception:
                            is_all_day = False
                    elif hasattr(item, "allDay"):
                        try:
                            value = item.allDay()
                            is_all_day = bool(value() if callable(value) else value)
                        except Exception:
                            is_all_day = False
                    events.append(
                        {
                            "id": item.eventIdentifier(),
                            "title": item.title() or "",
                            "start": item.startDate().description(),
                            "end": item.endDate().description(),
                            "notes": item.notes() or "",
                            "location": item.location() or "",
                            "calendar_id": item.calendar().calendarIdentifier(),
                            "provider": "apple",
                            "all_day": is_all_day,
                        }
                    )

        if google_calendar_ids and google_access_token:
            for calendar_id in google_calendar_ids:
                url = self.GOOGLE_EVENTS_URL.format(calendar_id=calendar_id)
                response = requests.get(
                    url,
                    headers={"Authorization": f"Bearer {google_access_token}"},
                    params={
                        "timeMin": start_dt.isoformat() + "Z",
                        "timeMax": end_dt.isoformat() + "Z",
                        "singleEvents": "true",
                        "orderBy": "startTime",
                    },
                    timeout=20,
                )
                if response.status_code != 200:
                    continue
                for item in response.json().get("items", []):
                    start = item.get("start", {})
                    end = item.get("end", {})
                    is_all_day = "date" in start
                    events.append(
                        {
                            "id": item.get("id", ""),
                            "title": item.get("summary", ""),
                            "start": start.get("dateTime") or start.get("date"),
                            "end": end.get("dateTime") or end.get("date"),
                            "notes": item.get("description", ""),
                            "location": item.get("location", ""),
                            "calendar_id": calendar_id,
                            "provider": "google",
                            "all_day": is_all_day,
                        }
                    )

        events.sort(key=lambda item: item.get("start") or "")
        return events

    def create_event(
        self,
        provider: str,
        calendar_id: str,
        title: str,
        start_dt: datetime,
        end_dt: datetime,
        notes: str,
        location: str,
        google_access_token: str,
        all_day: bool,
    ) -> bool:
        if provider == "apple":
            if self._apple_store is None or not self.ensure_apple_access():
                return False
            event = EventKit.EKEvent.eventWithEventStore_(self._apple_store)
            event.setTitle_(title)
            event.setAllDay_(all_day)
            event.setStartDate_(
                Foundation.NSDate.dateWithTimeIntervalSince1970_(start_dt.timestamp())
            )
            event.setEndDate_(
                Foundation.NSDate.dateWithTimeIntervalSince1970_(end_dt.timestamp())
            )
            event.setNotes_(notes)
            event.setLocation_(location)
            calendar = self._apple_store.calendarWithIdentifier_(calendar_id)
            if calendar is None:
                return False
            event.setCalendar_(calendar)
            success, _error = self._apple_store.saveEvent_span_error_(
                event, EventKit.EKSpanThisEvent, None
            )
            return bool(success)

        if provider == "google" and google_access_token:
            url = self.GOOGLE_EVENTS_URL.format(calendar_id=calendar_id)
            if all_day:
                start_payload = {"date": start_dt.date().isoformat()}
                end_payload = {"date": end_dt.date().isoformat()}
            else:
                start_payload = {"dateTime": start_dt.isoformat() + "Z"}
                end_payload = {"dateTime": end_dt.isoformat() + "Z"}
            response = requests.post(
                url,
                headers={"Authorization": f"Bearer {google_access_token}"},
                json={
                    "summary": title,
                    "description": notes,
                    "location": location,
                    "start": start_payload,
                    "end": end_payload,
                },
                timeout=20,
            )
            return response.status_code in {200, 201}

        return False

    def update_event(
        self,
        provider: str,
        event_id: str,
        calendar_id: str,
        title: str,
        start_dt: datetime,
        end_dt: datetime,
        notes: str,
        location: str,
        google_access_token: str,
        all_day: bool,
    ) -> bool:
        if provider == "apple":
            if self._apple_store is None or not self.ensure_apple_access():
                return False
            event = self._apple_store.eventWithIdentifier_(event_id)
            if event is None:
                return False
            event.setTitle_(title)
            event.setAllDay_(all_day)
            event.setStartDate_(
                Foundation.NSDate.dateWithTimeIntervalSince1970_(start_dt.timestamp())
            )
            event.setEndDate_(
                Foundation.NSDate.dateWithTimeIntervalSince1970_(end_dt.timestamp())
            )
            event.setNotes_(notes)
            event.setLocation_(location)
            calendar = self._apple_store.calendarWithIdentifier_(calendar_id)
            if calendar is None:
                return False
            event.setCalendar_(calendar)
            success, _error = self._apple_store.saveEvent_span_error_(
                event, EventKit.EKSpanThisEvent, None
            )
            return bool(success)

        if provider == "google" and google_access_token:
            url = self.GOOGLE_EVENTS_URL.format(calendar_id=calendar_id) + f"/{event_id}"
            if all_day:
                start_payload = {"date": start_dt.date().isoformat()}
                end_payload = {"date": end_dt.date().isoformat()}
            else:
                start_payload = {"dateTime": start_dt.isoformat() + "Z"}
                end_payload = {"dateTime": end_dt.isoformat() + "Z"}
            response = requests.patch(
                url,
                headers={"Authorization": f"Bearer {google_access_token}"},
                json={
                    "summary": title,
                    "description": notes,
                    "location": location,
                    "start": start_payload,
                    "end": end_payload,
                },
                timeout=20,
            )
            return response.status_code in {200, 201}

        return False
