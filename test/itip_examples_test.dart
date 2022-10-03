import 'package:test/test.dart';
import 'package:enough_icalendar/enough_icalendar.dart';

// examples taken from https://datatracker.ietf.org/doc/html/rfc5546#section-4
void main() {
  group('VEVENT Examples', () {
    test('A Minimal Published Event', () {
      final input =
          '''BEGIN:VCALENDAR
METHOD:PUBLISH
PRODID:-//Example/ExampleCalendarClient//EN
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
DTSTART:19970701T200000Z
DTSTAMP:19970611T190000Z
SUMMARY:ST. PAUL SAINTS -VS- DULUTH-SUPERIOR DUKES
UID:0981234-1234234-23@example.com
END:VEVENT
END:VCALENDAR''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.publish);
      // other properties are covered by components_test.dart
    });

    test('Changing a Published Event', () {
      final input =
          '''BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
PRODID:-//Example/ExampleCalendarClient//EN
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
DTSTAMP:19970612T190000Z
DTSTART:19970701T210000Z
DTEND:19970701T230000Z
SEQUENCE:1
UID:0981234-1234234-23@example.com
SUMMARY:ST. PAUL SAINTS -VS- DULUTH-SUPERIOR DUKES
END:VEVENT
END:VCALENDAR''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.publish);
      expect((iCalendar.children.first as VEvent).sequence, 1);
      // other properties are covered by components_test.dart
    });

    test('Changing a Published Event', () {
      final input =
          '''BEGIN:VCALENDAR
METHOD:CANCEL
VERSION:2.0
PRODID:-//Example/ExampleCalendarClient//EN
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
COMMENT:DUKES forfeit the game
SEQUENCE:2
UID:0981234-1234234-23@example.com
DTSTAMP:19970613T190000Z
END:VEVENT
END:VCALENDAR
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.cancel);
      expect((iCalendar.children.first as VEvent).sequence, 2);
      // other properties are covered by components_test.dart
    });

    test('A Rich Published Event', () {
      final input =
          '''BEGIN:VCALENDAR\r
PRODID:-//Example/ExampleCalendarClient//EN\r
METHOD:PUBLISH\r
CALSCALE:GREGORIAN\r
VERSION:2.0\r
BEGIN:VTIMEZONE\r
TZID:America-Chicago\r
TZURL:http://example.com/tz/America-Chicago\r
BEGIN:STANDARD\r
DTSTART:19671029T020000\r
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10\r
TZOFFSETFROM:-0500\r
TZOFFSETTO:-0600\r
TZNAME:CST\r
END:STANDARD\r
BEGIN:DAYLIGHT\r
DTSTART:19870405T020000\r
RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4\r
TZOFFSETFROM:-0600\r
TZOFFSETTO:-0500\r
TZNAME:CDT\r
END:DAYLIGHT\r
END:VTIMEZONE\r
BEGIN:VEVENT\r
ORGANIZER:mailto:a@example.com\r
ATTACH:http://www.example.com/\r
CATEGORIES:SPORTS EVENT,ENTERTAINMENT\r
CLASS:PRIVATE\r
DESCRIPTION:MIDWAY STADIUM\n\r
  Big time game.  MUST see.\n\r
  Expected duration:2 hours\n\r
DTEND;TZID=America-Chicago:19970701T180000\r
DTSTART;TZID=America-Chicago:19970702T160000\r
DTSTAMP:19970614T190000Z\r
STATUS:CONFIRMED\r
LOCATION;VALUE=URI:http://stadium.example.com/\r
PRIORITY:2\r
RESOURCES:SCOREBOARD\r
SEQUENCE:3\r
SUMMARY:ST. PAUL SAINTS -VS- DULUTH-SUPERIOR DUKES\r
UID:0981234-1234234-23@example.com\r
RELATED-TO:0981234-1234234-14@example.com\r
BEGIN:VALARM\r
TRIGGER:-PT2H\r
ACTION:DISPLAY\r
DESCRIPTION:You should be leaving for the game now.\r
END:VALARM\r
BEGIN:VALARM\r
TRIGGER:-PT30M\r
ACTION:AUDIO\r
END:VALARM\r
END:VEVENT\r
END:VCALENDAR\r
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.publish);
      expect((iCalendar.children[1] as VEvent).sequence, 3);
      // other properties are covered by components_test.dart
    });

    test('Anniversaries or Events Attached to Entire Days', () {
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:PUBLISH
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
DTSTAMP:19970614T190000Z
UID:0981234-1234234-23@example.com
DTSTART;VALUE=DATE:19970714
RRULE:FREQ=YEARLY;INTERVAL=1
SUMMARY: Bastille Day
END:VEVENT
END:VCALENDAR
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.publish);
      // expect((iCalendar.children.first as VEvent).sequence, 2);
      // other properties are covered by components_test.dart
    });

    test('A Group Event Request', () {
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED;CN=A:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL;CN=B:mailto:b@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL;CN=C:mailto:c@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL;CN=Hal:mailto:d@example.com
ATTENDEE;RSVP=FALSE;CUTYPE=ROOM:conf_big@example.com
ATTENDEE;ROLE=NON-PARTICIPANT;RSVP=FALSE:mailto:e@example.com
DTSTAMP:19970611T190000Z
DTSTART:19970701T200000Z
DTEND:19970701T2100000Z
SUMMARY:Conference
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:0
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      final event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 6);
      expect(event.attendees[0].role, Role.chair);
      expect(event.attendees[0].participantStatus, ParticipantStatus.accepted);
      expect(event.attendees[1].role, Role.requiredParticipant);
      expect(event.attendees[1].userType, CalendarUserType.individual);
      expect(event.attendees[1].rsvp, true);
      expect(event.attendees[4].role, Role.requiredParticipant);
      expect(event.attendees[4].userType, CalendarUserType.room);
      expect(event.attendees[4].rsvp, false);
      expect(event.attendees[5].role, Role.nonParticpant);
      expect(event.attendees[5].rsvp, false);
      // other properties are covered by components_test.dart
    });

    test('Reply to a Group Event Request', () {
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REPLY
VERSION:2.0
BEGIN:VEVENT
ATTENDEE;PARTSTAT=ACCEPTED:mailto:b@example.com
ORGANIZER:mailto:a@example.com
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:0
REQUEST-STATUS:2.0;Success
DTSTAMP:19970612T190000Z
END:VEVENT
END:VCALENDAR
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.reply);
      final event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 1);
      expect(event.attendees[0].participantStatus, ParticipantStatus.accepted);
      expect(event.attendees[0].email, 'b@example.com');
      expect(event.requestStatus, '2.0;Success');
      expect(event.requestStatusIsSuccess, isTrue);
      // other properties are covered by components_test.dart
    });

    test('Update an Event', () {
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL;CN=Hal:mailto:d@example.com
ATTENDEE;ROLE=NON-PARTICIPANT;RSVP=FALSE;
  CUTYPE=ROOM:mailto:conf@example.com
ATTENDEE;ROLE=NON-PARTICIPANT;RSVP=FALSE:mailto:e@example.com
DTSTART:19970701T180000Z
DTEND:19970701T190000Z
SUMMARY:Phone Conference
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:1
DTSTAMP:19970613T190000Z
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';
      final iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      final event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 6);
      // other properties are covered by components_test.dart
    });

    test('Countering an Event Proposal', () {
      // "A" sends a "REQUEST" to "B" and "C".  "B" makes a counter proposal
      //  to "A" to change the time and location.

      // "A" sends the following "REQUEST":
      var input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:c@example.com
DTSTART:19970701T190000Z
DTEND:19970701T200000Z
SUMMARY:Discuss the Merits of the election results
LOCATION:Green Conference Room
UID:calsrv.example.com-873970198738777a@example.com
SEQUENCE:0
DTSTAMP:19970611T190000Z
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);
      // other properties are covered by components_test.dart

      // "B" sends "COUNTER" to "A", requesting changes to time and place.
      //  "B" uses the "COMMENT" property to communicate a rationale for the
      //  change.  Note that the "SEQUENCE" property is not incremented on a
      //  "COUNTER".
      input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:COUNTER
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:c@example.com
DTSTART:19970701T160000Z
DTEND:19970701T170000Z
DTSTAMP:19970612T190000Z
SUMMARY:Discuss the Merits of the election results
LOCATION:Blue Conference Room
COMMENT:This time works much better and I think the big conference 
 room is too big
UID:calsrv.example.com-873970198738777a@example.com
SEQUENCE:0
END:VEVENT
END:VCALENDAR
''';
      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.counter);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.comment,
          'This time works much better and I think the big conference room is too big');
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);

      // "A" accepts the changes from "B".  To accept a counter proposal, the
      //  "Organizer" sends a new event "REQUEST" with an incremented sequence
      //  number.

      input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:c@example.com
DTSTAMP:19970613T190000Z
DTSTART:19970701T160000Z
DTEND:19970701T170000Z
SUMMARY:Discuss the Merits of the election results - changed to
  meet B's schedule
LOCATION:Blue Conference Room
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:1
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR''';

      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.status, EventStatus.confirmed);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);

      // Instead, "A" rejects "B's" counter proposal.
      input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:DECLINECOUNTER
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
COMMENT:Sorry, I cannot change this meeting time
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:0
DTSTAMP:19970614T190000Z
END:VEVENT
END:VCALENDAR''';

      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.declineCounter);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 1);
      expect(event.comment, 'Sorry, I cannot change this meeting time');
    });

    test('Delegating an Event', () {
      // "A" sends a "REQUEST" to "B" and "C".  "C" delegates the event to "E"

      // "C" responds to the "Organizer" "A":
      var input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REPLY
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-
 TO="mailto:e@example.com":mailto:c@example.com
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:0
REQUEST-STATUS:2.0;Success
DTSTAMP:19970611T190000Z
END:VEVENT
END:VCALENDAR
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.reply);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.requestStatusIsSuccess, isTrue);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 1);
      expect(event.attendees[0].participantStatus, ParticipantStatus.delegated);
      expect(event.attendees[0].email, 'c@example.com');
      expect(event.attendees[0].delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(event.attendees[0].delegatedToEmail, 'e@example.com');
      // other properties are covered by components_test.dart

      // "Attendee" "C" delegates presence at the meeting to "E".
      input =
          '''BEGIN:VCALENDAR\r
PRODID:-//Example/ExampleCalendarClient//EN\r
METHOD:REQUEST\r
VERSION:2.0\r
BEGIN:VEVENT\r
ORGANIZER:mailto:a@example.com\r
ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-\r
 TO="mailto:e@example.com":mailto:c@example.com\r
ATTENDEE;RSVP=TRUE;\r
 DELEGATED-FROM="mailto:c@example.com":mailto:e@example.com\r
DTSTART:19970701T180000Z\r
DTEND:19970701T200000Z\r
SUMMARY:Phone Conference\r
UID:calsrv.example.com-873970198738777@example.com\r
SEQUENCE:0\r
STATUS:CONFIRMED\r
DTSTAMP:19970611T190000Z\r
END:VEVENT\r
END:VCALENDAR\r
''';
      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 2);
      expect(event.attendees[0].participantStatus, ParticipantStatus.delegated);
      expect(event.attendees[0].email, 'c@example.com');
      expect(event.attendees[0].delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(event.attendees[0].delegatedToEmail, 'e@example.com');
      expect(event.attendees[1].rsvp, isTrue);
      expect(
          event.attendees[1].delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(event.attendees[1].delegatedFromEmail, 'c@example.com');
      expect(event.attendees[1].email, 'e@example.com');
      expect(event.status, EventStatus.confirmed);
    });

    test('Delegate Accepts the Meeting', () {
      // "A" sends a "REQUEST" to "B" and "C".  "B" delegates the event to "E"

      // To accept a delegated meeting, the delegate, "E", sends the following
      //  message to "A" and "C".

      var input =
          '''BEGIN:VCALENDAR\r
PRODID:-//Example/ExampleCalendarClient//EN\r
METHOD:REPLY\r
VERSION:2.0\r
BEGIN:VEVENT\r
ORGANIZER:mailto:a@example.com\r
ATTENDEE;PARTSTAT=ACCEPTED;DELEGATED-\r
  FROM="mailto:c@example.com":mailto:e@example.com\r
ATTENDEE;PARTSTAT=DELEGATED;\r
  DELEGATED-TO="mailto:e@example.com":mailto:c@example.com\r
UID:calsrv.example.com-873970198738777@example.com\r
SEQUENCE:0\r
REQUEST-STATUS:2.0;Success\r
DTSTAMP:19970614T190000Z\r
END:VEVENT\r
END:VCALENDAR\r
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.reply);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.requestStatusIsSuccess, isTrue);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 2);
      expect(event.attendees[0].participantStatus, ParticipantStatus.accepted);
      expect(event.attendees[0].email, 'e@example.com');
      expect(
          event.attendees[0].delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(event.attendees[0].delegatedFromEmail, 'c@example.com');
      expect(event.attendees[1].participantStatus, ParticipantStatus.delegated);
      expect(event.attendees[1].email, 'c@example.com');
      expect(event.attendees[1].delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(event.attendees[1].delegatedToEmail, 'e@example.com');
      // other properties are covered by components_test.dart
    });

    test('Delegate Declines the Meeting', () {
      // "A" sends a "REQUEST" to "B" and "C".  "B" delegates the event to "E"

      // "E" responds to "A" and "C".  Note the use of the "COMMENT" property
      //  "E" uses to indicate why the delegation was declined.

      var input =
          '''BEGIN:VCALENDAR\r
PRODID:-//Example/ExampleCalendarClient//EN\r
METHOD:REPLY\r
VERSION:2.0\r
BEGIN:VEVENT\r
ORGANIZER:mailto:a@example.com\r
ATTENDEE;PARTSTAT=DECLINED;\r
  DELEGATED-FROM="mailto:c@example.com":mailto:e@example.com\r
ATTENDEE;PARTSTAT=DELEGATED;\r
  DELEGATED-TO="mailto:e@example.com":mailto:c@example.com\r
COMMENT:Sorry, I will be out of town at that time.\r
UID:calsrv.example.com-873970198738777@example.com\r
SEQUENCE:0\r
REQUEST-STATUS:2.0;Success\r
DTSTAMP:19970614T190000Z\r
END:VEVENT\r
END:VCALENDAR\r
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.reply);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.requestStatusIsSuccess, isTrue);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 2);
      expect(event.attendees[0].participantStatus, ParticipantStatus.declined);
      expect(event.attendees[0].email, 'e@example.com');
      expect(
          event.attendees[0].delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(event.attendees[0].delegatedFromEmail, 'c@example.com');
      expect(event.attendees[1].participantStatus, ParticipantStatus.delegated);
      expect(event.attendees[1].email, 'c@example.com');
      expect(event.attendees[1].delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(event.attendees[1].delegatedToEmail, 'e@example.com');
      expect(event.comment, 'Sorry, I will be out of town at that time.');
      // other properties are covered by components_test.dart

      //  "A" resends the "REQUEST" method to "C".  "A" may also wish to
      //  express the fact that the item was delegated in the "COMMENT"
      //  property.

      input =
          '''BEGIN:VCALENDAR\r
PRODID:-//Example/ExampleCalendarClient//EN\r
METHOD:REQUEST\r
VERSION:2.0\r
BEGIN:VEVENT\r
ORGANIZER:mailto:a@example.com\r
ATTENDEE;PARTSTAT=DECLINED;\r
  DELEGATED-FROM="mailto:c@example.com":mailto:e@example.com\r
ATTENDEE;RSVP=TRUE:mailto:c@example.com\r
UID:calsrv.example.com-873970198738777@example.com\r
SEQUENCE:0\r
SUMMARY:Phone Conference\r
DTSTART:19970701T180000Z\r
DTEND:19970701T200000Z\r
DTSTAMP:19970614T200000Z\r
COMMENT:DELEGATE (ATTENDEE mailto:e@example.com) DECLINED YOUR \r
  INVITATION\r
END:VEVENT\r
END:VCALENDAR\r
''';
      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.requestStatusIsSuccess, isTrue);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 2);
      expect(event.attendees[0].participantStatus, ParticipantStatus.declined);
      expect(event.attendees[0].email, 'e@example.com');
      expect(
          event.attendees[0].delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(event.attendees[0].delegatedFromEmail, 'c@example.com');
      expect(event.attendees[1].rsvp, isTrue);
      expect(event.attendees[1].email, 'c@example.com');
      expect(event.comment,
          'DELEGATE (ATTENDEE mailto:e@example.com) DECLINED YOUR INVITATION');
    });

    test('Cancel a Group Event', () {
      // Individual "A" requests a meeting between individuals "A", "B", "C",
      //  and "D".  Individual "B" declines attendance to the meeting.
      //  Individual "A" decides to cancel the meeting.  The following table
      //  illustrates the sequence of messages that would be exchanged between
      //  these individuals.

      //  Messages related to a previously canceled event ("SEQUENCE" property
      //  value is less than the "SEQUENCE" property value of the "CANCEL"
      //  message) MUST be ignored.

      // This example shows how "A" cancels the event.
      var input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:CANCEL
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:d@example.com
COMMENT:Mr. B cannot attend.  It's raining.  Lets cancel.
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:1
STATUS:CANCELLED
DTSTAMP:19970613T190000Z
END:VEVENT
END:VCALENDAR
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.cancel);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.status, EventStatus.cancelled);
      expect(
          event.comment, 'Mr. B cannot attend.  It\'s raining.  Lets cancel.');
      // other properties are covered by components_test.dart
    });

    test('Removing Attendees', () {
      //  "A" wants to remove "B" from a meeting.  This is done by sending a
      //  "CANCEL" to "B" and removing "B" from the "Attendee" list in the
      //  master copy of the event.

      // The original meeting includes "A", "B", "C", and "D".  The example
      //  below shows the "CANCEL" that "A" sends to "B".  Note that in the
      //  example below, the "STATUS" property is omitted.  This is used when
      //  the meeting itself is cancelled and not when the intent is to remove
      //  an "Attendee" from the event.
      var input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:CANCEL
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE:mailto:b@example.com
COMMENT:You're off the hook for this meeting
UID:calsrv.example.com-873970198738777@example.com
DTSTAMP:19970613T193000Z
SEQUENCE:1
END:VEVENT
END:VCALENDAR
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.cancel);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.comment, 'You\'re off the hook for this meeting');
      // other properties are covered by components_test.dart

      //  The updated master copy of the event is shown below.  The "Organizer"
      //  MAY resend the updated event to the remaining "Attendees".  Note that
      //  "B" has been removed.

      input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:d@example.com
ATTENDEE;CUTYPE=ROOM:mailto:cr_big@example.com
ATTENDEE;ROLE=NON-PARTICIPANT;
  RSVP=FALSE:mailto:e@example.com
DTSTAMP:19970611T190000Z
DTSTART:19970701T200000Z
DTEND:19970701T203000Z
SUMMARY:Phone Conference
UID:calsrv.example.com-873970198738777@example.com
SEQUENCE:2
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';
      iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 2);
      expect(event.attendees.length, 5);
      expect(event.attendees[4].role, Role.nonParticpant);
      expect(event.attendees[4].rsvp, isFalse);
      expect(event.attendees[4].email, 'e@example.com');
    });

    test('Replacing the Organizer', () {
      //  The scenario for this example begins with "A" as the "Organizer" for
      //  a recurring meeting with "B", "C", and "D".  "A" receives a new job
      //  offer in another country and drops out of touch.  "A" left no
      //  forwarding address or way to be reached.  Using out-of-band
      //  communication, the other "Attendees" eventually learn what has
      //  happened and reach an agreement that "B" should become the new
      //  "Organizer" for the meeting.  To do this, "B" sends out a new version
      //  of the event and the other "Attendees" agree to accept "B" as the new
      //  "Organizer".  "B" also removes "A" from the event.

      //  When the "Organizer" is replaced, the "SEQUENCE" property value MUST
      //  be incremented.

      //  This is the message "B" sends to "C" and "D".

      var input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
METHOD:REQUEST
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:b@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:b@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:d@example.com
DTSTAMP:19970611T190000Z
DTSTART:19970701T200000Z
DTEND:19970701T203000Z
RRULE:FREQ=WEEKLY
SUMMARY:Phone Conference
UID:123456@example.com
SEQUENCE:1
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
''';
      var iCalendar = VComponent.parse(input);
      expect(iCalendar, isA<VCalendar>());
      expect((iCalendar as VCalendar).method, Method.request);
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.status, EventStatus.confirmed);
      expect(event.attendees.length, 3);
      expect(event.organizer?.email, 'b@example.com');
      // other properties are covered by components_test.dart
    });
  });
}
