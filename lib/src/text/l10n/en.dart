import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../types.dart';
import 'l10n.dart';

class RruleL10nEn extends RruleL10n {
  const RruleL10nEn._();

  static RruleL10nEn create() {
    initializeDateFormatting('en');
    return RruleL10nEn._();
  }

  @override
  String get locale => 'en_US';

  @override
  String frequencyInterval(RecurrenceFrequency frequency, int interval) {
    String plurals({required String one, required String singular}) {
      switch (interval) {
        case 1:
          return one;
        case 2:
          return 'Every other $singular';
        default:
          return 'Every $interval ${singular}s';
      }
    }

    switch (frequency) {
      case RecurrenceFrequency.secondly:
        return plurals(one: 'Secondly', singular: 'second');

      case RecurrenceFrequency.minutely:
        return plurals(one: 'Minutely', singular: 'minute');
      case RecurrenceFrequency.hourly:
        return plurals(one: 'Hourly', singular: 'hour');
      case RecurrenceFrequency.daily:
        return plurals(one: 'Daily', singular: 'day');
      case RecurrenceFrequency.weekly:
        return plurals(one: 'Weekly', singular: 'week');
      case RecurrenceFrequency.monthly:
        return plurals(one: 'Monthly', singular: 'month');
      case RecurrenceFrequency.yearly:
        return plurals(one: 'Annually', singular: 'year');
    }
  }

  @override
  String weeklyOnWeekday(DateTime startDate, int interval) {
    String plurals({required String one, required String singular}) {
      switch (interval) {
        case 1:
          return one;
        case 2:
          return 'Every other $singular';
        default:
          return 'Every ${ordinal(interval)} ${singular}';
      }
    }

    final weekdayName =
        formatWithIntl(() => DateFormat.EEEE().format(startDate));
    return plurals(one: 'Every $weekdayName', singular: weekdayName);
  }

  @override
  String until(DateTime until, {bool includeTime = false}) =>
      ', until ${formatWithIntl(() => includeTime ? DateFormat.yMMMMEEEEd().add_jms().format(until) : DateFormat.yMMMMEEEEd().format(until))}';

  @override
  String count(int count) {
    switch (count) {
      case 1:
        return ', once';
      case 2:
        return ', twice';
      default:
        return ', $count times';
    }
  }

  @override
  String onInstances(String instances) => 'on the $instances instance';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) =>
      '${_inVariant(variant)} $months';

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) =>
      '${_inVariant(variant)} the $weeks week of the year';

  String _inVariant(InOnVariant variant) {
    switch (variant) {
      case InOnVariant.simple:
        return 'in';
      case InOnVariant.also:
        return 'that are also in';
      case InOnVariant.instanceOf:
        return 'of';
    }
  }

  @override
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  }) {
    assert(variant != InOnVariant.also);

    final frequencyString =
        frequency == DaysOfWeekFrequency.monthly ? 'month' : 'year';
    final suffix = indicateFrequency ? ' of the $frequencyString' : '';
    return '${_onVariant(variant)} $days$suffix';
  }

  @override
  String get weekdaysString => 'weekdays';

  @override
  String get everydayString => 'every day';

  @override
  String get everyXDaysOfWeekPrefix => 'every ';
  @override
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek) {
    if (occurrences.isEmpty) return daysOfWeek;

    final ordinals = list(
      occurrences.map(ordinal).toList(),
      ListCombination.conjunctiveShort,
    );
    return 'the $ordinals $daysOfWeek';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    final suffix = {
      DaysOfVariant.simple: '',
      DaysOfVariant.day: ' day',
      DaysOfVariant.dayAndFrequency: ' day of the month',
    }[daysOfVariant];
    return '${_onVariant(variant)} the $days$suffix';
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) =>
      '${_onVariant(variant)} the $days day of the year';

  String _onVariant(InOnVariant variant) {
    switch (variant) {
      case InOnVariant.simple:
        return 'on';
      case InOnVariant.also:
        return 'that are also';
      case InOnVariant.instanceOf:
        return 'of';
    }
  }

  @override
  String list(List<String> items, ListCombination combination) {
    String two;
    String end;
    switch (combination) {
      case ListCombination.conjunctiveShort:
        two = ' & ';
        end = ' & ';
        break;
      case ListCombination.conjunctiveLong:
        two = ' and ';
        end = ', and ';
        break;
      case ListCombination.disjunctive:
        two = ' or ';
        end = ', or ';
        break;
    }
    return RruleL10n.defaultList(items, two: two, end: end);
  }

  @override
  String ordinal(int number, {bool isSingleItem = true}) {
    assert(number != 0);
    if (number == -1) return 'last';

    final n = number.abs();
    String string;
    if (n % 10 == 1 && n % 100 != 11) {
      if (n == 1) {
        string = 'first';
      } else {
        string = '${n}st';
      }
    } else if (n % 10 == 2 && n % 100 != 12) {
      if (n == 2) {
        string = 'second';
      } else {
        string = '${n}nd';
      }
    } else if (n % 10 == 3 && n % 100 != 13) {
      if (n == 3) {
        string = 'third';
      } else {
        string = '${n}rd';
      }
    } else {
      string = '${n}th';
    }

    return number < 0 ? '$string-to-last' : string;
  }
}
