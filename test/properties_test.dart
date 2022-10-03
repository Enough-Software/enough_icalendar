import 'package:test/test.dart';
import 'package:enough_icalendar/enough_icalendar.dart';

void main() {
  group('Direct Property Instantiation', () {
    test('OrganizerProperty', () {
      final prop = OrganizerProperty(
          'ORGANIZER;CN="Covidzentrum Bremen":MAILTO:sofortsupport@ticket.io');
      expect(prop.name, 'ORGANIZER');
      expect(prop.textValue, 'MAILTO:sofortsupport@ticket.io');
      expect(prop.value, Uri.parse('MAILTO:sofortsupport@ticket.io'));
      expect(prop.parameters, isNotEmpty);
      expect(prop.parameters.length, 1);
      expect(prop.parameters['CN'], isNotNull);
      expect(prop[ParameterType.commonName], isNotNull);
      expect(prop.parameters['CN'], prop[ParameterType.commonName]);
      expect(prop.parameters['CN']!.textValue, '"Covidzentrum Bremen"');
      expect(prop.parameters['CN']!.value, 'Covidzentrum Bremen');
      expect(prop.commonName, 'Covidzentrum Bremen');
    });

    test('GeoProperty', () {
      final prop = GeoProperty('GEO:37.386013;-122.082932');
      expect(prop.name, 'GEO');
      expect(prop.textValue, '37.386013;-122.082932');
      expect(prop.location.latitude, 37.386013);
      expect(prop.location.longitude, -122.082932);
    });

    test('Duration PT1H0M0S', () {
      final prop = DurationProperty('DURATION:PT1H0M0S');
      expect(prop.name, 'DURATION');
      expect(prop.textValue, 'PT1H0M0S');
      expect(prop.duration, isNotNull);
      expect(prop.duration.years, 0);
      expect(prop.duration.months, 0);
      expect(prop.duration.weeks, 0);
      expect(prop.duration.days, 0);
      expect(prop.duration.hours, 1);
      expect(prop.duration.minutes, 0);
      expect(prop.duration.days, 0);
    });
    test('DURATION:PT15M', () {
      final prop = DurationProperty('DURATION:PT15M');
      expect(prop.name, 'DURATION');
      expect(prop.textValue, 'PT15M');
      expect(prop.duration, isNotNull);
      expect(prop.duration.years, 0);
      expect(prop.duration.months, 0);
      expect(prop.duration.weeks, 0);
      expect(prop.duration.days, 0);
      expect(prop.duration.hours, 0);
      expect(prop.duration.minutes, 15);
      expect(prop.duration.days, 0);
    });

    test('DURATION:P1Y6M2W', () {
      final prop = DurationProperty('DURATION:P1Y6M2W');
      expect(prop.name, 'DURATION');
      expect(prop.textValue, 'P1Y6M2W');
      expect(prop.duration, isNotNull);
      expect(prop.duration.years, 1);
      expect(prop.duration.months, 6);
      expect(prop.duration.weeks, 2);
      expect(prop.duration.days, 0);
      expect(prop.duration.hours, 0);
      expect(prop.duration.minutes, 0);
      expect(prop.duration.days, 0);
    });

    test('ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:jsmith@example.com',
        () {
      final prop = AttendeeProperty(
          'ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:jsmith@example.com');
      expect(prop.name, 'ATTENDEE');
      expect(prop.textValue, 'mailto:jsmith@example.com');
      expect(prop.attendee, Uri.parse('mailto:jsmith@example.com'));
      expect(prop.role, Role.requiredParticipant);
      expect(prop.rsvp, isTrue);
    });
  });

  group('Indirect Property Instantiation', () {
    test('UTC Start Date', () {
      final prop = Property.parseProperty('DTSTART:20210803T080000Z');
      expect(prop, isA<DateTimeProperty>());
      expect(prop.name, 'DTSTART');
      expect(prop.textValue, '20210803T080000Z');
      expect((prop as DateTimeProperty).dateTime.isUtc, isTrue);
      expect(prop.dateTime, DateTime.utc(2021, 08, 03, 08, 00));
    });
    test('GeoProperty', () {
      final prop = Property.parseProperty('GEO:37.386013;-122.082932');
      expect(prop, isA<GeoProperty>());
      expect(prop.name, 'GEO');
      expect(prop.textValue, '37.386013;-122.082932');
      expect((prop as GeoProperty).location.latitude, 37.386013);
      expect(prop.location.longitude, -122.082932);
    });

    test('RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      final prop = Property.parseProperty(
          'RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
      expect(prop, isA<RecurrenceRuleProperty>());

      expect(prop.name, 'RRULE');
      expect((prop as RecurrenceRuleProperty).rule.frequency,
          RecurrenceFrequency.yearly);
      expect(prop.rule.byWeekDay, isNotEmpty);
      expect(prop.rule.byWeekDay!.length, 1);
      expect(prop.rule.byWeekDay![0].weekday, DateTime.sunday);
      expect(prop.rule.byWeekDay![0].week, 1);
      expect(prop.rule.byMonth, isNotEmpty);
      expect(prop.rule.byMonth!.length, 1);
      expect(prop.rule.byMonth![0], 4);
      expect(prop.rule.until, DateTime.utc(1998, 04, 04, 07));
    });

    test('RRULE:FREQ=UNKNOWN;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      try {
        Property.parseProperty(
            'RRULE:FREQ=UNKNOWN;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
      } on FormatException {
        // expected
      }
    });

    test('RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      try {
        Property.parseProperty(
            'RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
        fail('Invalid RECUR rule without frequency should fail');
      } on FormatException {
        // expected
      }
    });

    test('ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:jsmith@example.com',
        () {
      final prop = Property.parseProperty(
          'ATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:jsmith@example.com');
      expect(prop, isA<AttendeeProperty>());
      expect(prop.name, 'ATTENDEE');
      expect((prop as AttendeeProperty).rsvp, isTrue);
      expect(prop.role, Role.requiredParticipant);
      expect(prop.textValue, 'mailto:jsmith@example.com');
      expect(prop.attendee, Uri.parse('mailto:jsmith@example.com'));
    });
  });

  test('FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:19970308T160000Z/PT8H30M', () {
    final prop = Property.parseProperty(
        'FREEBUSY;FBTYPE=BUSY-UNAVAILABLE:19970308T160000Z/PT8H30M');
    expect(prop.name, 'FREEBUSY');
    expect(prop.textValue, '19970308T160000Z/PT8H30M');
    expect((prop as FreeBusyProperty).freeBusyType,
        FreeBusyTimeType.busyUnavailable);
    expect(prop.periods, isNotNull);
    expect(prop.periods, isNotEmpty);
    expect(prop.periods.length, 1);
    expect(
        prop.periods.first.startDate, DateTime.utc(1997, 03, 08, 16, 00, 00));
    expect(prop.periods.first.duration, IsoDuration(hours: 8, minutes: 30));
  });

  test('FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H', () {
    final prop = Property.parseProperty(
        'FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H');
    expect(prop.name, 'FREEBUSY');
    expect(prop.textValue, '19970308T160000Z/PT3H,19970308T200000Z/PT1H');
    expect((prop as FreeBusyProperty).freeBusyType, FreeBusyTimeType.free);
    expect(prop.periods, isNotEmpty);
    expect(prop.periods.length, 2);
    expect(prop.periods[0].startDate, DateTime.utc(1997, 03, 08, 16, 00, 00));
    expect(prop.periods[0].duration, IsoDuration(hours: 3));
    expect(prop.periods[1].startDate, DateTime.utc(1997, 03, 08, 20, 00, 00));
    expect(prop.periods[1].duration, IsoDuration(hours: 1));
  });

  test(
      'FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H,19970308T230000Z/19970309T000000Z',
      () {
    final prop = Property.parseProperty(
        'FREEBUSY;FBTYPE=FREE:19970308T160000Z/PT3H,19970308T200000Z/PT1H,19970308T230000Z/19970309T000000Z');
    expect(prop.name, 'FREEBUSY');
    expect(prop.textValue,
        '19970308T160000Z/PT3H,19970308T200000Z/PT1H,19970308T230000Z/19970309T000000Z');
    expect((prop as FreeBusyProperty).freeBusyType, FreeBusyTimeType.free);
    expect(prop.periods, isNotEmpty);
    expect(prop.periods.length, 3);
    expect(prop.periods[0].startDate, DateTime.utc(1997, 03, 08, 16, 00, 00));
    expect(prop.periods[0].duration, IsoDuration(hours: 3));
    expect(prop.periods[0].endDate, isNull);
    expect(prop.periods[1].startDate, DateTime.utc(1997, 03, 08, 20, 00, 00));
    expect(prop.periods[1].duration, IsoDuration(hours: 1));
    expect(prop.periods[0].endDate, isNull);
    expect(prop.periods[2].startDate, DateTime.utc(1997, 03, 08, 23, 00, 00));
    expect(prop.periods[2].duration, isNull);
    expect(prop.periods[2].endDate, DateTime.utc(1997, 03, 09, 00, 00, 00));
  });
}
