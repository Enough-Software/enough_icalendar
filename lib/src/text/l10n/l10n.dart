import 'package:intl/intl.dart';

import '../../types.dart';
import 'en.dart';

export 'en.dart';

/// Contains localized strings used by `RecurrenceRule.toText`.
///
/// Currently, only English is supported: [RruleL10nEn].
abstract class RruleL10n {
  /// Creates a new localization instance.
  const RruleL10n();

  /// The locale code used for localized formatting, e.g. `en_US`.
  String get locale;

  /// Formats the result of the given [formatter] using this locale.
  String formatWithIntl(String Function() formatter) =>
      Intl.withLocale(locale, formatter) as String;

  /// Formats the given [frequency] and [interval].
  String frequencyInterval(RecurrenceFrequency frequency, int interval);

  /// Formats a weekly occurrence on the weekday of the given [startDate].
  String weeklyOnWeekday(DateTime startDate, int interval);

  /// Formats the `UNTIL` part.
  String until(DateTime until, {bool includeTime = false});

  /// Formats the `COUNT` part.
  String count(int count);

  /// Formats a range between the given [start] and [end].
  String range(String start, String end) => '$start – $end';

  /// Formats the given [instances].
  String onInstances(String instances);

  /// Formats the given [months].
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple});

  /// Formats the name of the given [month].
  String month(int month, {bool isSingleItem = false}) =>
      formatWithIntl(() => DateFormat().dateSymbols.MONTHS[month - 1]);

  /// Formats the given [weeks].
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple});

  /// The weekdays that are considered part of the typical work week.
  Set<int> get weekdays => {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  /// Formats the given days of week.
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  });

  /// The localized string for an every-day occurrence.
  String get everydayString;

  /// The localized string for a weekday occurrence.
  String get weekdaysString;

  /// The localized prefix for an every-X-days-of-week occurrence.
  String get everyXDaysOfWeekPrefix;

  /// Formats the name of the given [dayOfWeek].
  String dayOfWeek(int dayOfWeek) =>
      formatWithIntl(() => DateFormat().dateSymbols.WEEKDAYS[dayOfWeek % 7]);

  /// Formats the given [occurrences] on the given [daysOfWeek].
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek);

  /// Formats the given days of month.
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  });

  /// Formats the given days of year.
  String onDaysOfYear(String days, {InOnVariant variant = InOnVariant.simple});

  /// Formats a list of [items] with the given [combination].
  String list(List<String> items, ListCombination combination);

  /// Generates a formatted list from items similar to the
  /// Unicode CLDR list formatting proposal.
  static String defaultList(
    List<String> items, {
    required String two,
    required String end,
    String start = ', ',
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
        final output = StringBuffer(items.first)
          ..write(start)
          ..write(items[1]);

        for (final entry in items.sublist(2, items.length - 1)) {
          output
            ..write(middle)
            ..write(entry);
        }

        output
          ..write(end)
          ..write(items.last);
        return output.toString();
    }
  }

  /// Formats the ordinal of the given [number].
  String ordinal(int number, {bool isSingleItem = true});
}

/// Variants for expressing whether something happens `in` or `on` a time span.
enum InOnVariant {
  /// Simple phrasing.
  simple,

  /// Also phrasing.
  also,

  /// Instance-of phrasing.
  instanceOf,
}

/// Frequency used when formatting days of week.
enum DaysOfWeekFrequency {
  /// Monthly frequency.
  monthly,

  /// Yearly frequency.
  yearly,
}

/// Variants for how days are represented.
enum DaysOfVariant {
  /// Simple day representation.
  simple,

  /// Day representation.
  day,

  /// Day and frequency representation.
  dayAndFrequency,
}

/// How a list of items should be combined.
enum ListCombination {
  /// Short conjunctive combination, e.g. `a, b & c`.
  conjunctiveShort,

  /// Long conjunctive combination, e.g. `a, b and c`.
  conjunctiveLong,

  /// Disjunctive combination, e.g. `a, b or c`.
  disjunctive,
}
