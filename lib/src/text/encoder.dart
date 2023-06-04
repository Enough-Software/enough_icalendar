import 'dart:convert';

import 'package:collection/collection.dart';
import '../../enough_icalendar.dart';
import 'l10n/de.dart';

import 'l10n/l10n.dart';

/// Supported languages
enum SupportedLanguage { en, de }

/// Encodes recurrence rules to human readable text.
///
/// Compare [Recurrence.toHumanReadableText]
class RecurrenceRuleToTextEncoder extends Converter<Recurrence, String> {

  const RecurrenceRuleToTextEncoder(this.l10n);
  /// Retrieves the localozation for the specified supported [language]
  static RruleL10n getForLanguage(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.en:
        return RruleL10nEn.create();
      case SupportedLanguage.de:
        return RruleL10nDe.create();
    }
  }

  /// Retrieves the localozation for the specified [languageCode], when supported.
  ///
  /// By defaul the English localization is returned.
  static RruleL10n getForLanguageCode(String languageCode) {
    if (languageCode.startsWith('de')) {
      return RruleL10nDe.create();
    }
    return RruleL10nEn.create();
  }

  final RruleL10n l10n;

  @override
  String convert(Recurrence input, {DateTime? startDate}) {
    final frequencyIntervalString =
        l10n.frequencyInterval(input.frequency, input.interval);
    final output = StringBuffer();
    if (startDate != null &&
        input.frequency == RecurrenceFrequency.weekly &&
        !input.hasByLimiter) {
      output.write(l10n.weeklyOnWeekday(startDate, input.interval));
    } else {
      output.write(frequencyIntervalString);
    }
    if (input.frequency > RecurrenceFrequency.daily) {
      assert(
        !input.hasByLimiter,
        'Frequencies > daily with any `by`-parts are not supported yet in '
        'toText().',
      );
    } else {
      if (input.frequency == RecurrenceFrequency.daily) {
        _convertDaily(input, output);
      } else if (input.frequency == RecurrenceFrequency.weekly) {
        _convertWeekly(input, output);
      } else if (input.frequency == RecurrenceFrequency.monthly) {
        _convertMonthly(input, output);
      } else if (input.frequency == RecurrenceFrequency.yearly) {
        _convertYearly(input, output);
      } else {
        throw UnsupportedError('Unsupported frequency: ${input.frequency}');
      }
    }

    if (input.until != null) {
      output.write(l10n.until(input.until!,
          includeTime: input.frequency > RecurrenceFrequency.daily));
    } else if (input.count != null) {
      output.write(l10n.count(input.count!));
    }

    return output.toString();
  }

  void _convertDaily(Recurrence input, StringBuffer output) {
    //TODO: support BYHOUR and BYMINUTE modifier
    //  Every 20 minutes from 9:00 AM to 4:40 PM every day:

    //    DTSTART;TZID=America/New_York:19970902T090000
    //    RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40
    //    or
    //    RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16
    output
      // [in January – March, August & September]
      ..add(_formatByMonths(input))
      // [on the 1st & 2nd-to-last instance]
      ..add(_formatBySetPositions(input))
      // [byWeekDay]:
      //   [on (Monday, Wednesday – Friday & Sunday | weekdays [& Sunday])]
      // [byMonthDays]:
      //   [on the 1st and last day of the month]
      // byWeekDay, byMonthDays:
      //   on (Monday, Wednesday – Friday & Sunday | weekdays [& Sunday])
      //   that are also the 1st & 3rd-to-last – last day of the month
      ..add(_formatByWeekDays(
        input,
        variant:
            input.hasBySetPos ? InOnVariant.instanceOf : InOnVariant.simple,
      ))
      ..add(_formatByMonthDays(
        input,
        variant: input.hasByWeekDay
            ? InOnVariant.also
            : input.hasBySetPos
                ? InOnVariant.instanceOf
                : InOnVariant.simple,
        combination: input.hasByWeekDay
            ? ListCombination.disjunctive
            : ListCombination.conjunctiveShort,
      ));
  }

  void _convertWeekly(Recurrence input, StringBuffer output) {
    output
      // [in January – March, August & September]
      ..add(_formatByMonths(input))
      // [on the 1st & 2nd-to-last instance]
      ..add(_formatBySetPositions(input))
      // [byWeekDay]:
      //   [on (Monday, Wednesday – Friday & Sunday | a weekday [& Sunday])]
      ..add(_formatByWeekDays(
        input,
        variant:
            input.hasBySetPos ? InOnVariant.instanceOf : InOnVariant.simple,
      ));
  }

  void _convertMonthly(Recurrence input, StringBuffer output) {
    output
      // [in January – March, August & September]
      ..add(_formatByMonths(input))
      // [on the 1st & 2nd-to-last instance]
      ..add(_formatBySetPositions(input))
      // [byWeekDay]:
      //   [on (Monday, Wednesday – Friday & Sunday | weekdays [& Sunday])]
      // [byMonthDays]:
      //   [on the 1st and last day of the month]
      // byWeekDay, byMonthDays:
      //   on (Monday, Wednesday – Friday & Sunday | weekdays [& Sunday])
      //   that are also the 1st or 3rd-to-last – last day of the month
      ..add(_formatByWeekDays(
        input,
        frequency: DaysOfWeekFrequency.monthly,
        indicateFrequency: false,
        variant:
            input.hasBySetPos ? InOnVariant.instanceOf : InOnVariant.simple,
      ))
      ..add(_formatByMonthDays(
        input,
        daysOfVariant: (input.byWeekDay?.anyHasWeekNumber == true)
            ? DaysOfVariant.dayAndFrequency
            : input.byMonthDay?.any((d) => d < 0) ?? false
                ? DaysOfVariant.day
                : DaysOfVariant.simple,
        variant: input.hasByWeekDay
            ? InOnVariant.also
            : input.hasBySetPos
                ? InOnVariant.instanceOf
                : InOnVariant.simple,
        combination: input.hasByWeekDay
            ? ListCombination.disjunctive
            : ListCombination.conjunctiveShort,
      ));
  }

  void _convertYearly(Recurrence input, StringBuffer output) {
    output.add(_formatBySetPositions(input));

    // Order of remaining by-attributes:
    // byWeekDay, byMonthDays, byYearDay, byWeek, byMonth

    final firstVariant =
        input.hasBySetPos ? InOnVariant.instanceOf : InOnVariant.simple;

    final startWithByWeekDays = input.hasByWeekDay;
    if (startWithByWeekDays) {
      final frequency = input.hasByYearDay || input.hasByMonthDay
          ? DaysOfWeekFrequency.yearly
          : input.hasByMonth
              ? DaysOfWeekFrequency.monthly
              : DaysOfWeekFrequency.yearly;
      output.add(_formatByWeekDays(
        input,
        frequency: frequency,
        variant: firstVariant,
      ));
    }

    final startWithByMonthDays = input.hasByMonthDay && !startWithByWeekDays;
    if (startWithByMonthDays) {
      output.add(_formatByMonthDays(input, variant: firstVariant));
    }

    final startWithByYearDays =
        input.hasByYearDay && !startWithByWeekDays && !startWithByMonthDays;
    if (startWithByYearDays) {
      output.add(_formatByYearDays(input, variant: firstVariant));
    }

    final startWithByWeeks = input.hasByWeek &&
        !startWithByWeekDays &&
        !startWithByMonthDays &&
        !startWithByYearDays;
    if (startWithByWeeks) {
      output.add(_formatByWeeks(input, variant: firstVariant));
    }

    final startWithByMonths = input.hasByMonth &&
        !startWithByWeekDays &&
        !startWithByMonthDays &&
        !startWithByYearDays &&
        !startWithByWeeks;
    if (startWithByMonths) {
      output.add(_formatByMonths(input, variant: firstVariant));
    }

    final daysOnlyByWeek =
        input.hasByWeekDay && !input.hasByMonthDay && !input.hasByYearDay;
    final daysOnlyByMonth =
        !input.hasByWeekDay && input.hasByMonthDay && !input.hasByYearDay;

    final appendByWeeksDirectly = daysOnlyByWeek && input.hasByWeek;
    final appendByMonthsDirectly = (daysOnlyByWeek || daysOnlyByMonth) &&
        !input.hasByWeek &&
        input.hasByMonth;

    if (appendByWeeksDirectly) {
      output.add(_formatByWeeks(
        input,
        combination: ListCombination.conjunctiveShort,
      ));
    }
    if (appendByMonthsDirectly) {
      assert(!appendByWeeksDirectly);
      output.add(_formatByMonths(
        input,
        combination: ListCombination.conjunctiveShort,
      ));
    }

    final limits = [
      if (!startWithByMonthDays && input.hasByMonthDay)
        _formatByMonthDays(
          input,
          variant: InOnVariant.also,
          combination: ListCombination.disjunctive,
        ),
      if (!startWithByYearDays && input.hasByYearDay)
        _formatByYearDays(
          input,
          variant: InOnVariant.also,
          combination: ListCombination.disjunctive,
        ),
      if (!startWithByWeeks && !appendByWeeksDirectly && input.hasByWeek)
        _formatByWeeks(
          input,
          variant: InOnVariant.also,
          combination: ListCombination.disjunctive,
        ),
      if (!startWithByMonths && !appendByMonthsDirectly && input.hasByMonth)
        _formatByMonths(
          input,
          variant: InOnVariant.also,
          combination: ListCombination.disjunctive,
        ),
    ].whereNotNull().toList();
    if (limits.isNotEmpty) {
      output.add(l10n.list(limits, ListCombination.conjunctiveLong));
    }
  }

  String? _formatBySetPositions(Recurrence input) {
    if (!input.hasBySetPos) return null;

    return l10n.onInstances(input.bySetPos!.formattedForUser(l10n));
  }

  String? _formatByMonths(
    Recurrence input, {
    InOnVariant variant = InOnVariant.simple,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    if (!input.hasByMonth) return null;

    return l10n.inMonths(
      input.byMonth!.formattedForUser(
        l10n,
        map: l10n.month,
        combination: combination,
      ),
      variant: variant,
    );
  }

  String? _formatByWeeks(
    Recurrence input, {
    InOnVariant variant = InOnVariant.simple,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    if (!input.hasByWeek) return null;

    return l10n.inWeeks(
      input.byWeek!.formattedForUser(l10n, combination: combination),
      variant: variant,
    );
  }

  String? _formatByYearDays(
    Recurrence input, {
    InOnVariant variant = InOnVariant.simple,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    if (!input.hasByYearDay) return null;

    return l10n.onDaysOfYear(
      input.byYearDay!.formattedForUser(l10n, combination: combination),
      variant: variant,
    );
  }

  String? _formatByMonthDays(
    Recurrence input, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    if (!input.hasByMonthDay) return null;

    return l10n.onDaysOfMonth(
      input.byMonthDay!.formattedForUser(l10n, combination: combination),
      daysOfVariant: daysOfVariant,
      variant: variant,
    );
  }

  String? _formatByWeekDays(
    Recurrence input, {
    DaysOfWeekFrequency? frequency,
    bool? indicateFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    if (!input.hasByWeekDay) return null;

    var addEveryPrefix = frequency != null;
    if (frequency == DaysOfWeekFrequency.yearly &&
        input.hasByWeekDay &&
        !input.byWeekDay!.anyHasWeekNumber &&
        !input.hasByMonthDay &&
        !input.hasByYearDay &&
        input.hasByWeek &&
        input.byWeek!.length == 1 &&
        !input.hasByMonth) {
      addEveryPrefix = false;
    }

    return l10n.onDaysOfWeek(
      input.byWeekDay!.formattedForUser(
        l10n,
        addEveryPrefix: addEveryPrefix,
        weekStart: input.startOfWorkWeek,
      ),
      indicateFrequency: indicateFrequency ?? input.hasByWeekDayWithWeeks,
      frequency: frequency,
      variant: variant,
    );
  }
}

extension on StringBuffer {
  void add(Object? obj) {
    if (obj == null) return;

    final text = obj is String ? obj : obj.toString();
    if (!text.startsWith(',')) {
      write(' ');
    }
    write(text);
  }
}

typedef _ItemToString<T> = String Function(T item, {bool isSingleItem});

extension<T> on Iterable<T> {
  /// Creates a list with all items sorted by their key like
  /// `0, 1, 2, 3, …, -3, -2, -1`.
  List<T> sortedForUserGeneral({required int Function(T item) key}) {
    final nonNegative = where((e) => key(e) >= 0).sortedBy<num>(key);
    final negative = where((e) => key(e) < 0).sortedBy<num>(key);
    return nonNegative + negative;
  }
}

extension on Iterable<int> {
  String formattedForUser(
    RruleL10n l10n, {
    _ItemToString<int>? map,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    assert(isNotEmpty);

    final raw = sortedForUser();
    final mapped = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final startIndex = i;
      var current = raw[startIndex];
      while (raw.length > i + 1 && raw[i + 1] == current + 1) {
        i++;
        current = raw[i];
      }

      mapped._addIndividualOrCombined(
        l10n,
        raw,
        startIndex,
        i,
        map ?? l10n.ordinal,
      );
    }

    return l10n.list(mapped, combination);
  }

  List<int> sortedForUser() => sortedForUserGeneral(key: (e) => e);
}

extension on Iterable<ByDayRule> {
  String occurrenceFreeFormattedForUser(
    RruleL10n l10n, {
    required bool addEveryPrefix,
    required int weekStart,
    ListCombination combination = ListCombination.conjunctiveShort,
  }) {
    // With [addEveryPrefix]:
    //   every Monday
    //   weekdays & every Sunday
    //   weekdays, every Saturday & Sunday

    final raw = map((e) => e.weekday)
        .sortedBy<num>((it) => (it - DateTime.monday) % DateTime.daysPerWeek);

    final mapped = <String>[];

    final containsAllWeekdays = l10n.weekdays.every(raw.contains);
    final containsAllDays = containsAllWeekdays &&
        {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday
        }.every(raw.contains);
    if (containsAllDays) {
      return l10n.everydayString;
    } else if (containsAllWeekdays) {
      mapped.add(l10n.weekdaysString);
      raw.removeWhere((d) => l10n.weekdays.contains(d));
    }

    var addedEveryPrefix = false;
    for (var i = 0; i < raw.length; i++) {
      final startIndex = i;
      final startValue = raw[startIndex];

      var current = startValue;
      while (raw.length > i + 1 &&
          raw[i + 1] == (current + 1) % DateTime.daysPerWeek) {
        i++;
        current = raw[i];
      }

      mapped._addIndividualOrCombined<int>(
        l10n,
        raw,
        startIndex,
        i,
        (day, {isSingleItem = false}) {
          var string = l10n.dayOfWeek(day);
          if (addEveryPrefix && !addedEveryPrefix && day == startValue) {
            string = '${l10n.everyXDaysOfWeekPrefix}$string';
            addedEveryPrefix = true;
          }
          return string;
        },
      );
    }

    return l10n.list(mapped, combination);
  }

  String formattedForUser(
    RruleL10n l10n, {
    required bool addEveryPrefix,
    required int weekStart,
  }) {
    final grouped = groupBy<ByDayRule, int?>(this, (e) => e.week)
        .entries
        .sortedForUserGeneral(
            key: (it) =>
                it.value.first.hasWeekNumber ? it.value.first.week! : 0);

    if (anyHasWeekNumber && map((it) => it.weekday).toSet().length == 1) {
      // Simplify this special case:
      // All entries contain the same day of the week.

      return l10n.nthDaysOfWeek(
        grouped.map((it) => it.key!),
        l10n.dayOfWeek(first.weekday),
      );
    }

    final strings = grouped.map((entry) {
      final hasOccurrence = entry.key != null;
      final daysOfWeek = entry.value
          .map((it) => ByDayRule(it.weekday))
          .occurrenceFreeFormattedForUser(
            l10n,
            addEveryPrefix: addEveryPrefix && !hasOccurrence,
            weekStart: weekStart,
            combination: ListCombination.conjunctiveShort,
          );
      return hasOccurrence
          ? l10n.nthDaysOfWeek(hasOccurrence ? [entry.key!] : [], daysOfWeek)
          : daysOfWeek;
    }).toList();

    // If no inner (short) conjunction is used, we can simply use the short
    // variant instead of the long one.
    final atMostOneWeekDayPerOccurrence = every((entry) => where((e) => e.week == entry.week).length == 1);

    return l10n.list(
      strings,
      atMostOneWeekDayPerOccurrence
          ? ListCombination.conjunctiveShort
          : ListCombination.conjunctiveLong,
    );
  }
}

extension on List<String> {
  void _addIndividualOrCombined<T>(
    RruleL10n l10n,
    List<T> source,
    int startIndex,
    int endIndex,
    _ItemToString<T> map,
  ) {
    assert(startIndex <= endIndex);

    switch (endIndex - startIndex) {
      case 0:
        add(map(source[startIndex], isSingleItem: true));
        return;
      case 1:
        add(map(source[startIndex], isSingleItem: true));
        add(map(source[endIndex], isSingleItem: true));
        return;
      default:
        add(l10n.range(map(source[startIndex], isSingleItem: false),
            map(source[endIndex], isSingleItem: false)));
        return;
    }
  }
}
