# 0.17.0
- Updated dependencies

# 0.16.0
- Fix handling of ICS data with varying line endings [#13], thanks to [vanlooverenkoen](https://github.com/vanlooverenkoen)
- Allow to set trigger of an alarm to a DateTime[#12], thanks to [liplum](https://github.com/liplum)
- Added helper to convert Duration to IsoDuration [#11] thanks to [liplum](https://github.com/liplum)

## 0.15.0
- Fix export of WKST attribute of a RRULE [#10](https://github.com/Enough-Software/enough_icalendar/issues/10) with thanks to [tgrushka](https://github.com/tgrushka)!

## 0.14.0
- Ensure compatibility with Flutter 3.10 - with thanks to [hurkanugur](https://github.com/hurkanugur)!

## 0.13.0
- Again, thanks to [martingeorgiu](https://github.com/martingeorgiu) the support for parsing Apple-originating iCalendar invites has been improved.

## 0.12.0
- Thanks to [martingeorgiu](https://github.com/martingeorgiu) for the following great changes:
  - support Apple format by not requiring a standard and a daylight for every timezone
  - remove Flutter dependency

## 0.11.0
- support `X-MICROSOFT-SKYPETEAMSMEETINGURL` property directly.

## 0.10.0
- Forward `customParser` argument correctly, in case you need to support further properties directly


## 0.9.0
- Fix duration parsing [#2](https://github.com/Enough-Software/enough_icalendar/issues/2)
- Support `X-WR-CALNAME` property, use VCalendar.calendarName to get/set it [#3](https://github.com/Enough-Software/enough_icalendar/issues/3)

## 0.8.0
- Support `X-MICROSOFT-CDO-ALLDAYEVENT` property, access it via `VEvent.isAllDayEvent`
- Attendees are now optional when creating an event

## 0.7.0
- Uses UTC date times when encountering UTC DateTime values. To get the local time, call `toLocal()`, e.g. `final localStartTime = event.start!.toLocal();`

## 0.6.0
- Adds the `IsoDuration.toDuration()` conversion method

## 0.5.0
- Convert a recurrence rule to human readbable text using `recurrence.toHumanReadableText()`.
  With a recurrence of `RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU`, `recurrence.toHumanReadableText()` results in 
  `Every other month on the first & last Sunday, 10 times`, and `recurrence.toHumanReadableText(languageCode: 'de')` results in 
  `Alle zwei Monate an dem ersten & letzten Sonntag, 10-mal`, for example.
- Newlines and commas are escaped and de-escaped correctly in description and location fields.


## 0.4.0
Support for additional properties and parameters.

The following proprietry properties are now supported:
- X-LIC-LOCATION
- X-MICROSOFT-CDO-BUSYSTATUS

The following parameters are now supported:
- EMAIL (Attendee)
- X-FILENAME (Attachment)

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
