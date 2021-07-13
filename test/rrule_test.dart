import 'package:flutter_test/flutter_test.dart';

import 'package:enough_icalendar/enough_icalendar.dart';

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
      expect(ruleProp.rule.until, DateTime(1998, 04, 04, 07));
    });

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
      expect(ruleProp.rule.until, DateTime(1998, 04, 04, 07));
    });

    test('RRULE:FREQ=DAILY;COUNT=10', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=DAILY;COUNT=10');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.count, 10);
    });

    test('RRULE:FREQ=DAILY;UNTIL=19971224T000000Z', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=DAILY;UNTIL=19971224T000000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.until, DateTime(1997, 12, 24, 00, 00, 00));
    });

    test('RRULE:FREQ=DAILY;INTERVAL=2', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=DAILY;INTERVAL=2');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.interval, 2);
    });

    test('RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.interval, 10);
      expect(ruleProp.rule.count, 5);
    });

    test(
        'RRULE:FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.until, DateTime(2000, 01, 31, 14, 00, 00));
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
    });

    test('RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.until, DateTime(2000, 01, 31, 14, 00, 00));
      expect(ruleProp.rule.byMonth, [1]);
    });

    test('RRULE:FREQ=WEEKLY;COUNT=10', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;COUNT=10');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.count, 10);
    });

    test('RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.until, DateTime(1997, 12, 24, 00, 00, 00));
    });

    test('RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
    });
    test('RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.until, DateTime(1997, 10, 07, 00, 00, 00));
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
    });
    test('RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
    });
    test(
        'RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR',
        () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.until, DateTime(1997, 12, 24, 00, 00, 00));
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday),
        ByDayRule(DateTime.wednesday),
        ByDayRule(DateTime.friday),
      ]);
    });
    test('RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.weekly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 8);
      expect(ruleProp.rule.startOfWorkWeek, DateTime.sunday);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.tuesday),
        ByDayRule(DateTime.thursday),
      ]);
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
    });
    test('RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.until, DateTime(1997, 12, 24, 00, 00, 00));
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.friday, week: 1),
      ]);
    });

    test('RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.sunday, week: 1),
        ByDayRule(DateTime.sunday, week: -1),
      ]);
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
    });
    test('RRULE:FREQ=MONTHLY;BYMONTHDAY=-3', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;BYMONTHDAY=-3');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byMonthDay, [-3]);
    });

    test('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonthDay, [2, 15]);
    });

    test('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonthDay, [1, -1]);
    });
    test('RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
        () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.interval, 18);
      expect(ruleProp.rule.byMonthDay, [10, 11, 12, 13, 14, 15]);
    });

    test('RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.tuesday)]);
    });

    test('RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonth, [DateTime.june, DateTime.july]);
    });

    test('RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.interval, 2);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byMonth,
          [DateTime.january, DateTime.february, DateTime.march]);
    });

    test('RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.interval, 3);
      expect(ruleProp.rule.count, 10);
      expect(ruleProp.rule.byYearDay, [1, 100, 200]);
    });

    test('RRULE:FREQ=YEARLY;BYDAY=20MO', () {
      final ruleProp = RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYDAY=20MO');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [
        ByDayRule(DateTime.monday, week: 20),
      ]);
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
    });

    test('RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.thursday)]);
      expect(ruleProp.rule.byMonth, [DateTime.march]);
    });

    test('RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.yearly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.thursday)]);
      expect(ruleProp.rule.byMonth,
          [DateTime.june, DateTime.july, DateTime.august]);
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byMonthDay, [13]);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.friday)]);
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.monthly);
      expect(ruleProp.rule.byWeekDay, [ByDayRule(DateTime.saturday)]);
      expect(ruleProp.rule.byMonthDay, [7, 8, 9, 10, 11, 12, 13]);
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
    });

    test('RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3', () {
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
    });

    test('RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2');
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
    });
    test('RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.hourly);
      expect(ruleProp.rule.interval, 3);
      expect(ruleProp.rule.until, DateTime(1997, 09, 02, 17, 00, 00));
    });

    test('RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.minutely);
      expect(ruleProp.rule.interval, 15);
      expect(ruleProp.rule.count, 6);
    });
    test('RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4', () {
      final ruleProp =
          RecurrenceRuleProperty('RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.minutely);
      expect(ruleProp.rule.count, 4);
      expect(ruleProp.rule.interval, 90);
    });
    test('RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40', () {
      final ruleProp = RecurrenceRuleProperty(
          'RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40');
      expect(ruleProp.name, 'RRULE');
      expect(ruleProp.rule.frequency, RecurrenceFrequency.daily);
      expect(ruleProp.rule.byHour, [9, 10, 11, 12, 13, 14, 15, 16]);
      expect(ruleProp.rule.byMinute, [0, 20, 40]);
    });
    test('RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16', () {
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
            'RRULE:FREQ=UNKNOWN;BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
      } on FormatException {
        // expected
      }
    });

    test('invalid RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z', () {
      try {
        RecurrenceRuleProperty(
            'RRULE:BYDAY=1SU;BYMONTH=4;UNTIL=19980404T070000Z');
        fail('Invalid RECUR rule without frequency should fail');
      } on FormatException {
        // expected
      }
    });
  });
}
