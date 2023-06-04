import 'package:intl/intl.dart';

import '../../types.dart';
import 'en.dart';

export 'en.dart';

/// Contains localized strings used by [RecurrenceRule.toText].
///
/// Currently, only English is supported: [RruleL10nEn].
abstract class RruleL10n {
  const RruleL10n();

  String get locale;
  String formatWithIntl(String Function() formatter) =>
      Intl.withLocale(locale, formatter) as String;

  String frequencyInterval(RecurrenceFrequency frequency, int interval);
  String weeklyOnWeekday(DateTime startDate, int interval);

  String until(DateTime until, {bool includeTime = false});
  String count(int count);
  String range(String start, String end) => '$start – $end';

  String onInstances(String instances);

  String inMonths(String months, {InOnVariant variant = InOnVariant.simple});
  String month(int month, {bool isSingleItem = false}) =>
      formatWithIntl(() => DateFormat().dateSymbols.MONTHS[month - 1]);

  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple});

  Set<int> get weekdays => {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      };
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  });
  String get everydayString;
  String get weekdaysString;
  String get everyXDaysOfWeekPrefix;
  String dayOfWeek(int dayOfWeek) => formatWithIntl(
      () => DateFormat().dateSymbols.WEEKDAYS[dayOfWeek % 7],
    );

  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek);

  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  });

  String onDaysOfYear(String days, {InOnVariant variant = InOnVariant.simple});

  String list(List<String> items, ListCombination combination);

  /// Generates a formatted list from items similar to the
  /// [Unicode-Proposal](http://cldr.unicode.org/development/development-process/design-proposals/list-formatting).
  static String defaultList(
    List<String> items, {
    required String two,
    required String end, String start = ', ',
    String middle = ', ',
  }) {
    switch (items.length) {
      case 0:
        throw ArgumentError('items must not be empty.');
      case 1:
        return items.first;
      case 2:
        return '${items.first}$two${items[1]}';
      default:
        final output = StringBuffer(items.first);
        output..write(start)..write(items[1]);

        for (final entry in items.sublist(2, items.length - 1)) {
          output..write(middle)..write(entry);
        }

        output..write(end)..write(items.last);
        return output.toString();
    }
  }

  String ordinal(int number, {bool isSingleItem = true});
}

enum InOnVariant { simple, also, instanceOf }

enum DaysOfWeekFrequency { monthly, yearly }

enum DaysOfVariant { simple, day, dayAndFrequency }

enum ListCombination { conjunctiveShort, conjunctiveLong, disjunctive }
