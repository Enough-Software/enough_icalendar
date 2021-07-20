# enough_icalendar
iCalendar library in pure Dart to parse, generate and respond to iCal / ics invites. 
Fully compliant with the iCalendar standard [RFC 5545](https://datatracker.ietf.org/doc/html/rfc5545) and compliant to all VEvent functions of [iTIP / RFC 5546](https://datatracker.ietf.org/doc/html/rfc5546).

## Installation
Add this dependency your pubspec.yaml file:

```
dependencies:
  enough_icalendar: ^0.3.0
```
The latest version or `enough_icalendar` is [![enough_icalendar version](https://img.shields.io/pub/v/enough_icalendar.svg)](https://pub.dartlang.org/packages/enough_icalendar).



## API Documentation
Check out the full API documentation at https://pub.dev/documentation/enough_icalendar/latest/

## Usage

Use `enough_icalendar` to parse, generate and respond to iCalendar requests. 

### Import

```dart
import 'package:enough_icalendar/enough_icalendar.dart';
```
### Parse iCalendar Requests
Use `VComponent.parse(String)` to parse the specified text.

```dart
  final text = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:uid1@example.com
DTSTAMP:19970714T170000Z
ORGANIZER;CN=John Doe:MAILTO:john.doe@example.com
DTSTART:19970714T170000Z
DTEND:19970715T035959Z
SUMMARY:Bastille Day Party
GEO:48.85299;2.36885
END:VEVENT
END:VCALENDAR''';
  final icalendar = VComponent.parse(text) as VCalendar;
  print(icalendar.productId); // -//hacksw/handcal//NONSGML v1.0//EN
  final event = icalendar.event!;
  print(event.summary); // Bastille Day Party
  print(event.start); // 1997-06-14 at 17:00
  print(event.end); // 1997-07-15 at 03:59:59
  print(event.organizer?.commonName); // John Doe
  print(event.organizer?.email); // john.doe@example.com
  print(event.geoLocation?.latitude); // 48.85299
  print(event.geoLocation?.longitude); // 2.36885
}
```
### Generate an invite
Use `VCalendar.createEvent(...)` to create a new invite easily.

Alternatively, for full low-lewel control instantiate `VCalendar` yourself and add `VComponent` children as you need.
Add any properties to the components to fill it with live.

Call the `toString()` method to render your invite.
```dart
  final invite = VCalendar.createEvent(
    organizerEmail: 'a@example.com',
    attendeeEmails: ['a@example.com', 'b@example.com', 'c@example.com'],
    rsvp: true,
    start: DateTime(2021, 07, 21, 10, 00),
    end: DateTime(2021, 07, 21, 11, 00),
    location: 'Big meeting room',
    url: Uri.parse('https://enough.de'),
    summary: 'Discussion',
    description:
        'Let us discuss how to proceed with the enough_icalendar development. It seems that basic functionality is now covered. What\'s next?',
    productId: 'enough_icalendar/v1',
  );
  print(invite);
  return invite;
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:REQUEST
  // BEGIN:VEVENT
  // DTSTAMP:20210719T090527
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // DTSTART:20210721T100000
  // DTEND:20210721T110000
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // LOCATION:Big meeting room
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // ATTENDEE;RSVP=TRUE:mailto:c@example.com
  // END:VEVENT
  // END:VCALENDAR
```
### Accept or Decline an Invite
Attendees can change their participant status with `VCalendar.replyWithParticipantStatus(...)`. You either need
to specify the `attendeeEmail` or the `attendee` parameter. This reply will need to be sent to the organizer.
```dart
  final reply = invite.replyWithParticipantStatus(ParticipantStatus.accepted,
      attendeeEmail: 'b@example.com');
  print(reply);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar
  // VERSION:2.0
  // METHOD:REPLY
  // BEGIN:VEVENT
  // ORGANIZER:mailto:a@example.com
  // UID:jovSCDXQ3sI5mBuu32@example.com
  // ATTENDEE;PARTSTAT=ACCEPTED:mailto:b@example.com
  // DTSTAMP:20210719T093653
  // REQUEST-STATUS:2.0;Success
  // END:VEVENT
```

### Delegate Event Participation
Attendees can delegate their event particpation to others by calling `VCalendar.delegate(...)`. Two results are generated,
one iCalendar for the delegatee and another one for the organizer.
```dart
  final delegationResult = original.delegate(
    fromEmail: 'c@example.com',
    toEmail: 'e@example.com',
  );
  print(delegationResult.requestForDelegatee);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:REQUEST
  // BEGIN:VEVENT
  // DTSTAMP:20210719T173821
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // DTSTART:20210721T100000
  // DTEND:20210721T110000
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // LOCATION:Big meeting room
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-TO="mailto:e@example.com":mailto:c
  //  @example.com
  // ATTENDEE;DELEGATED-FROM="mailto:c@example.com";RSVP=TRUE:mailto:e@exampl
  //  e.com
  // END:VEVENT
  // END:VCALENDAR

  print(delegationResult.replyForOrganizer);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar
  // VERSION:2.0
  // METHOD:REPLY
  // BEGIN:VEVENT
  // ORGANIZER:mailto:a@example.com
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-TO="mailto:e@example.com":mailto:c
  //  @example.com
  // DTSTAMP:20210719T173821
  // REQUEST-STATUS:2.0;Success
  // END:VEVENT
  // END:VCALENDAR
```

### Creating and Reponding to Counter Proposals
Attendees can create counter proposals and organizers can accept or decline such proposals.
#### Create a Counter Proposals
Attendees can create counter proposals with `VCalendar.counter(...)`:
```dart
  final counterProposal = invite.counter(
    comment: 'This time fits better, also we need some more time.',
    start: DateTime(2021, 07, 23, 10, 00),
    end: DateTime(2021, 07, 23, 12, 00),
    location: 'Carnegie Hall',
  );
  print(counterProposal);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:COUNTER
  // BEGIN:VEVENT
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // ATTENDEE;RSVP=TRUE:mailto:c@example.com
  // DTSTAMP:20210719T142550
  // COMMENT:This time fits better, also we need some more time.
  // LOCATION:Carnegie Hall
  // DTSTART:20210723T100000
  // DTEND:20210723T120000
  // END:VEVENT
  // END:VCALENDAR
```
#### Accept a Counter Proposal
Organizers can accept a counter proposal with `VCalendar.acceptCounter(...)`. 
The accepted proposal will have a higher sequence and the status automatically be set to EventStatus.confirmed.
The accepted and update invite is to be sent to all attendees by the organizer.
```dart
  final accepted = counterProposal.acceptCounter(
      comment: 'Accepted this proposed change of date and time');
  print(accepted);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:REQUEST
  // BEGIN:VEVENT
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // ATTENDEE;RSVP=TRUE:mailto:c@example.com
  // LOCATION:Carnegie Hall
  // DTSTART:20210723T100000
  // DTEND:20210723T120000
  // SEQUENCE:1
  // DTSTAMP:20210719T143344
  // STATUS:CONFIRMED
  // COMMENT:Accepted this proposed change of date and time
  // END:VEVENT
  // END:VCALENDAR 
```
#### Decline a Counter Proposal
Organizers can decline a counter proposal with `VCalendar.declineCounter(...)`. The declined reply is to be sent to the proposing attendee.
```dart
  final declined = counterProposal.declineCounter(
      attendeeEmail: 'b@example.com',
      comment: 'Sorry, but we have to stick to the original schedule');
  print(declined);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:DECLINECOUNTER
  // BEGIN:VEVENT
  // UID:vmScK-AyJr0NX2nCsW@example.com
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // DTSTAMP:20210719T143715
  // LOCATION:Carnegie Hall
  // DTSTART:20210723T100000
  // DTEND:20210723T120000
  // COMMENT:Sorry, but we have to stick to the original schedule
  // END:VEVENT
  // END:VCALENDAR
```
## Features and bugs

`enough_icalendar` supports all icalendar components and provides easy to access models:
* `VCALENDAR` 
* `VEVENT` 
* `VTIMEZONE` with the `STANDARD` and `DAYLIGHT` subcomponents
* `VALARM`
* `VFREEBUSY`
* `VTODO`
* `VJOURNAL`
* Fully compliant with the iCalendar standard [RFC 5545](https://datatracker.ietf.org/doc/html/rfc5545)
* Compliant to all `VEvent` functions of [iTIP / RFC 5546](https://datatracker.ietf.org/doc/html/rfc5546).


Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Enough-Software/enough_icalendar/issues

## Null-Safety
`enough_icalendar` is null-safe.

## License
`enough_icalendar` is licensed under the commercial friendly [Mozilla Public License 2.0](LICENSE)

