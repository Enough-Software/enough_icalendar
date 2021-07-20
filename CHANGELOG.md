## 0.3.1
- Fix bug in `VCalendar.createEvent`
- Fix bug when adding a `TextParameter` with a value that contains a semicolon
- Add convenience geters for summary, description, attendees, organizer, uid in `VCalendar`


## 0.3.0
- Render `VCalendar`, `VEvent` instances, etc just by calling their `toString()` method
- Set any properties
- Set any propery parameters
- Easily generate invites with `VCalendar.createEvent(...)`
- Support any `VEvent` specific [iTIP / RFC 5546](https://datatracker.ietf.org/doc/html/rfc5546) functions:
    - change participant status (accept, decline, delegated) with `VCalendar.replyWithParticipantStatus(...)`
    - delegate to another attendee with `VCalendar.delegate(...)`
    - create a counter proposal with `VCalendar.counter(...)`
    - accept a counter proposal with `VCalendar.acceptCounter(...)`
    - reject a counter proposal with `VCalendar.declineCounter(...)`
    - cancel an event for all with `VCalendar.cancelEvent(...)`
    - cancel an event for specific attendees with `VCalendar.cancelEventForAttendees(...)`
- Improve documentation

## 0.2.0
- Improve documentation
- Renamed `Component` to `VComponent` for clarity

## 0.1.0

* Initial release with full parsing and high level API support.
