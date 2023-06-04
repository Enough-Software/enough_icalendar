import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:test/test.dart';

void main() {
  group('Valid RRULE', () {
    test('RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, isNotEmpty);
      expect(ruleProp.rule.byWeekDay!.length, 1);
      expect(ruleProp.rule.byWeekDay![0].weekday, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay![0].week, 1);
      expect(ruleProp.rule.byMonth, isNotEmpty);
      expect(ruleProp.rule.byMonth!.length, 1);
      expect(ruleProp.rule.byMonth![0], 4);
      expect(ruleProp.rule.until, DateTime.utc(1998, 04, 04, 07));
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on the first Sunday of the month in April, until Saturday, April 4, 1998',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich an dem ersten Sonntag des Monats im April, bis zum Samstag, 4. April 1998',
      );
    });

    test('RRULE:FREQ=DAILY;COUNT=10', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=DAILY;COUNT=10');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.toHumanReadableText(), 'Daily, 10 times');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Täglich, 10-mal',
      );
    });

    test('RRULE:FREQ=DAILY;UNTIL=19971224T000000Z', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=DAILY;UNTIL=19971224T000000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.until, DateTime.utc(1997, 12, 24, 00, 00, 00));
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Daily, until Wednesday, December 24, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Täglich, bis zum Mittwoch, 24. Dezember 1997',
      );
    });

    test('RRULE:FREQ=DAILY;INTERVAL=2', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=DAILY;INTERVAL=2');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.toHumanReadableText(), 'Every other day');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Tage',
      );
    });

    test('RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.interval, 10);
      expect(ruleProp.rule.count, 5);
      expect(ruleProp.rule.toHumanReadableText(), 'Every 10 days, 5 times');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 10 Tage, 5-mal',
      );
    });

    test(
        'RRULE:FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        () {
      // Every day in January, for 3 years:
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.until, DateTime.utc(2000, 01, 31, 14, 00, 00));
      expect(ruleProp.rule.byMonth, [1]);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.sunday),
        ByDayRule(DateTime.monday),
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.wednesday),
        ByDayRule(DateTime.thursday),
        ByDayRule(DateTime.friday),
        ByDayRule(DateTime.saturday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on every day in January, until Monday, January 31, 2000',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich an jedem Tag im Januar, bis zum Montag, 31. Januar 2000',
      );
    });

    test('RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1', () {
      // Every day in January, for 3 years:
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.until, DateTime.utc(2000, 01, 31, 14, 00, 00));
      expect(ruleProp.rule.byMonth, [1]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Daily in January, until Monday, January 31, 2000',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Täglich im Januar, bis zum Montag, 31. Januar 2000',
      );
    });

    test('RRULE:FREQ=WEEKLY;COUNT=10', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;COUNT=10');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.toHumanReadableText(), 'Weekly, 10 times');
      expect(
        ruleProp.rule
            .toHumanReadableText(startDate: DateTime(2021, 07, 27, 15, 00)),
        'Every Tuesday, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(
            languageCode: 'de', startDate: DateTime(2021, 07, 27, 15, 00)),
        'Jeden Dienstag, 10-mal',
      );
    });

    test('RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.until, DateTime.utc(1997, 12, 24, 00, 00, 00));
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Weekly, until Wednesday, December 24, 1997',
      );
      expect(
        ruleProp.rule
            .toHumanReadableText(startDate: DateTime(1997, 12, 03, 15, 00)),
        'Every Wednesday, until Wednesday, December 24, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Wöchentlich, bis zum Mittwoch, 24. Dezember 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(
            languageCode: 'de', startDate: DateTime(1997, 12, 03, 15, 00)),
        'Jeden Mittwoch, bis zum Mittwoch, 24. Dezember 1997',
      );
    });

    test('RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.toHumanReadableText(), 'Every other week');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Wochen',
      );
      expect(
        ruleProp.rule
            .toHumanReadableText(startDate: DateTime(1997, 12, 03, 15, 00)),
        'Every other Wednesday',
      );
      expect(
        ruleProp.rule.toHumanReadableText(
            languageCode: 'de', startDate: DateTime(1997, 12, 03, 15, 00)),
        'Jeden zweiten Mittwoch',
      );
    });

    test('RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.until, DateTime.utc(1997, 10, 07, 00, 00, 00));
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Weekly on Tuesday & Thursday, until Tuesday, October 7, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(
          startDate: DateTime(1997, 12, 03, 15, 00),
        ),
        'Weekly on Tuesday & Thursday, until Tuesday, October 7, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Wöchentlich am Dienstag & Donnerstag, bis zum Dienstag, 7. Oktober 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(
            languageCode: 'de', startDate: DateTime(1997, 12, 03, 15, 00)),
        'Wöchentlich am Dienstag & Donnerstag, bis zum Dienstag, 7. Oktober 1997',
      );
    });
    test('RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Weekly on Tuesday & Thursday, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Wöchentlich am Dienstag & Donnerstag, 10-mal',
      );
    });
    test(
        'RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR',
        () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.until, DateTime.utc(1997, 12, 24, 00, 00, 00));
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday),
        ByDayRule(DateTime.wednesday),
        ByDayRule(DateTime.friday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every other week on Monday, Wednesday & Friday, until Wednesday, December 24, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Wochen am Montag, Mittwoch & Freitag, bis zum Mittwoch, 24. Dezember 1997',
      );
    });
    test('RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 8);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every other week on Tuesday & Thursday, 8 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Wochen am Dienstag & Donnerstag, 8-mal',
      );
    });
    test('RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.friday, week: 1),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the first Friday, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem ersten Freitag, 10-mal',
      );
    });
    test('RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.until, DateTime.utc(1997, 12, 24, 00, 00, 00));
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.friday, week: 1),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the first Friday, until Wednesday, December 24, 1997',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem ersten Freitag, bis zum Mittwoch, 24. Dezember 1997',
      );
    });

    test('RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.sunday, week: 1),
        ByDayRule(DateTime.sunday, week: -1),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every other month on the first & last Sunday, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Monate an dem ersten & letzten Sonntag, 10-mal',
      );
    });
    test('RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 6);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday, week: -2),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the second-to-last Monday, 6 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem vorletzten Montag, 6-mal',
      );
    });
    test('RRULE:FREQ=MONTHLY;BYMONTHDAY=-3', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;BYMONTHDAY=-3');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byMonthDay, [-3]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the third-to-last day',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem drittletzten Tag',
      );
    });

    test('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonthDay, [2, 15]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the second & 15th, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem zweiten & 15., 10-mal',
      );
    });

    test('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonthDay, [1, -1]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the first & last day, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem ersten & letzten Tag, 10-mal',
      );
    });
    test('RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
        () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.interval, 18);
      expect(ruleProp.rule.byMonthDay, [10, 11, 12, 13, 14, 15]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every 18 months on the 10th – 15th, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 18 Monate an dem 10. – 15., 10-mal',
      );
    });

    test('RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.tuesday)]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every other month on every Tuesday',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Monate an jedem Dienstag',
      );
    });

    test('RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonth, [DateTime.june, DateTime.july]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually in June & July, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich im Juni & Juli, 10-mal',
      );
    });

    test('RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 10);
      expect(
        ruleProp.rule.byMonth,
        [
          DateTime.january,
          DateTime.february,
          DateTime.march,
        ],
      );
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every other year in January – March, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle zwei Jahre im Januar – März, 10-mal',
      );
    });

    test('RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.interval, 3);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byYearDay, [1, 100, 200]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every 3 years on the first, 100th & 200th day of the year, 10 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 3 Jahre an dem ersten, 100. & 200. Tag des Jahres, 10-mal',
      );
    });

    test('RRULE:FREQ=YEARLY;BYDAY=20MO', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYDAY=20MO');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday, week: 20),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on the 20th Monday of the year',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich an dem 20. Montag des Jahres',
      );
    });

    test('RRULE:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeek, [20]);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday),
      ]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on Monday in the 20th week of the year',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich am Montag in der 20. Woche des Jahres',
      );
    });

    test('RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.thursday)]);
      expect(ruleProp.rule.byMonth, [DateTime.march]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on every Thursday in March',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich an jedem Donnerstag im März',
      );
    });

    test('RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.thursday)]);
      expect(
        ruleProp.rule.byMonth,
        [DateTime.june, DateTime.july, DateTime.august],
      );
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Annually on every Thursday in June – August',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Jährlich an jedem Donnerstag im Juni – August',
      );
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byMonthDay, [13]);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.friday)]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on every Friday that are also the 13th',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an jedem Freitag, der ebenfalls der 13. ist',
      );
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.saturday)]);
      expect(ruleProp.rule.byMonthDay, [7, 8, 9, 10, 11, 12, 13]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on every Saturday that are also the 7th – 13th',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an jedem Samstag, der ebenfalls der 7. – 13. ist',
      );
    });

    test(
        'RRULE:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8',
        () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.interval, 4);
      expect(ruleProp.rule.byMonth, [11]);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.tuesday)]);
      expect(ruleProp.rule.byMonthDay, [2, 3, 4, 5, 6, 7, 8]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every 4 years on every Tuesday that are also the second – 8th day of the month and that are also in November',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 4 Jahre an jedem Dienstag, der ebenfalls der 2. – 8. Tag des Monats ist und der ebenfalls im November ist',
      );
    });

    test('RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3', () {
      // The third instance into the month of one of Tuesday, Wednesday, or
      // Thursday, for the next 3 months:
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 3);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.wednesday),
        ByDayRule(DateTime.thursday),
      ]);
      expect(ruleProp.rule.bySetPos, [3]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the third instance of every Tuesday – Thursday, 3 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich in der dritten Instanz von jedem Dienstag – Donnerstag, 3-mal',
      );
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2', () {
      // The second-to-last weekday of the month:
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday),
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.wednesday),
        ByDayRule(DateTime.thursday),
        ByDayRule(DateTime.friday),
      ]);
      expect(ruleProp.rule.bySetPos, [-2]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the second-to-last instance of weekdays',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich in der vorletzten Instanz von Wochentag',
      );
    });
    test('RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z', () {
      final ruleProp = RecurrenceRuleProperty(
        'RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z',
      );
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.hourly);
      expect(ruleProp.rule.interval, 3);
      expect(ruleProp.rule.until, DateTime.utc(1997, 09, 02, 17, 00, 00));
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Every 3 hours, until Tuesday, September 2, 1997 5:00:00 PM',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 3 Stunden, bis zum Dienstag, 2. September 1997 17:00:00',
      );
    });

    test('RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.minutely);
      expect(ruleProp.rule.interval, 15);
      expect(ruleProp.rule.count, 6);
      expect(ruleProp.rule.toHumanReadableText(), 'Every 15 minutes, 6 times');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 15 Minuten, 6-mal',
      );
    });
    test('RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.minutely);
      expect(ruleProp.rule.count, 4);
      expect(ruleProp.rule.interval, 90);
      expect(ruleProp.rule.toHumanReadableText(), 'Every 90 minutes, 4 times');
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Alle 90 Minuten, 4-mal',
      );
    });
    test('RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40', () {
      // Every 20 minutes from 9:00 AM to 4:40 PM every day:
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.byHour, [9, 10, 11, 12, 13, 14, 15, 16]);
      expect(ruleProp.rule.byMinute, [0, 20, 40]);
      // TODO adapt test case when BYHOUR and BYMINUTE are supported
      expect(ruleProp.rule.toHumanReadableText(), 'Daily');
      expect(ruleProp.rule.toHumanReadableText(languageCode: 'de'), 'Täglich');
    });
    test('RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16', () {
      // Every 20 minutes from 9:00 AM to 4:40 PM every day:
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.minutely);
      expect(ruleProp.rule.interval, 20);
      expect(ruleProp.rule.byHour, [9, 10, 11, 12, 13, 14, 15, 16]);
    });
    test('RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 4);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.sunday),
      ]);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.monday);
    });
    test('RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 4);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.sunday),
      ]);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
    });
    test('RRULE:FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 5);
      expect(ruleProp.rule.byMonthDay, [15, 30]);
      expect(
        ruleProp.rule.toHumanReadableText(),
        'Monthly on the 15th & 30th, 5 times',
      );
      expect(
        ruleProp.rule.toHumanReadableText(languageCode: 'de'),
        'Monatlich an dem 15. & 30., 5-mal',
      );
    });

    // test('', () {
    //   final ruleProp = RecurrenceRuleProperty('');
    //   expect(ruleProp.name, 'RRULE');
    //   expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
    //   expect(ruleProp.rule.count, 10);
    //   expect(ruleProp.rule.interval, 18);
    //   expect(ruleProp.rule.byMonthDay, [10, 11, 12, 13, 14, 15]);
    // });
  });
  group('Invalid RRULE', () {
    test(
      'invalid RRULE:FREQ=UNKNOWN;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z',
      () {
        try {
          RecurrenceRuleProperty(
            'RRULE:FREQ=UNKNOWN;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z',
          );
        } on FormatException {
          // expected
        }
      },
    );

    test('invalid RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      try {
        RecurrenceRuleProperty(
          'RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z',
        );
        fail('Invalid RECUR rule without frequency should fail');
      } on FormatException {
        // expected
      }
    });
  });
}
