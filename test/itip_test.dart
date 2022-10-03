import 'package:test/test.dart';
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:collection/collection.dart' show IterableExtension;

// examples taken from https://datatracker.ietf.org/doc/html/rfc5546#section-4
void main() {
  group('VEVENT', () {
    test('Reply to a Group Event Request', () {
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
      expect(iCalendar.canReply, isTrue);
      final originalEvent = iCalendar.children.first as VEvent;
      final reply = iCalendar.replyWithParticipantStatus(
          ParticipantStatus.accepted,
          attendeeEmail: 'b@example.com');
      reply.checkValidity();
      expect(reply.method, Method.reply);
      expect(reply.version, '2.0');
      expect(reply.children, isNotEmpty);
      expect(reply.children.first, isA<VEvent>());
      final event = reply.children.first as VEvent;
      event.checkValidity();
      expect(event.uid, originalEvent.uid);
      expect(event.sequence, originalEvent.sequence);
      expect(event.organizer, originalEvent.organizer);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees[0].email, 'b@example.com');
      expect(event.attendees[0].participantStatus, ParticipantStatus.accepted);
      expect(event.requestStatus, '2.0;Success');

      final parsed = VComponent.parse(reply.toString());
      expect((parsed as VCalendar).method, Method.reply);
      expect(parsed.version, '2.0');
      expect(parsed.children, isNotEmpty);
      expect(parsed.children.first, isA<VEvent>());
      final parsedEvent = parsed.children.first as VEvent;
      expect(parsedEvent.uid, originalEvent.uid);
      expect(parsedEvent.sequence, originalEvent.sequence);
      expect(parsedEvent.organizer, originalEvent.organizer);
      expect(parsedEvent.attendees, isNotEmpty);
      expect(parsedEvent.attendees[0].email, 'b@example.com');
      expect(parsedEvent.attendees[0].participantStatus,
          ParticipantStatus.accepted);
      expect(parsedEvent.requestStatus, '2.0;Success');
      // print(reply);
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
      var event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 6);
      // now update it it:
      var update = iCalendar.update();
      expect(update, isA<VCalendar>());
      expect(update.method, Method.request);
      expect(update.version, '2.0');
      expect(update.productId, '-//Example/ExampleCalendarClient//EN');
      expect(update.children, isNotEmpty);
      event = update.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 2); // increased to 2
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 6);
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
      iCalendar = iCalendar.counter(
        comment:
            'This time works much better and I think the big conference room is too big',
        start: DateTime(1997, 07, 01, 16),
        end: DateTime(1997, 07, 01, 17),
        location: 'Blue Conference Room',
      );
      expect(iCalendar.method, Method.counter);
      event = iCalendar.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.comment,
          'This time works much better and I think the big conference room is too big');
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);
      expect(event.start, DateTime(1997, 07, 01, 16));
      expect(event.end, DateTime(1997, 07, 01, 17));

      // "A" accepts the changes from "B".  To accept a counter proposal, the
      //  "Organizer" sends a new event "REQUEST" with an incremented sequence
      //  number.
      final accepted = iCalendar.acceptCounter(
          description:
              'Discuss the Merits of the election results - changed to meet B\'s schedule');
      event = accepted.event!;
      expect(accepted.method, Method.request);
      expect(event.sequence, 1);
      expect(event.status, EventStatus.confirmed);
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);
      expect(event.description,
          'Discuss the Merits of the election results - changed to meet B\'s schedule');

      // Instead, "A" rejects "B's" counter proposal.
      final declined = iCalendar.declineCounter(
          attendeeEmail: 'b@example.com',
          comment: 'Sorry, I cannot change this meeting time');
      expect(declined.method, Method.declineCounter);
      expect(declined.children, isNotEmpty);
      event = declined.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).attendees, isNotEmpty);
      expect(event.attendees.length, 1);
      expect(event.attendees.first.email, 'b@example.com');
      expect(event.sequence, 0);
      expect(event.comment, 'Sorry, I cannot change this meeting time');
    });

    test('Delegating an Event', () {
      // "A" sends a "REQUEST" to "B" and "C".
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

      final original = VComponent.parse(input) as VCalendar;
// "C" delegates the event to "E":
      // "C" responds to the "Organizer" "A":
      final delegationResult = original.delegate(
        fromEmail: 'c@example.com',
        toEmail: 'e@example.com',
      );

      final delegationReply = delegationResult.replyForOrganizer;
      expect(delegationReply.method, Method.reply);
      var event = delegationReply.children.first;
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
      final delegated = delegationResult.requestForDelegatee;
      expect(delegated.method, Method.request);
      event = delegated.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      final attendees = event.attendees;
      expect(attendees, isNotEmpty);
      expect(attendees.length, 4);
      final from =
          attendees.firstWhereOrNull((a) => a.email == 'c@example.com');
      expect(from, isNotNull);
      expect(from!.participantStatus, ParticipantStatus.delegated);
      expect(from.email, 'c@example.com');
      expect(from.delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(from.delegatedToEmail, 'e@example.com');
      final to = attendees.firstWhereOrNull((a) => a.email == 'e@example.com');
      expect(to, isNotNull);
      expect(to!.rsvp, isTrue);
      expect(to.delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(to.delegatedFromEmail, 'c@example.com');
      expect(to.email, 'e@example.com');
      expect(event.status, EventStatus.confirmed);
    });

    test('Delegate Accepts the Meeting', () {
      // "A" sends a "REQUEST" to "B" and "C".  "C" delegates the event to "E"
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
DTSTART:19970701T190000Z
DTEND:19970701T200000Z
SUMMARY:Discuss the Merits of the election results
LOCATION:Green Conference Room
UID:calsrv.example.com-873970198738777a@example.com
SEQUENCE:0
DTSTAMP:19970611T190000Z
STATUS:CONFIRMED
ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-TO="mailto:e@example.com":mailto:c
 @example.com
ATTENDEE;DELEGATED-FROM="mailto:c@example.com";RSVP=TRUE:mailto:e@exampl
 e.com
END:VEVENT
END:VCALENDAR
''';
      final original = VComponent.parse(input) as VCalendar;

      // To accept a delegated meeting, the delegate, "E", sends the following
      //  message to "A" and "C".
      final accepted = original.replyWithParticipantStatus(
        ParticipantStatus.accepted,
        attendeeEmail: 'e@example.com',
      );
      expect(accepted.method, Method.reply);
      var event = accepted.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 0);
      expect(event.requestStatusIsSuccess, isTrue);
      expect(event.attendees, isNotEmpty);
      final delegatee =
          event.attendees.firstWhereOrNull((a) => a.email == 'e@example.com');
      expect(delegatee, isNotNull);

      expect(delegatee!.participantStatus, ParticipantStatus.accepted);
      expect(delegatee.email, 'e@example.com');
      expect(delegatee.delegatedFrom, Uri.parse('mailto:c@example.com'));
      expect(delegatee.delegatedFromEmail, 'c@example.com');
      // Usually only the accepting participant is listed, so I am keeping this different from the example
      final delegator =
          event.attendees.firstWhereOrNull((a) => a.email == 'c@example.com');
      expect(delegator, isNotNull);

      expect(delegator!.participantStatus, ParticipantStatus.delegated);
      expect(delegator.email, 'c@example.com');
      expect(delegator.delegatedTo, Uri.parse('mailto:e@example.com'));
      expect(delegator.delegatedToEmail, 'e@example.com');
      // other properties are covered by components_test.dart
    });

    test('Delegate Declines the Meeting', () {
      // "A" sends a "REQUEST" to "B" and "C".  "C" delegates the event to "E"
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED:mailto:a@example.com
ATTENDEE;RSVP=TRUE;CUTYPE=INDIVIDUAL:mailto:b@example.com
DTSTART:19970701T190000Z
DTEND:19970701T200000Z
SUMMARY:Discuss the Merits of the election results
LOCATION:Green Conference Room
UID:calsrv.example.com-873970198738777a@example.com
SEQUENCE:0
DTSTAMP:19970611T190000Z
STATUS:CONFIRMED
ATTENDEE;PARTSTAT=DELEGATED;DELEGATED-TO="mailto:e@example.com":mailto:c
 @example.com
ATTENDEE;DELEGATED-FROM="mailto:c@example.com";RSVP=TRUE:mailto:e@exampl
 e.com
END:VEVENT
END:VCALENDAR
''';
      final original = VComponent.parse(input) as VCalendar;
      // "E" responds to "A" and "C".  Note the use of the "COMMENT" property
      //  "E" uses to indicate why the delegation was declined.

      final declined = original.replyWithParticipantStatus(
        ParticipantStatus.declined,
        attendeeEmail: 'e@example.com',
        comment: 'Sorry, I will be out of town at that time.',
      );
      expect(declined.method, Method.reply);
      var event = declined.children.first;
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
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
VERSION:2.0
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:d@example.com
UID:calsrv.example.com-873970198738777@example.com
DTSTAMP:19970613T190000Z
END:VEVENT
END:VCALENDAR
''';
      final original = VComponent.parse(input) as VCalendar;
      final cancelled = original.cancelEvent(
        comment: 'Mr. B cannot attend.  It\'s raining.  Lets cancel.',
      );
      expect(cancelled.method, Method.cancel);
      var event = cancelled.children.first;
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

      final input =
          '''BEGIN:VCALENDAR
PRODID:-//Example/ExampleCalendarClient//EN
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
ORGANIZER:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:a@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:b@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:c@example.com
ATTENDEE;CUTYPE=INDIVIDUAL:mailto:d@example.com
UID:calsrv.example.com-873970198738777@example.com
DTSTAMP:19970613T190000Z
END:VEVENT
END:VCALENDAR
''';
      final original = VComponent.parse(input) as VCalendar;
      final cancelledChanges = original.cancelEventForAttendees(
        cancelledAttendeeEmails: ['b@example.com', 'd@example.com'],
        comment: 'You\'re off the hook for this meeting',
      );
      final cancelled = cancelledChanges.requestForCancelledAttendees;
      expect(cancelled.method, Method.cancel);
      var event = cancelled.children.first;
      expect(event, isA<VEvent>());
      expect((event as VEvent).sequence, 1);
      expect(event.comment, 'You\'re off the hook for this meeting');
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 2);
      expect(event.attendees[0].email, 'b@example.com');
      expect(event.attendees[1].email, 'd@example.com');
      // other properties are covered by components_test.dart

      //  The "Organizer"
      //  MAY resend the updated event to the remaining "Attendees".  Note that
      //  "B" and "D" have been removed.
      final updatedInvite = cancelledChanges.requestUpdateForGroup;
      expect(updatedInvite.method, Method.request);
      event = updatedInvite.event!;
      expect(event.sequence, isNull);
      expect(event.attendees.length, 4);
      expect(event.attendees[1].role, Role.nonParticpant);
      expect(event.attendees[1].rsvp, isFalse);
      expect(event.attendees[1].email, 'b@example.com');
      expect(event.attendees[3].role, Role.nonParticpant);
      expect(event.attendees[3].rsvp, isFalse);
      expect(event.attendees[3].email, 'd@example.com');
    });

    test('Replacing the Organizer', () {
      //TODO support with specific API necessary?
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
