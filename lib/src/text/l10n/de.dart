import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../types.dart';
import 'l10n.dart';

class RruleL10nDe extends RruleL10n {
  const RruleL10nDe._();

  static RruleL10nDe create() {
    initializeDateFormatting('de');
    return RruleL10nDe._();
  }

  @override
  String get locale => 'de_DE';

  @override
  String frequencyInterval(RecurrenceFrequency frequency, int interval) {
    String plurals({required String one, required String plural}) {
      switch (interval) {
        case 1:
          return one;
        case 2:
          return 'Alle zwei $plural';
        default:
          return 'Alle $interval ${plural}';
      }
    }

    switch (frequency) {
      case RecurrenceFrequency.secondly:
        return plurals(one: 'Sekündlich', plural: 'Sekunden');
      case RecurrenceFrequency.minutely:
        return plurals(one: 'Minütlich', plural: 'Minuten');
      case RecurrenceFrequency.hourly:
        return plurals(one: 'Stündlich', plural: 'Stunden');
      case RecurrenceFrequency.daily:
        return plurals(one: 'Täglich', plural: 'Tage');
      case RecurrenceFrequency.weekly:
        return plurals(one: 'Wöchentlich', plural: 'Wochen');
      case RecurrenceFrequency.monthly:
        return plurals(one: 'Monatlich', plural: 'Monate');
      case RecurrenceFrequency.yearly:
        return plurals(one: 'Jährlich', plural: 'Jahre');
    }
  }

  @override
  String weeklyOnWeekday(DateTime startDate, int interval) {
    String plurals({required String one, required String singular}) {
      switch (interval) {
        case 1:
          return one;
        case 2:
          return 'Jeden zweiten $singular';
        default:
          return 'Jeden ${ordinal(interval)} ${singular}';
      }
    }

    final weekdayName =
        formatWithIntl(() => DateFormat.EEEE().format(startDate));
    return plurals(one: 'Jeden $weekdayName', singular: weekdayName);
  }

  @override
  String until(DateTime until, {bool includeTime = false}) =>
      ', bis zum ${formatWithIntl(() => includeTime ? DateFormat.yMMMMEEEEd().add_jms().format(until) : DateFormat.yMMMMEEEEd().format(until))}';

  @override
  String count(int count) {
    switch (count) {
      case 1:
        return ', einmal';
      case 2:
        return ', zweimal';
      case 2:
        return ', dreimal';
      default:
        return ', $count-mal';
    }
  }

  @override
  String onInstances(String instances) => 'in der $instances Instanz';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) {
    switch (variant) {
      case InOnVariant.simple:
        return 'im $months';
      case InOnVariant.also:
        return 'der ebenfalls im $months ist';
      case InOnVariant.instanceOf:
        return 'im $months';
    }
  }

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) =>
      '${_inVariant(variant, useDativ: false)} der $weeks Woche des Jahres';

  String _inVariant(InOnVariant variant, {bool useDativ = true}) {
    switch (variant) {
      case InOnVariant.simple:
        return useDativ ? 'im' : 'in';
      case InOnVariant.also:
        return 'die ebenfalls';
      case InOnVariant.instanceOf:
        return 'von';
    }
  }

  @override
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  }) {
    // print(
    //     'onDaysOfWeek: days=$days, indicateFreq=$indicateFrequency, freq=$frequency');
    assert(variant != InOnVariant.also);

    final frequencyString =
        frequency == DaysOfWeekFrequency.monthly ? 'Monats' : 'Jahres';
    final suffix = indicateFrequency ? ' des ${frequencyString}' : '';
    return '${_onVariant(variant, useDativ: !days.contains('em '))} $days$suffix';
  }

  @override
  String get weekdaysString => 'Wochentag';

  @override
  String get everydayString => 'jedem Tag';

  @override
  String get everyXDaysOfWeekPrefix => 'jedem ';
  @override
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek) {
    if (occurrences.isEmpty) return daysOfWeek;

    final ordinals = list(
      occurrences.map(ordinal).toList(),
      ListCombination.conjunctiveShort,
    );
    return 'dem $ordinals $daysOfWeek';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    print('onDaysOfMonth days=$days, variant=$variant');
    final suffix = {
      DaysOfVariant.simple: '',
      DaysOfVariant.day: ' Tag',
      DaysOfVariant.dayAndFrequency: ' Tag des Monats',
    }[daysOfVariant];
    switch (variant) {
      case InOnVariant.simple:
        return 'an dem $days$suffix';
      case InOnVariant.also:
        return ', der ebenfalls der $days$suffix ist';
      case InOnVariant.instanceOf:
        return 'von dem $days$suffix';
    }
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) =>
      '${_onVariant(variant)} dem $days Tag des Jahres';

  String _onVariant(InOnVariant variant, {bool useDativ = false}) {
    switch (variant) {
      case InOnVariant.simple:
        return useDativ ? 'am' : 'an';
      case InOnVariant.also:
        return 'die ebenfalls';
      case InOnVariant.instanceOf:
        return 'von';
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
        two = ' und ';
        end = ', und ';
        break;
      case ListCombination.disjunctive:
        two = ' oder ';
        end = ', oder ';
        break;
    }
    return RruleL10n.defaultList(items, two: two, end: end);
  }

  @override
  String ordinal(int number, {bool isSingleItem = true}) {
    assert(number != 0);
    if (number == -1) return 'letzten';
    if (number == -2) return 'vorletzten';
    if (number == -3) return 'drittletzten';

    final n = number.abs();
    String string;
    if (n % 10 == 1 && n % 100 != 11) {
      if (n == 1 && isSingleItem) {
        string = 'ersten';
      } else {
        string = '${n}.';
      }
    } else if (n % 10 == 2 && n % 100 != 12) {
      if (n == 2 && isSingleItem) {
        string = 'zweiten';
      } else {
        string = '${n}.';
      }
    } else if (n % 10 == 3 && n % 100 != 13) {
      if (n == 3 && isSingleItem) {
        string = 'dritten';
      } else {
        string = '${n}.';
      }
    } else {
      string = '${n}.';
    }

    return number < 0 ? '$string-letzten' : string;
  }
}
