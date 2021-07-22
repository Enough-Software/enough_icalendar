import 'package:flutter_test/flutter_test.dart';
import 'package:enough_icalendar/enough_icalendar.dart';

void main() {
  group('Fold Tests', () {
    test('No folding', () {
      final input =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR'''
              .split('\n');
      final output = VComponent.unfold(input);
      expect(output, isNotEmpty);
      expect(output.length, input.length);
      for (var i = 0; i < output.length; i++) {
        expect(output[i], input[i]);
      }
    });

    test('Unfold line spread accross 3 lines', () {
      final input =
          '''DESCRIPTION:This is a lo
 ng description 
       that exists on a long line.'''
              .split('\n');
      final output = VComponent.unfold(input);
      expect(output, isNotEmpty);
      expect(output.length, 1);
      expect(output[0],
          'DESCRIPTION:This is a long description that exists on a long line.');
    });

    test('Last line folded', () {
      final input =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCA
 LENDAR'''
              .split('\n');
      final output = VComponent.unfold(input);
      expect(output, isNotEmpty);
      expect(output.length, input.length - 1);
      for (var i = 0; i < output.length - 1; i++) {
        expect(output[i], input[i]);
      }
      expect(output.last, 'END:VCALENDAR');
    });

    test('First line folded', () {
      final input =
          '''BEGI
 N:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR'''
              .split('\n');
      final output = VComponent.unfold(input);
      expect(output, isNotEmpty);
      expect(output.length, input.length - 1);
      for (var i = 1; i < output.length; i++) {
        expect(output[i], input[i + 1]);
      }
      expect(output.first, 'BEGIN:VCALENDAR');
    });

    test('Some lines folded', () {
      final input =
          '''BEGI
 N:VCALENDAR
VERSION:2.0
PRODID:-
 //hacksw/handcal//NON
 SGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-
    AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille 
  Day Par
  ty
END:VEVE
 NT
END:VCALENDAR'''
              .split('\n');
      final output = VComponent.unfold(input);
      final expected =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR'''
              .split('\n');
      expect(output, isNotEmpty);
      expect(output.length, expected.length);
      for (var i = 0; i < output.length; i++) {
        expect(output[i], expected[i]);
      }
    });

    test('Some lines folded 2', () {
      final input =
          '''BEGIN:VCALENDAR
PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:19960704T120000Z
UID:uid1@example.com
ORGANIZER:mailto:jsmith@example.com
DTSTART:19960918T143000Z
DTEND:19960920T220000Z
STATUS:CONFIRMED
CATEGORIES:CONFERENCE
SUMMARY:Networld+Interop Conference
DESCRIPTION:Networld+Interop Conference 
  and Exhibit\\nAtlanta World Congress Center\\n
 Atlanta\\, Georgia
END:VEVENT
END:VCALENDAR
'''
              .split('\n');
      final output = VComponent.unfold(input);
      final expected =
          '''BEGIN:VCALENDAR
PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:19960704T120000Z
UID:uid1@example.com
ORGANIZER:mailto:jsmith@example.com
DTSTART:19960918T143000Z
DTEND:19960920T220000Z
STATUS:CONFIRMED
CATEGORIES:CONFERENCE
SUMMARY:Networld+Interop Conference
DESCRIPTION:Networld+Interop Conference and Exhibit\\nAtlanta World Congress Center\\nAtlanta\\, Georgia
END:VEVENT
END:VCALENDAR
'''
              .split('\n');
      expect(output, isNotEmpty);
      //expect(output.length, expected.length);
      for (var i = 0; i < output.length; i++) {
        expect(output[i], expected[i]);
      }
    });

    test('Some lines folded with LF linebreks in properties', () {
      final input =
          '''BEGIN:VCALENDAR
METHOD:xyz
VERSION:2.0
PRODID:-//ABC Corporation//NONSGML My Product//EN
BEGIN:VEVENT
DTSTAMP:19970324T120000Z
SEQUENCE:0
UID:uid3@example.com
ORGANIZER:mailto:jdoe@example.com
ATTENDEE;RSVP=TRUE:mailto:jsmith@example.com
DTSTART:19970324T123000Z
DTEND:19970324T210000Z
CATEGORIES:MEETING,PROJECT
CLASS:PUBLIC
SUMMARY:Calendaring Interoperability Planning Meeting
DESCRIPTION:Discuss how we can test c&s interoperability\\n
 using iCalendar and other IETF standards.
LOCATION:LDB Lobby
ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/
  conf/bkgrnd.ps
END:VEVENT
END:VCALENDAR
'''
              .split('\n');
      final output = VComponent.unfold(input);
      final expected =
          '''BEGIN:VCALENDAR
METHOD:xyz
VERSION:2.0
PRODID:-//ABC Corporation//NONSGML My Product//EN
BEGIN:VEVENT
DTSTAMP:19970324T120000Z
SEQUENCE:0
UID:uid3@example.com
ORGANIZER:mailto:jdoe@example.com
ATTENDEE;RSVP=TRUE:mailto:jsmith@example.com
DTSTART:19970324T123000Z
DTEND:19970324T210000Z
CATEGORIES:MEETING,PROJECT
CLASS:PUBLIC
SUMMARY:Calendaring Interoperability Planning Meeting
DESCRIPTION:Discuss how we can test c&s interoperability\\nusing iCalendar and other IETF standards.
LOCATION:LDB Lobby
ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/conf/bkgrnd.ps
END:VEVENT
END:VCALENDAR
'''
              .split('\n');
      expect(output, isNotEmpty);
      //expect(output.length, expected.length);
      for (var i = 0; i < output.length; i++) {
        expect(output[i], expected[i]);
      }
    });
  });

  group('Calendar Tests', () {
    test('Calendar simple - unix linebreaks', () {
      final text =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      expect(calendar.version, '2.0');
      expect(calendar.productId, '-//hacksw/handcal//NONSGML v1.0//EN');
      final event = calendar.children.first;
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary, 'Bastille Day Party');
      expect(event.uid, '19970610T172345Z-AF23B2@example.com');
      expect(event.timeStamp, DateTime(1997, 06, 10, 17, 23, 45));
      expect(event.start, DateTime(1997, 07, 14, 17, 00, 00));
      expect(event.end, DateTime(1997, 07, 15, 04, 00, 00));
    });

    test('Private event', () {
      final text =
          '''BEGIN:VEVENT
UID:19970901T130000Z-123401@example.com
DTSTAMP:19970901T130000Z
DTSTART:19970903T163000Z
DTEND:19970903T190000Z
SUMMARY:Annual Employee Review
CLASS:PRIVATE
CATEGORIES:BUSINESS,HUMAN RESOURCES
END:VEVENT''';
      final event = VComponent.parse(text);
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary, 'Annual Employee Review');
      expect(event.uid, '19970901T130000Z-123401@example.com');
      expect(event.timeStamp, DateTime(1997, 09, 01, 13, 00, 00));
      expect(event.start, DateTime(1997, 09, 03, 16, 30, 00));
      expect(event.end, DateTime(1997, 09, 03, 19, 00, 00));
      expect(event.classification, Classification.private);
      expect(event.categories, ['BUSINESS', 'HUMAN RESOURCES']);
    });

    test('Transparent event', () {
      final text =
          '''BEGIN:VEVENT
UID:19970901T130000Z-123402@example.com
DTSTAMP:19970901T130000Z
DTSTART:19970401T163000Z
DTEND:19970402T010000Z
SUMMARY:Laurel is in sensitivity awareness class.
CLASS:PUBLIC
CATEGORIES:BUSINESS,HUMAN RESOURCES
TRANSP:TRANSPARENT
END:VEVENT
''';
      final event = VComponent.parse(text);
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary,
          'Laurel is in sensitivity awareness class.');
      expect(event.uid, '19970901T130000Z-123402@example.com');
      expect(event.timeStamp, DateTime(1997, 09, 01, 13, 00, 00));
      expect(event.start, DateTime(1997, 04, 01, 16, 30, 00));
      expect(event.end, DateTime(1997, 04, 02, 1, 00, 00));
      expect(event.classification, Classification.public);
      expect(event.categories, ['BUSINESS', 'HUMAN RESOURCES']);
      expect(event.timeTransparency, TimeTransparency.transparent);
    });

    test('Recurrent event - yearly', () {
      final text =
          '''BEGIN:VEVENT\r
UID:19970901T130000Z-123403@example.com\r
DTSTAMP:19970901T130000Z\r
DTSTART;VALUE=DATE:19971102\r
SUMMARY:Our Blissful Anniversary\r
TRANSP:TRANSPARENT\r
CLASS:CONFIDENTIAL\r
CATEGORIES:ANNIVERSARY,PERSONAL,SPECIAL OCCASION\r
RRULE:FREQ=YEARLY\r
END:VEVENT\r
''';
      final event = VComponent.parse(text);
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary, 'Our Blissful Anniversary');
      expect(event.uid, '19970901T130000Z-123403@example.com');
      expect(event.timeStamp, DateTime(1997, 09, 01, 13, 00, 00));
      expect(event.start, DateTime(1997, 11, 02));
      expect(event.classification, Classification.confidential);
      expect(event.categories, ['ANNIVERSARY', 'PERSONAL', 'SPECIAL OCCASION']);
      expect(event.timeTransparency, TimeTransparency.transparent);
      expect(event.recurrenceRule, isNotNull);
      expect(event.recurrenceRule!.frequency, RecurrenceFrequency.yearly);
    });

    test('Day ending', () {
      final text =
          '''BEGIN:VEVENT
UID:20070423T123432Z-541111@example.com
DTSTAMP:20070423T123432Z
DTSTART;VALUE=DATE:20070628
DTEND;VALUE=DATE:20070709
SUMMARY:Festival International de Jazz de Montreal
TRANSP:TRANSPARENT
END:VEVENT
''';
      final event = VComponent.parse(text);
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary,
          'Festival International de Jazz de Montreal');
      expect(event.uid, '20070423T123432Z-541111@example.com');
      expect(event.timeStamp, DateTime(2007, 04, 23, 12, 34, 32));
      expect(event.start, DateTime(2007, 06, 28));
      expect(event.end, DateTime(2007, 07, 09));
      expect(event.timeTransparency, TimeTransparency.transparent);
      expect(event.recurrenceRule, isNull);
    });

    test('three-day conference example with CRLF line breaks', () {
      final text =
          '''BEGIN:VCALENDAR\r
PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN\r
VERSION:2.0\r
BEGIN:VEVENT\r
DTSTAMP:19960704T120000Z\r
UID:uid1@example.com\r
ORGANIZER:mailto:jsmith@example.com\r
DTSTART:19960918T143000Z\r
DTEND:19960920T220000Z\r
STATUS:CONFIRMED\r
CATEGORIES:CONFERENCE\r
SUMMARY:Networld+Interop Conference\r
DESCRIPTION:Networld+Interop Conference \r
  and Exhibit\nAtlanta World Congress Center\n\r
 Atlanta\, Georgia\r
END:VEVENT\r
END:VCALENDAR\r
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final event = calendar.children.first;
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).uid, 'uid1@example.com');
      expect(event.timeStamp, DateTime(1996, 07, 04, 12, 00, 00));
      expect(event.start, DateTime(1996, 09, 18, 14, 30, 00));
      expect(event.end, DateTime(1996, 09, 20, 22, 00, 00));
      expect(event.categories, ['CONFERENCE']);
      expect(event.status, EventStatus.confirmed);
      expect(event.organizer?.email, 'jsmith@example.com');
      expect(event.summary, 'Networld+Interop Conference');
      expect(event.description,
          'Networld+Interop Conference and Exhibit\nAtlanta World Congress Center\nAtlanta, Georgia');
    });

    test(
        'three-day conference example with LF line breaks and LF breaks in DESCRIPTION',
        () {
      final text =
          '''BEGIN:VCALENDAR
PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:19960704T120000Z
UID:uid1@example.com
ORGANIZER:mailto:jsmith@example.com
DTSTART:19960918T143000Z
DTEND:19960920T220000Z
STATUS:CONFIRMED
CATEGORIES:CONFERENCE
SUMMARY:Networld+Interop Conference
DESCRIPTION:Networld+Interop Conference 
  and Exhibit\nAtlanta World Congress Center\n
 Atlanta\, Georgia
END:VEVENT
END:VCALENDAR
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final event = calendar.children.first;
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).uid, 'uid1@example.com');
      expect(event.timeStamp, DateTime(1996, 07, 04, 12, 00, 00));
      expect(event.start, DateTime(1996, 09, 18, 14, 30, 00));
      expect(event.end, DateTime(1996, 09, 20, 22, 00, 00));
      expect(event.categories, ['CONFERENCE']);
      expect(event.status, EventStatus.confirmed);
      expect(event.organizer?.email, 'jsmith@example.com');
      expect(event.summary, 'Networld+Interop Conference');
      expect(event.description,
          'Networld+Interop Conference and Exhibit\nAtlanta World Congress Center\nAtlanta, Georgia');
    });

    test('group-scheduled meeting with VTIMEZONE', () {
      final text =
          '''BEGIN:VCALENDAR
PRODID:-//RDU Software//NONSGML HandCal//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:America/New_York
BEGIN:STANDARD
DTSTART:19981025T020000
TZOFFSETFROM:-0400
TZOFFSETTO:-0500
TZNAME:EST
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19990404T020000
TZOFFSETFROM:-0500
TZOFFSETTO:-0400
TZNAME:EDT
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
DTSTAMP:19980309T231000Z
UID:guid-1.example.com
ORGANIZER:mailto:mrbig@example.com
ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT;CUTYPE=GROUP:
 mailto:employee-A@example.com
DESCRIPTION:Project XYZ Review Meeting
CATEGORIES:MEETING
CLASS:PUBLIC
CREATED:19980309T130000Z
SUMMARY:XYZ Project Review
DTSTART;TZID=America/New_York:19980312T083000
DTEND;TZID=America/New_York:19980312T093000
LOCATION:1CP Conference Room 4350
END:VEVENT
END:VCALENDAR
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//RDU Software//NONSGML HandCal//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 2);
      final event = calendar.children[1];
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).uid, 'guid-1.example.com');
      expect(event.timeStamp, DateTime(1998, 03, 09, 23, 10, 00));
      expect(event.created, DateTime(1998, 03, 09, 13, 00, 00));
      expect(event.start, DateTime(1998, 03, 12, 08, 30, 00));
      expect(event.end, DateTime(1998, 03, 12, 09, 30, 00));
      expect(event.location, '1CP Conference Room 4350');
      expect(event.classification, Classification.public);
      expect(event.categories, ['MEETING']);
      expect(event.organizer?.email, 'mrbig@example.com');
      expect(event.summary, 'XYZ Project Review');
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 1);
      final attendee = event.attendees.first;
      expect(attendee.rsvp, isTrue);
      expect(attendee.role, Role.requiredParticipant);
      expect(attendee.userType, CalendarUserType.group);
      expect(attendee.email, 'employee-A@example.com');
      final timezone = calendar.children.first;
      expect(timezone, isInstanceOf<VTimezone>());
      expect((timezone as VTimezone).timezoneId, 'America/New_York');
      expect(timezone.children, isNotEmpty);
      expect(timezone.children.length, 2);
      var phase = timezone.children.first;
      expect(phase, isInstanceOf<VTimezonePhase>());
      expect(phase.name, 'STANDARD');
      expect(phase.componentType, VComponentType.timezonePhaseStandard);
      expect((phase as VTimezonePhase).timezoneName, 'EST');
      expect(phase.start, DateTime(1998, 10, 25, 02, 00, 00));
      expect(phase.from, UtcOffset.value(offsetHour: -4, offsetMinute: 0));
      expect(phase.to, UtcOffset.value(offsetHour: -5, offsetMinute: 0));
      phase = timezone.children[1];
      expect(phase, isInstanceOf<VTimezonePhase>());
      expect(phase.name, 'DAYLIGHT');
      expect(phase.componentType, VComponentType.timezonePhaseDaylight);
      expect((phase as VTimezonePhase).timezoneName, 'EDT');
      expect(phase.start, DateTime(1999, 04, 04, 02, 00, 00));
      expect(phase.from, UtcOffset.value(offsetHour: -5, offsetMinute: 0));
      expect(phase.to, UtcOffset.value(offsetHour: -4, offsetMinute: 0));
    });

    test('with attachments and sequence', () {
      final text =
          '''BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
PRODID:-//ABC Corporation//NONSGML My Product//EN
BEGIN:VEVENT
DTSTAMP:19970324T120000Z
SEQUENCE:0
UID:uid3@example.com
ORGANIZER:mailto:jdoe@example.com
ATTENDEE;RSVP=TRUE:mailto:jsmith@example.com
DTSTART:19970324T123000Z
DTEND:19970324T210000Z
CATEGORIES:MEETING,PROJECT
CLASS:PUBLIC
SUMMARY:Calendaring Interoperability Planning Meeting
DESCRIPTION:Discuss how we can test c&s interoperability\\n
 using iCalendar and other IETF standards.
LOCATION:LDB Lobby
ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/
  conf/bkgrnd.ps
END:VEVENT
END:VCALENDAR
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//ABC Corporation//NONSGML My Product//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.method, Method.publish);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final event = calendar.children.first;
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).uid, 'uid3@example.com');
      expect(event.timeStamp, DateTime(1997, 03, 24, 12, 00, 00));
      expect(event.start, DateTime(1997, 03, 24, 12, 30, 00));
      expect(event.end, DateTime(1997, 03, 24, 21, 00, 00));
      expect(event.organizer?.email, 'jdoe@example.com');
      expect(event.attendees.length, 1);
      expect(event.attendees[0].rsvp, isTrue);
      expect(event.attendees[0].email, 'jsmith@example.com');
      expect(event.categories, ['MEETING', 'PROJECT']);
      expect(event.classification, Classification.public);
      expect(event.summary, 'Calendaring Interoperability Planning Meeting');
      expect(event.description,
          'Discuss how we can test c&s interoperability\\nusing iCalendar and other IETF standards.');
      expect(event.location, 'LDB Lobby');
      // ATTACH;FMTTYPE=application/postscript:ftp://example.com/pub/conf/bkgrnd.ps
      expect(event.attachments, isNotEmpty);
      expect(event.attachments[0].mediaType, 'application/postscript');
      expect(event.attachments[0].uri,
          Uri.parse('ftp://example.com/pub/conf/bkgrnd.ps'));
      expect(event.sequence, 0);
    });

    test('Todo with audio alarm', () {
      final text =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ABC Corporation//NONSGML My Product//EN
BEGIN:VTODO
DTSTAMP:19980130T134500Z
SEQUENCE:2
UID:uid4@example.com
ORGANIZER:mailto:unclesam@example.com
ATTENDEE;PARTSTAT=ACCEPTED:mailto:jqpublic@example.com
DUE:19980415T000000
STATUS:NEEDS-ACTION
SUMMARY:Submit Income Taxes
BEGIN:VALARM
ACTION:AUDIO
TRIGGER;VALUE=DATE-TIME:19980403T120000Z
ATTACH;FMTTYPE=audio/basic:http://example.com/pub/audio-
 files/ssbanner.aud
REPEAT:4
DURATION:PT1H
END:VALARM
END:VTODO
END:VCALENDAR
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//ABC Corporation//NONSGML My Product//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final todo = calendar.children.first;
      expect(todo, isInstanceOf<VTodo>());
      expect((todo as VTodo).uid, 'uid4@example.com');
      expect(todo.timeStamp, DateTime(1998, 01, 30, 13, 45, 00));
      expect(todo.sequence, 2);
      expect(todo.organizer?.email, 'unclesam@example.com');
      expect(todo.attendees.length, 1);
      expect(todo.attendees[0].rsvp, isFalse);
      expect(todo.attendees[0].participantStatus, ParticipantStatus.accepted);
      expect(todo.attendees[0].email, 'jqpublic@example.com');
      expect(todo.summary, 'Submit Income Taxes');
      expect(todo.status, TodoStatus.needsAction);
      expect(todo.due, DateTime(1998, 04, 15, 00, 00, 00));
      expect(todo.children, isNotEmpty);
      expect(todo.children.length, 1);
      final alarm = todo.children.first;
      expect(alarm, isInstanceOf<VAlarm>());
      expect((alarm as VAlarm).componentType, VComponentType.alarm);
      expect(alarm.action, AlarmAction.audio);
      expect(alarm.triggerDate, DateTime(1998, 04, 03, 12, 00, 00));
      expect(alarm.repeat, 4);
      expect(alarm.duration, IsoDuration(hours: 1));
      expect(alarm.attachments, isNotEmpty);
      expect(alarm.attachments.length, 1);
      expect(alarm.attachments[0].mediaType, 'audio/basic');
      expect(alarm.attachments[0].uri,
          Uri.parse('http://example.com/pub/audio-files/ssbanner.aud'));
    });

    test('journal example', () {
      final text =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//RDU Software//NONSGML HandCal//EN
BEGIN:VFREEBUSY
UID:19970901T115957Z-76A912@example.com
DTSTAMP:19970901T120000Z
ORGANIZER:mailto:jsmith@example.com
DTSTART:19980313T141711Z
DTEND:19980410T141711Z
FREEBUSY:19980314T233000Z/19980315T003000Z
FREEBUSY:19980316T153000Z/19980316T163000Z
FREEBUSY:19980318T030000Z/19980318T040000Z
URL:http://www.example.com/calendar/busytime/jsmith.ifb
END:VFREEBUSY
END:VCALENDAR
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//RDU Software//NONSGML HandCal//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final freebusy = calendar.children.first;
      expect(freebusy, isInstanceOf<VFreeBusy>());
      expect((freebusy as VFreeBusy).organizer?.email, 'jsmith@example.com');
      expect(freebusy.timeStamp, DateTime(1997, 09, 01, 12, 00, 00));
      expect(freebusy.uid, '19970901T115957Z-76A912@example.com');
      expect(freebusy.organizer?.email, 'jsmith@example.com');
      expect(freebusy.start, DateTime(1998, 03, 13, 14, 17, 11));
      expect(freebusy.end, DateTime(1998, 04, 10, 14, 17, 11));
      expect(freebusy.url,
          Uri.parse('http://www.example.com/calendar/busytime/jsmith.ifb'));
      expect(freebusy.freeBusyProperties, isNotEmpty);
      expect(freebusy.freeBusyProperties.length, 3);
      expect(freebusy.freeBusyProperties[0].periods, isNotEmpty);
      expect(freebusy.freeBusyProperties[0].periods.length, 1);
      expect(freebusy.freeBusyProperties[0].periods[0].startDate,
          DateTime(1998, 03, 14, 23, 30, 00));
      expect(freebusy.freeBusyProperties[0].periods[0].endDate,
          DateTime(1998, 03, 15, 00, 30, 00));
      expect(
          freebusy.freeBusyProperties[0].freeBusyType, FreeBusyTimeType.busy);
      expect(freebusy.freeBusyProperties[1].periods.length, 1);
      expect(freebusy.freeBusyProperties[1].periods[0].startDate,
          DateTime(1998, 03, 16, 15, 30, 00));
      expect(freebusy.freeBusyProperties[1].periods[0].endDate,
          DateTime(1998, 03, 16, 16, 30, 00));
      expect(freebusy.freeBusyProperties[2].periods.length, 1);
      expect(freebusy.freeBusyProperties[2].periods[0].startDate,
          DateTime(1998, 03, 18, 03, 00, 00));
      expect(freebusy.freeBusyProperties[2].periods[0].endDate,
          DateTime(1998, 03, 18, 04, 00, 00));
    });

    test('free busy example', () {
      final text =
          '''BEGIN:VCALENDAR\r
VERSION:2.0\r
PRODID:-//ABC Corporation//NONSGML My Product//EN\r
BEGIN:VJOURNAL\r
DTSTAMP:19970324T120000Z\r
UID:uid5@example.com\r
ORGANIZER:mailto:jsmith@example.com\r
STATUS:DRAFT\r
CLASS:PUBLIC\r
CATEGORIES:Project Report,XYZ,Weekly Meeting\r
DESCRIPTION:Project xyz Review Meeting Minutes\n\r
 Agenda\n1. Review of project version 1.0 requirements.\n2. \r
  Definition \r
 of project processes.\n3. Review of project schedule.\n\r
 Participants: John Smith\, Jane Doe\, Jim Dandy\n-It was \r
  decided that the requirements need to be signed off by \r
  product marketing.\n-Project processes were accepted.\n\r
 -Project schedule needs to account for scheduled holidays \r
  and employee vacation time. Check with HR for specific \r
  dates.\n-New schedule will be distributed by Friday.\n-\r
 Next weeks meeting is cancelled. No meeting until 3/23.\r
END:VJOURNAL\r
END:VCALENDAR\r
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).productId,
          '-//ABC Corporation//NONSGML My Product//EN');
      expect(calendar.version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final journal = calendar.children.first;
      expect(journal, isInstanceOf<VJournal>());
      expect((journal as VJournal).uid, 'uid5@example.com');
      expect(journal.timeStamp, DateTime(1997, 03, 24, 12, 00, 00));
      expect(journal.organizer?.email, 'jsmith@example.com');
      expect(journal.classification, Classification.public);
      expect(journal.status, JournalStatus.draft);
      expect(journal.categories, ['Project Report', 'XYZ', 'Weekly Meeting']);
      expect(journal.description,
          '''Project xyz Review Meeting Minutes\nAgenda
1. Review of project version 1.0 requirements.
2. Definition of project processes.
3. Review of project schedule.
Participants: John Smith\, Jane Doe\, Jim Dandy\n-It was decided that the requirements need to be signed off by product marketing.
-Project processes were accepted.
-Project schedule needs to account for scheduled holidays and employee vacation time. Check with HR for specific dates.
-New schedule will be distributed by Friday.
-Next weeks meeting is cancelled. No meeting until 3/23.''');
    });

    test('Real world 1', () {
      final text =
          '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:http://ticket.io/
METHOD:PUBLISH
X-WR-TIMEZONE:Europe/Berlin
BEGIN:VEVENT
UID:ticketioa7a690b342c3a9fdbc20206572744d64
CLASS:PUBLIC
SUMMARY:Kostenloser Antigen-Schnelltest Bremen
LOCATION:, Außer der Schleifmühle 4, 28203 Bremen
DTSTART;TZID=Europe/Berlin:20210706T090000
DTEND;TZID=Europe/Berlin:20210706T210000
DTSTAMP:20210706T103042
DESCRIPTION:
ORGANIZER;CN="Covidzentrum Bremen":MAILTO:sofortsupport@ticket.io
END:VEVENT
END:VCALENDAR''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.calendarScale, 'GREGORIAN');
      expect(calendar.isGregorian, isTrue);
      expect(calendar.productId, 'http://ticket.io/');
      expect(calendar.timezoneId, 'Europe/Berlin');
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 1);
      final event = calendar.children.first;
      expect(event, isInstanceOf<VEvent>());
      expect(
          (event as VEvent).summary, 'Kostenloser Antigen-Schnelltest Bremen');
      expect(event.uid, 'ticketioa7a690b342c3a9fdbc20206572744d64');
      expect(event.classification, Classification.public);
      expect(event.timeStamp, DateTime(2021, 07, 06, 10, 30, 42));
      expect(event.start, DateTime(2021, 07, 06, 09, 00, 00));
      expect(event.end, DateTime(2021, 07, 06, 21, 00, 00));
      expect(event.description, '');
      expect(event.location, ', Außer der Schleifmühle 4, 28203 Bremen');
      expect(event.organizer, isNotNull);
      expect(event.organizer!.uri, Uri.parse('MAILTO:sofortsupport@ticket.io'));
      expect(event.organizer!.email, 'sofortsupport@ticket.io');
      expect(event.organizer!.commonName, 'Covidzentrum Bremen');
    });

    test('Real world 2', () {
      final text =
          '''BEGIN:VCALENDAR\r
VERSION:2.0\r
PRODID:-//Open-Xchange//7.10.3-Rev34//EN\r
METHOD:REQUEST\r
BEGIN:VTIMEZONE\r
TZID:Europe/Rome\r
LAST-MODIFIED:20201011T015911Z\r
TZURL:http://tzurl.org/zoneinfo-outlook/Europe/Rome\r
X-LIC-LOCATION:Europe/Rome\r
BEGIN:DAYLIGHT\r
TZNAME:CEST\r
TZOFFSETFROM:+0100\r
TZOFFSETTO:+0200\r
DTSTART:19700329T020000\r
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU\r
END:DAYLIGHT\r
BEGIN:STANDARD\r
TZNAME:CET\r
TZOFFSETFROM:+0200\r
TZOFFSETTO:+0100\r
DTSTART:19701025T030000\r
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU\r
END:STANDARD\r
END:VTIMEZONE\r
BEGIN:VEVENT\r
DTSTAMP:20210721T134636Z\r
ATTENDEE;CN=The invited one;PARTSTAT=NEEDS-ACTION;CUTYPE=INDIVIDUAL;EMAIL=som\r
 e.one@domain.com:mailto:some.one@domain.com\r
ATTENDEE;CN=Mrs Organizer;PARTSTAT=ACCEPTED;CUTYPE=INDIVIDUAL;EMAIL=mrs.organ\r
 izer@example.com:mailto:mrs.organizer@example.com\r
CLASS:PUBLIC\r
CREATED:20210721T134636Z\r
DESCRIPTION:Hey\, here's the event description\, with some commas.\r
DTEND;TZID=Europe/Rome:20210722T160000\r
DTSTART;TZID=Europe/Rome:20210722T140000\r
LAST-MODIFIED:20210721T134636Z\r
LOCATION:When in Rome...\r
ORGANIZER;CN=Mrs Organizer:mailto:mrs.organizer@example.com\r
SEQUENCE:0\r
SUMMARY:Example meeting\r
TRANSP:OPAQUE\r
UID:1dbfc3a9-a285-46ae-944a-15c3927ab7ac\r
X-MICROSOFT-CDO-BUSYSTATUS:BUSY\r
END:VEVENT\r
END:VCALENDAR\r
''';
      final calendar = VComponent.parse(text);
      expect(calendar, isInstanceOf<VCalendar>());
      expect((calendar as VCalendar).version, '2.0');
      expect(calendar.isVersion2, isTrue);
      expect(calendar.isGregorian, isTrue);
      expect(calendar.productId, '-//Open-Xchange//7.10.3-Rev34//EN');
      expect(calendar.timezoneId, 'Europe/Rome');
      expect(calendar.children, isNotEmpty);
      expect(calendar.children.length, 2);
      final event = calendar.children[1];
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).summary, 'Example meeting');
      expect(event.uid, '1dbfc3a9-a285-46ae-944a-15c3927ab7ac');
      expect(event.classification, Classification.public);
      expect(event.start, DateTime(2021, 07, 22, 14, 00, 00));
      expect(event.end, DateTime(2021, 07, 22, 16, 00, 00));
      expect(event.description,
          'Hey, here\'s the event description, with some commas.');
      expect(event.location, 'When in Rome...');
      expect(event.organizer, isNotNull);
      expect(
          event.organizer!.uri, Uri.parse('MAILTO:mrs.organizer@example.com'));
      expect(event.organizer!.email, 'mrs.organizer@example.com');
      expect(event.organizer!.commonName, 'Mrs Organizer');
      expect(event.busyStatus, EventBusyStatus.busy);
      expect(calendar.timezone?.location, 'Europe/Rome');
    });
  });

  group('Create Calendar Invites', () {
    test('Simple event', () {
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
      // print(invite);
      invite.checkValidity();
      expect(invite.isVersion2, isTrue);
      expect(invite.isGregorian, isTrue);
      expect(invite.productId, 'enough_icalendar/v1');
      expect(invite.children, isNotEmpty);
      final event = invite.children.first;
      event.checkValidity();
      expect(event, isInstanceOf<VEvent>());
      expect((event as VEvent).start, DateTime(2021, 07, 21, 10, 00));
      expect(event.end, DateTime(2021, 07, 21, 11, 00));
      expect(event.location, 'Big meeting room');
      expect(event.url, Uri.parse('https://enough.de'));
      expect(event.summary, 'Discussion');
      expect(event.description,
          'Let us discuss how to proceed with the enough_icalendar development. It seems that basic functionality is now covered. What\'s next?');
      expect(event.attendees, isNotEmpty);
      expect(event.attendees.length, 3);
      expect(event.attendees[0].rsvp, isTrue);
      expect(event.attendees[0].email, 'a@example.com');
      expect(event.attendees[1].rsvp, isTrue);
      expect(event.attendees[1].email, 'b@example.com');
      expect(event.attendees[2].rsvp, isTrue);
      expect(event.attendees[2].email, 'c@example.com');
      expect(event.organizer, isNotNull);
      expect(event.organizer?.email, 'a@example.com');
    });
  });
}
