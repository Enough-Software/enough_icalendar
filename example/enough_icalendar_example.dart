import 'package:enough_icalendar/enough_icalendar.dart';

void main() {
  parse();
  final invite = generate();
  changeParticipantStatus(invite);
  final counterProposal = counter(invite);
  acceptCounter(counterProposal);
  declineCounter(counterProposal);
  cancelEventForAll(invite);
  cancelForAttendee(invite, 'b@example.com');
  delegate(invite);
}

void parse() {
  final text = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:uid1@example.com
DTSTAMP:19970714T170000Z
ORGANIZER;CN=John Doe:MAILTO:john.doe@example.com
DTSTART:19970714T170000Z
DTEND:19970715T035959Z
RRULE:FREQ=YEARLY
SUMMARY:Bastille Day Party
GEO:48.85299;2.36885
END:VEVENT
END:VCALENDAR''';
  // As text can contain different elements,
  // VComponent.parse returns the generic VComponent base class.
  // In this case I am sure it's a VCalendar, so I can cast it directly:
  final icalendar = VComponent.parse(text) as VCalendar;
  print(icalendar.productId);
  // I'm sure that this calendar contains an event:
  final event = icalendar.event!;
  print(event.summary); // Bastille Day Party
  print(event.start); // 1997-06-14 at 17:00
  print(event.end); // 1997-07-15 at 03:59:59
  print(event.recurrenceRule?.toHumanReadableText()); // Annually
  print(event.recurrenceRule
      ?.toHumanReadableText(languageCode: 'de')); // Jährlich
  print(event.organizer?.commonName); // John Doe
  print(event.organizer?.email); // john.doe@example.com
  print(event.geoLocation?.latitude); // 48.85299
  print(event.geoLocation?.longitude); // 2.36885
}

VCalendar generate() {
  // You can generate invites using this convenience method.
  // Take full control by creating VCalendar, VEvent, VTodo, etc yourself.
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
  print('\nGenerated invite:');
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
}

void changeParticipantStatus(VCalendar invite) {
  final reply = invite.replyWithParticipantStatus(ParticipantStatus.accepted,
      attendeeEmail: 'b@example.com');
  print('\nAccepted by attendee b@example.com:');
  print(reply);
  // prints this:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar
  // VERSION:2.0
  // METHOD:REPLY
  // BEGIN:VEVENT
  // ORGANIZER:mailto:a@example.com
  // UID:RQPhszGcPqYFR4fRUT@example.com
  // ATTENDEE;PARTSTAT=ACCEPTED:mailto:b@example.com
  // DTSTAMP:20210719T093653
  // REQUEST-STATUS:2.0;Success
  // END:VEVENT
}

void delegate(VCalendar invite) {
  final delegationResult = invite.delegate(
    fromEmail: 'c@example.com',
    toEmail: 'e@example.com',
  );
  print('\nRequest for delegatee:');
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

  print('\nReply for organizer:');
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
}

VCalendar counter(VCalendar invite) {
  final counterProposal = invite.counter(
    comment: 'This time fits better, also we need some more time.',
    start: DateTime(2021, 07, 23, 10, 00),
    end: DateTime(2021, 07, 23, 12, 00),
    location: 'Carnegie Hall',
  );
  print('\nCounter proposal:');
  print(counterProposal);
  return counterProposal;
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
}

void acceptCounter(VCalendar counterProposal) {
  // An organizer can accept a counter proposal.
  // The updated invite is then sent to all attendees.
  final accepted = counterProposal.acceptCounter(
      comment: 'Accepted this proposed change of date and time');
  // The accepted proposal will have a higher sequence and the status automatically be set to EventStatus.confirmed.
  print('\nAccepted counter proposal:');
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
}

void declineCounter(VCalendar counterProposal) {
  // An organizer can decline a counter proposal.
  // The declined notice is then sent to the proposing attendee.
  final declined = counterProposal.declineCounter(
      attendeeEmail: 'b@example.com',
      comment: 'Sorry, but we have to stick to the original schedule');
  print('\Declined counter proposal:');
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
}

void cancelEventForAll(VCalendar invite) {
  // An organizer can cancel the event completely:
  final cancelled =
      invite.cancelEvent(comment: 'Sorry, let\'s skip this completely');
  print('\nCancelled event:');
  print(cancelled);
  // prints this:
  //
  // METHOD:CANCEL
  // BEGIN:VEVENT
  // UID:vmScK-AyJr0NX2nCsW@example.com
  // DTSTART:20210721T100000
  // DTEND:20210721T110000
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  // lopment. It seems that basic functionality is now covered. What's next?
  // LOCATION:Big meeting room
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // ATTENDEE;RSVP=TRUE:mailto:c@example.com
  // SEQUENCE:1
  // DTSTAMP:20210719T145004
  // STATUS:CANCELLED
  // COMMENT:Sorry, let's skip this completely
  // END:VEVENT
  // END:VCALENDAR
}

void cancelForAttendee(VCalendar invite, String cancelledAttendeeEmail) {
  // An organizer can cancel an event for specific attendees:
  final cancelChanges = invite.cancelEventForAttendees(
    cancelledAttendeeEmails: [cancelledAttendeeEmail],
    comment: 'You\'re off the hook, enjoy!',
  );
  print('\nChanges for cancelled attendees:');
  print(cancelChanges.requestForCancelledAttendees);
  // prints the following:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // METHOD:CANCEL
  // BEGIN:VEVENT
  // UID:vmScK-AyJr0NX2nCsW@example.com
  // DTSTART:20210721T100000
  // DTEND:20210721T110000
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // LOCATION:Big meeting room
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:b@example.com
  // SEQUENCE:1
  // DTSTAMP:20210719T162910
  // COMMENT:You're off the hook, enjoy!
  // END:VEVENT
  // END:VCALENDAR

  print('\nChanges for the group:');
  print(cancelChanges.requestUpdateForGroup);

  // prints the following:
  //
  // BEGIN:VCALENDAR
  // PRODID:enough_icalendar/v1
  // VERSION:2.0
  // BEGIN:VEVENT
  // DTSTAMP:20210719T162910
  // UID:vmScK-AyJr0NX2nCsW@example.com
  // DTSTART:20210721T100000
  // DTEND:20210721T110000
  // ORGANIZER:mailto:a@example.com
  // SUMMARY:Discussion
  // DESCRIPTION:Let us discuss how to proceed with the enough_icalendar deve
  //  lopment. It seems that basic functionality is now covered. What's next?
  // LOCATION:Big meeting room
  // URL:https://enough.de
  // ATTENDEE;RSVP=TRUE:mailto:a@example.com
  // ATTENDEE;RSVP=FALSE;ROLE=NON-PARTICIPANT:mailto:b@example.com
  // ATTENDEE;RSVP=TRUE:mailto:c@example.com
  // END:VEVENT
  // END:VCALENDAR
}
