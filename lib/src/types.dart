/// To explicitly specify the value type format for a property value.
enum ValueType {
  binary,
  boolean,
  calendarAddress,
  date,
  dateTime,
  duration,
  float,
  integer,
  period,
  periodList,
  recurrence,
  text,
  time,
  uri,
  utcOffset,
  other,

  typeClassification,
  typeUriList,
  typeDateTimeList,
  typeFreeBusy,
  typeParticipantStatus,
  typeRange,
  typeAlarmTriggerRelationship,
  typeRelationship,
  typeRole,
  typeValue,
}

extension ExtensionValueType on ValueType {
  String? get name {
    switch (this) {
      case ValueType.binary:
        return 'BINARY';
      case ValueType.boolean:
        return 'BOOLEAN';
      case ValueType.calendarAddress:
        return 'CAL-ADDRESS';
      case ValueType.date:
        return 'DATE';
      case ValueType.dateTime:
        return 'DATE-TIME';
      case ValueType.duration:
        return 'DURATION';
      case ValueType.float:
        return 'FLOAT';
      case ValueType.integer:
        return 'INTEGER';
      case ValueType.period:
        return 'PERIOD';
      case ValueType.recurrence:
        return 'RECUR';
      case ValueType.text:
        return 'TEXT';
      case ValueType.time:
        return 'TIME';
      case ValueType.uri:
        return 'URI';
      case ValueType.utcOffset:
        return 'UTC-OFFSET';
      case ValueType.other:
      case ValueType.typeFreeBusy:
      case ValueType.periodList:
      case ValueType.typeDateTimeList:
      case ValueType.typeParticipantStatus:
      case ValueType.typeRange:
      case ValueType.typeAlarmTriggerRelationship:
      case ValueType.typeRelationship:
      case ValueType.typeRole:
      case ValueType.typeUriList:
      case ValueType.typeValue:
      case ValueType.typeClassification:
        return null;
    }
  }
}

enum Classification { public, private, confidential, other }

extension ExtensionClassificationValue on Classification {
  String? get name {
    switch (this) {
      case Classification.public:
        return 'PUBLIC';
      case Classification.private:
        return 'PRIVATE';
      case Classification.confidential:
        return 'CONFIDENTIAL';
      case Classification.other:
        return null;
    }
  }
}

/// `FREQ` part of a recurrence role
///
/// Compare [Recurrence]
enum RecurrenceFrequency {
  secondly,
  minutely,
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
}

extension ExtensionRecurrenceFrequency on RecurrenceFrequency {
  String get name {
    switch (this) {
      case RecurrenceFrequency.secondly:
        return 'SECONDLY';
      case RecurrenceFrequency.minutely:
        return 'MINUTELY';
      case RecurrenceFrequency.hourly:
        return 'HOURLY';
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }
}

/// This value type is used to identify properties that contain a recurrence rule specification.
class Recurrence {
  /// The `FREQ` rule part identifies the type of recurrence rule.
  ///
  /// This rule part MUST be specified in the recurrence rule.  Valid values
  /// include SECONDLY, to specify repeating events based on an interval
  /// of a second or more; MINUTELY, to specify repeating events based
  /// on an interval of a minute or more; HOURLY, to specify repeating
  /// events based on an interval of an hour or more; DAILY, to specify
  /// repeating events based on an interval of a day or more; WEEKLY, to
  /// specify repeating events based on an interval of a week or more;
  /// MONTHLY, to specify repeating events based on an interval of a
  /// month or more; and YEARLY, to specify repeating events based on an
  /// interval of a year or more.
  final RecurrenceFrequency frequency;

  /// The `UNTIL` rule part defines a DATE or DATE-TIME value that bounds the recurrence rule in an inclusive manner.
  ///
  ///   If the value
  /// specified by UNTIL is synchronized with the specified recurrence,
  /// this DATE or DATE-TIME becomes the last instance of the
  /// recurrence.  The value of the UNTIL rule part MUST have the same
  /// value type as the "DTSTART" property.  Furthermore, if the
  /// "DTSTART" property is specified as a date with local time, then
  /// the UNTIL rule part MUST also be specified as a date with local
  /// time.  If the "DTSTART" property is specified as a date with UTC
  /// time or a date with local time and time zone reference, then the
  /// UNTIL rule part MUST be specified as a date with UTC time.  In the
  /// case of the "STANDARD" and "DAYLIGHT" sub-components the UNTIL
  /// rule part MUST always be specified as a date with UTC time.  If
  /// specified as a DATE-TIME value, then it MUST be specified in a UTC
  /// time format.  If not present, and the COUNT rule part is also not
  /// present, the "RRULE" is considered to repeat forever.
  final DateTime? until;

  /// The `COUNT` rule part defines the number of occurrences at which to range-bound the recurrence.
  ///
  /// The "DTSTART" property value always counts as the first occurrence.
  final int? count;

  /// The `INTERVAL` rule part contains a positive integer representing at which intervals the recurrence rule repeats.
  ///
  /// The default value is
  /// "1", meaning every second for a SECONDLY rule, every minute for a
  /// MINUTELY rule, every hour for an HOURLY rule, every day for a
  /// DAILY rule, every week for a WEEKLY rule, every month for a
  /// MONTHLY rule, and every year for a YEARLY rule.  For example,
  /// within a DAILY rule, a value of "8" means every eight days.
  final int interval;

  /// Seconds modifier / limiter for this Recurrence.
  ///
  /// BYxxx rule parts modify the recurrence in some manner.
  /// BYxxx rule parts for a period of time which is the same or greater than the frequency generally reduce or limit the number
  /// of occurrences of the recurrence generated. For example, "FREQ=DAILY;BYMONTH=1" reduces the number of recurrence instances
  /// from all days (if BYMONTH tag is not present) to all days in January. BYxxx rule parts for a period of time less than the
  /// frequency generally increase or expand the number of occurrences of the recurrence. For example, "FREQ=YEARLY;BYMONTH=1,2"
  /// increases the number of days within the yearly recurrence set from 1 (if BYMONTH tag is not present) to 2.
  ///
  /// ```
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |          |SECONDLY|MINUTELY|HOURLY |DAILY  |WEEKLY|MONTHLY|YEARLY|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYMONTH   |Limit   |Limit   |Limit  |Limit  |Limit |Limit  |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYWEEKNO  |N/A     |N/A     |N/A    |N/A    |N/A   |N/A    |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYYEARDAY |Limit   |Limit   |Limit  |N/A    |N/A   |N/A    |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYMONTHDAY|Limit   |Limit   |Limit  |Limit  |N/A   |Expand |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYDAY     |Limit   |Limit   |Limit  |Limit  |Expand|Note 1 |Note 2|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYHOUR    |Limit   |Limit   |Limit  |Expand |Expand|Expand |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYMINUTE  |Limit   |Limit   |Expand |Expand |Expand|Expand |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYSECOND  |Limit   |Expand  |Expand |Expand |Expand|Expand |Expand|
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// |BYSETPOS  |Limit   |Limit   |Limit  |Limit  |Limit |Limit  |Limit |
  /// +----------+--------+--------+-------+-------+------+-------+------+
  /// ```
  ///
  /// Note 1:  Limit if BYMONTHDAY is present; otherwise, special expand
  ///          for MONTHLY.
  ///
  /// Note 2:  Limit if BYYEARDAY or BYMONTHDAY is present; otherwise,
  ///          special expand for WEEKLY if BYWEEKNO present; otherwise,
  ///          special expand for MONTHLY if BYMONTH present; otherwise,
  ///          special expand for YEARLY.
  ///
  /// Compare [byMinute]
  final List<int>? bySecond;

  /// `BYMINUTE` modifier / limiter for this Recurrence.
  ///
  /// Compare [bySecond] for details
  final List<int>? byMinute;

  /// `BYHOUR` modifier / limiter for this Recurrence.
  ///
  /// Compare [bySecond] for details
  final List<int>? byHour;

  /// `BYDAY` modifier / limiter for this Recurrence. 1 = Monday / DateTime.monday, 7 = Sunday / DateTime.sunday
  ///
  /// Compare [bySecond] for details
  final List<ByDayRule>? byWeekDay;

  /// `BYMONTHDAY` modifier / limiter for this Recurrence.
  final List<int>? byMonthDay;

  /// `BYYEARDAY` modifier / limiter for this Recurrence.
  final List<int>? byYearDay;

  /// `BYWEEKNO` modifier / limiter for this Recurrence.
  ///
  /// Compare [bySecond] for details
  final List<int>? byWeek;

  /// `BYMONTH` modifier / limiter for this Recurrence.
  ///
  /// Compare [bySecond] for details
  final List<int>? byMonth;

  /// BYSETPOS modifier / limiter for this Recurrence.
  ///
  /// The BYSETPOS rule part specifies a COMMA-separated list of values
  /// that corresponds to the nth occurrence within the set of
  /// recurrence instances specified by the rule.  BYSETPOS operates on
  /// a set of recurrence instances in one interval of the recurrence
  /// rule.  For example, in a WEEKLY rule, the interval would be one
  /// week A set of recurrence instances starts at the beginning of the
  /// interval defined by the FREQ rule part.  Valid values are 1 to 366
  /// or -366 to -1.  It MUST only be used in conjunction with another
  /// BYxxx rule part.  For example "the last work day of the month"
  /// could be represented as:
  ///
  /// `FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1`
  final List<int>? bySetPos;

  /// The `WKST` rule part specifies the day on which the workweek starts.
  ///
  /// Valid values are MO, TU, WE, TH, FR, SA, and SU.  This is
  /// significant when a WEEKLY "RRULE" has an interval greater than 1,
  /// and a BYDAY rule part is specified.  This is also significant when
  /// in a YEARLY "RRULE" when a BYWEEKNO rule part is specified.  The
  /// default value is MO.
  final int startOfWorkWeek;

  Recurrence(
    this.frequency, {
    this.until,
    this.count,
    this.interval = 1,
    this.bySecond,
    this.byMinute,
    this.byHour,
    this.byWeekDay,
    this.byYearDay,
    this.byWeek,
    this.byMonth,
    this.byMonthDay,
    this.startOfWorkWeek = DateTime.monday,
    this.bySetPos,
  });

  static String? _lastContent;
  static Map<String, String>? _lastResult;
  static Map<String, String> _split(String content) {
    if (content == _lastContent) {
      return _lastResult!;
    }
    final result = <String, String>{};
    final pairs = content.split(';');
    for (final pair in pairs) {
      final index = pair.indexOf('=');
      if (index != -1) {
        result[pair.substring(0, index)] = pair.substring(index + 1);
      } else {
        result[pair] = '';
      }
    }
    _lastResult = result;
    _lastContent = content;
    return result;
  }

  static RecurrenceFrequency _parseFrequency(String content) {
    final freq = _split(content)['FREQ'];
    if (freq == null) {
      throw FormatException('No FREQ found in RECUR $content');
    }
    switch (freq) {
      case 'SECONDLY':
        return RecurrenceFrequency.secondly;
      case 'MINUTELY':
        return RecurrenceFrequency.minutely;
      case 'HOURLY':
        return RecurrenceFrequency.hourly;
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
    }
    throw FormatException('Invalid FREQ value: $freq in RECUR $content');
  }

  static DateTime? _parseUntil(String content) {
    final until = _split(content)['UNTIL'];
    if (until == null) {
      return null;
    }
    if (until.contains('T')) {
      return DateParser.parseDateTime(until);
    }
    return DateParser.parseDate(until);
  }

  static int? _parseIntValue(String content, String fieldName) {
    final text = _split(content)[fieldName];
    if (text == null) {
      return null;
    }
    final value = int.tryParse(text);
    if (value == null) {
      throw FormatException('Invalid $fieldName $text in RECUR $content');
    }
    return value;
  }

  static int? _parseCount(String content) => _parseIntValue(content, 'COUNT');

  static int? _parseInterval(String content) =>
      _parseIntValue(content, 'INTERVAL');

  static List<String>? _parseStringList(String content, String fieldName) {
    final listText = _split(content)[fieldName];
    if (listText == null) {
      return null;
    }
    return listText.split(',');
  }

  static List<int>? _parseIntList(
      String content, String fieldName, int allowedMin, int allowedMax,
      [int? disallowedValue]) {
    final texts = _parseStringList(content, fieldName);
    if (texts == null) {
      return null;
    }
    final result = <int>[];
    for (final text in texts) {
      final value = int.tryParse(text);
      if (value == null ||
          value < allowedMin ||
          value > allowedMax ||
          value == disallowedValue) {
        throw FormatException(
            'Invalid $fieldName: part $text invalid in RECUR $content');
      }
      result.add(value);
    }
    if (result.isEmpty) {
      throw FormatException('Invalid $fieldName: empty in RECUR $content');
    }
    return result;
  }

  static List<int>? _parseBySecond(String content) =>
      _parseIntList(content, 'BYSECOND', 0, 60);

  static List<int>? _parseByMinute(String content) =>
      _parseIntList(content, 'BYMINUTE', 0, 59);
  static List<int>? _parseByHour(String content) =>
      _parseIntList(content, 'BYHOUR', 0, 23);

  static final _weekdaysByName = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  static List<ByDayRule>? _parseByWeekDay(String content) {
    final texts = _parseStringList(content, 'BYDAY');
    if (texts == null) {
      return null;
    }
    final result = <ByDayRule>[];
    for (final text in texts) {
      final weekday = _weekdaysByName[text];
      if (weekday != null) {
        result.add(ByDayRule(weekday));
      } else {
        // this is a more complex value with a week definition at the beginning:
        // Definition:
        // weekdaynum  = [[plus / minus] ordwk] weekday
        // plus        = "+"
        // minus       = "-"
        // ordwk       = 1*2DIGIT       ;1 to 53
        // weekday     = "SU" / "MO" / "TU" / "WE" / "TH" / "FR" / "SA"
        final weekText = text.substring(0, text.length - 2);
        final week = int.tryParse(weekText);
        if (week == null || week == 0 || week > 53 || week < -53) {
          throw FormatException(
              'Invalid week $weekText in BYDAY rule part $text in RECUR $content');
        }
        final dayText = text.substring(text.length - 2);
        final day = _weekdaysByName[dayText];
        if (day == null) {
          throw FormatException(
              'Invalid weekday $dayText in BYDAY rule part $text in RECUR $content');
        }
        result.add(ByDayRule(day, week: week));
      }
    }
    return result;
  }

  static List<int>? _parseByMonthDay(String content) =>
      _parseIntList(content, 'BYMONTHDAY', -31, 31, 0);

  static List<int>? _parseByYearDay(String content) =>
      _parseIntList(content, 'BYYEARDAY', -366, 366, 0);

  static List<int>? _parseByWeek(String content) =>
      _parseIntList(content, 'BYWEEKNO', -53, 53, 0);

  static List<int>? _parseByMonth(String content) =>
      _parseIntList(content, 'BYMONTH', 1, 12);

  static List<int>? _parseBySetPos(String content) =>
      _parseIntList(content, 'BYSETPOS', -366, 366, 0);

  static int? _parseWorkWeekStart(String content) {
    final startOfWorkWeekText = _split(content)['WKST'];
    if (startOfWorkWeekText == null) {
      return null;
    }
    final weekday = _weekdaysByName[startOfWorkWeekText];
    if (weekday == null) {
      throw FormatException(
          'Invalid weekday $startOfWorkWeekText in WKST part of RECUR $content');
    }
    return weekday;
  }

  static Recurrence parse(String content) {
    final frequency = _parseFrequency(content);
    final until = _parseUntil(content);
    final count = _parseCount(content);
    final interval = _parseInterval(content) ?? 1;
    final bySecond = _parseBySecond(content);
    final byMinute = _parseByMinute(content);
    final byHour = _parseByHour(content);
    final byWeekDay = _parseByWeekDay(content);
    final byMonthDay = _parseByMonthDay(content);
    final byYearDay = _parseByYearDay(content);
    final byWeek = _parseByWeek(content);
    final byMonth = _parseByMonth(content);
    final bySetPos = _parseBySetPos(content);
    final startOfWorkWeek = _parseWorkWeekStart(content) ?? DateTime.monday;
    return Recurrence(frequency,
        until: until,
        count: count,
        interval: interval,
        bySecond: bySecond,
        byMinute: byMinute,
        byHour: byHour,
        byWeekDay: byWeekDay,
        byMonthDay: byMonthDay,
        byYearDay: byYearDay,
        byWeek: byWeek,
        byMonth: byMonth,
        bySetPos: bySetPos,
        startOfWorkWeek: startOfWorkWeek);
  }
}

/// Contains BYDAY weekday rules
class ByDayRule {
  /// Weekday 1 = Monday / DateTime.monday, 7 = Sunday / DateTime.sunday
  final int weekday;

  /// The week, e.g. 1 for first week, 2 for the second week, -1 for the last week, -2 for the second last week, etc
  ///
  /// This value is relative to the DTSTART / DateTimeStart property
  final int? week;

  ByDayRule(this.weekday, {this.week});

  @override
  int get hashCode => weekday + (week ?? 0) * 10;

  @override
  bool operator ==(Object other) {
    return other is ByDayRule && other.weekday == weekday && other.week == week;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    switch (weekday) {
      case DateTime.monday:
        buffer.write('Monday');
        break;
      case DateTime.tuesday:
        buffer.write('Tuesday');
        break;
      case DateTime.wednesday:
        buffer.write('Wednesday');
        break;
      case DateTime.thursday:
        buffer.write('Thursday');
        break;
      case DateTime.friday:
        buffer.write('Friday');
        break;
      case DateTime.saturday:
        buffer.write('Saturday');
        break;
      case DateTime.sunday:
        buffer.write('Sunday');
        break;
      default:
        buffer..write('Invalid day ')..write(weekday);
        break;
    }
    if (week != null) {
      buffer..write(' in week ')..write(week);
    }
    return buffer.toString();
  }
}

class TimeOfDayWithSeconds {
  final int hour;
  final int minute;
  final int second;

  TimeOfDayWithSeconds(
      {required this.hour, required this.minute, required this.second});

  static TimeOfDayWithSeconds parse(String content) {
    final hour = int.tryParse(content.substring(0, 2));
    final minute = int.tryParse(content.substring(2, 4));
    final second = int.tryParse(content.substring(4, 6));
    if (hour == null || minute == null || second == null) {
      throw FormatException('Invalid time definition: $content');
    }
    return TimeOfDayWithSeconds(hour: hour, minute: minute, second: second);
  }
}

/// This value type is used to identify properties that contain an offset from UTC to local time.
class UtcOffset {
  final int offsetHour;
  final int offsetMinute;

  UtcOffset(String content)
      : offsetHour = _parseHour(content),
        offsetMinute = _parseMinute(content);

  UtcOffset.value({required this.offsetHour, required this.offsetMinute});

  @override
  String toString() {
    final buffer = StringBuffer();
    if (offsetHour < 0) {
      buffer.write('-');
    }
    final hour = offsetHour.abs();
    if (hour < 10) {
      buffer.write('0');
    }
    buffer.write(hour);
    if (offsetMinute < 10) {
      buffer.write('0');
    }
    buffer.write(offsetMinute);
    return buffer.toString();
  }

  @override
  int get hashCode => offsetHour + (offsetMinute * 60);

  @override
  bool operator ==(Object other) {
    return other is UtcOffset &&
        other.offsetHour == offsetHour &&
        other.offsetMinute == offsetMinute;
  }

  static int _parseHour(String content) {
    if (content.length < 5) {
      throw FormatException('Invalid UTC-OFFSET $content');
    }
    final hourText = content.substring(0, 3);
    final hour = int.tryParse(hourText);
    if (hour == null) {
      throw FormatException('Invalid UTC-OFFSET $content');
    }
    return hour;
  }

  static int _parseMinute(String content) {
    if (content.length < 5) {
      throw FormatException('Invalid UTC-OFFSET $content');
    }
    final minuteText =
        content.length > 5 ? content.substring(3, 5) : content.substring(3);
    final minute = int.tryParse(minuteText);
    if (minute == null) {
      throw FormatException('Invalid UTC-OFFSET $content');
    }
    return minute;
  }
}

class DateParser {
  DateParser._();

  static DateTime parseDate(String content) {
    if (content.length != 4 + 2 + 2) {
      throw FormatException('Invalid date definition: $content');
    }
    final year = int.tryParse(content.substring(0, 4));
    final month = int.tryParse(content.substring(4, 6));
    final day = int.tryParse(content.substring(6));
    if (year == null || month == null || day == null) {
      throw FormatException('Invalid date definition: $content');
    }
    return DateTime(year, month, day);
  }

  static DateTime parseDateTime(String content) {
    final tIndex = content.indexOf('T');
    if (content.length < 4 + 2 + 2 + 1 + 6 || tIndex != 4 + 2 + 2) {
      throw FormatException('Invalid datetime definition: $content');
    }
    final date = DateParser.parseDate(content.substring(0, 4 + 2 + 2));
    final time = TimeOfDayWithSeconds.parse(content.substring(tIndex + 1));
    return DateTime(
        date.year, date.month, date.day, time.hour, time.minute, time.second);
  }
}

class DateTimeOrDuration {
  final DateTime? dateTime;
  final IsoDuration? duration;

  DateTimeOrDuration(this.dateTime, this.duration);

  static DateTimeOrDuration parse(String textValue, ValueType type) {
    DateTime? dateTime;
    IsoDuration? duration;
    if (type == ValueType.dateTime) {
      dateTime = DateParser.parseDateTime(textValue);
    } else if (type == ValueType.date) {
      dateTime = DateParser.parseDate(textValue);
    } else if (type == ValueType.duration) {
      duration = IsoDuration.parse(textValue);
    } else {
      throw FormatException(
          'Unsupported type for DateTimeOrDuration: $type with text [$textValue].');
    }
    return DateTimeOrDuration(dateTime, duration);
  }
}

/// Contains a precise period of time.
class Period {
  /// The startdate
  final DateTime startDate;

  /// The duration
  ///
  /// Either the [duration] or the [enddate] will be defined.
  final IsoDuration? duration;

  /// The end date
  ///
  /// Either the [duration] or the [enddate] will be defined.
  final DateTime? endDate;

  Period(this.startDate, {this.duration, this.endDate})
      : assert(duration != null || endDate != null,
            'Either duration or endDate must be set.'),
        assert(!(duration != null && endDate != null),
            'Not both duration and endDate can be set at the same time.');
  Period.text(String content)
      : startDate = _parseStartDate(content),
        endDate = _parseEndDate(content),
        duration = _parseDuration(content);

  static int _getSeparatorIndex(String content) {
    final separatorIndex = content.indexOf('/');
    if (separatorIndex == -1) {
      throw FormatException(
          'Invalid period definition, no / separator found in $content');
    }
    return separatorIndex;
  }

  static DateTime _parseStartDate(String content) {
    final separatorIndex = _getSeparatorIndex(content);
    final startDateText = content.substring(0, separatorIndex);
    return DateParser.parseDateTime(startDateText);
  }

  static DateTime? _parseEndDate(String content) {
    final separatorIndex = _getSeparatorIndex(content);
    final endText = content.substring(separatorIndex + 1);
    if (endText.startsWith('P')) {
      return null;
    }
    return DateParser.parseDateTime(endText);
  }

  static IsoDuration? _parseDuration(String content) {
    final separatorIndex = _getSeparatorIndex(content);
    final endText = content.substring(separatorIndex + 1);
    if (!endText.startsWith('P')) {
      return null;
    }
    return IsoDuration.parse(endText);
  }

  static Period parse(String textValue) {
    final startDate = _parseStartDate(textValue);
    final duration = _parseDuration(textValue);
    final endDate = _parseEndDate(textValue);
    return Period(startDate, duration: duration, endDate: endDate);
  }
}

class _DurationSection {
  final int result;
  final int index;
  _DurationSection(this.result, this.index);
}

/// ISO 8601 compliant duration
class IsoDuration {
  final int years;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final bool isNegativeDuration;

  IsoDuration({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
    this.isNegativeDuration = false,
  });

  static _DurationSection _parseSection(
      String content, int startIndex, String designatur) {
    final index = content.indexOf(designatur, startIndex);
    if (index == -1) {
      return _DurationSection(0, startIndex);
    }
    var text = content.substring(startIndex, index);
    if (text.contains(',')) {
      text = text.replaceAll(',', '.');
    }
    final parsed = int.tryParse(text);
    if (parsed == null) {
      throw FormatException('Invalid duration: $content (for part [$text])');
    }
    return _DurationSection(parsed, index + 1);
  }

  @override
  int get hashCode =>
      years +
      months * 12 +
      weeks * 53 +
      days * 366 +
      hours * 24 +
      minutes * 60 +
      seconds * 600;

  @override
  bool operator ==(Object other) {
    return other is IsoDuration &&
        other.years == years &&
        other.months == months &&
        other.weeks == weeks &&
        other.days == days &&
        other.hours == hours &&
        other.minutes == minutes &&
        other.seconds == seconds;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    if (isNegativeDuration) {
      buffer.write('-');
    }
    buffer.write('P');
    if (years != 0) {
      buffer..write(years)..write('Y');
    }
    if (months != 0) {
      buffer..write(months)..write('M');
    }
    if (weeks != 0) {
      buffer..write(weeks)..write('W');
    }
    if (days != 0) {
      buffer..write(days)..write('D');
    }
    if (hours != 0 || minutes != 0 || seconds != 0 || buffer.length == 1) {
      buffer.write('T');
      buffer
        ..write(hours)
        ..write('H')
        ..write(minutes)
        ..write('M')
        ..write(seconds)
        ..write('S');
    }
    return buffer.toString();
  }

  /// Parses the given [textValue] into a duration.
  ///
  /// The formmat is defined as `P[n]Y[n]M[n]DT[n]H[n]M[n]S`
  /// Example: `P3WT1H` means 3 weeks and 1 hour.
  /// Compare https://en.wikipedia.org/wiki/ISO_8601#Durations
  static IsoDuration parse(String textValue) {
    /// Note ISO_8601 allows floating numbers, compare https://en.wikipedia.org/wiki/ISO_8601#Durations,
    /// but even the validator https://icalendar.org/validator.html does not accept floating numbers.
    ///  So this implementation expects integers, too
    if (!(textValue.startsWith('P') || textValue.startsWith('-P'))) {
      throw FormatException(
          'duration content needs to start with P, $textValue is invalid');
    }
    final isNegativeDuration = textValue.startsWith('-');
    if (isNegativeDuration) {
      textValue = textValue.substring(1);
    }
    var years = 0, months = 0, weeks = 0, days = 0;
    var startIndex = 1;
    if (!textValue.startsWith('PT')) {
      final yearsResult = _parseSection(textValue, startIndex, 'Y');
      startIndex = yearsResult.index;
      years = yearsResult.result;
      final monthsResult = _parseSection(textValue, startIndex, 'M');
      startIndex = monthsResult.index;
      months = monthsResult.result;
      final weeksResult = _parseSection(textValue, startIndex, 'W');
      startIndex = weeksResult.index;
      weeks = weeksResult.result;
      final daysResult = _parseSection(textValue, startIndex, 'D');
      startIndex = daysResult.index;
      days = daysResult.result;
    }
    var hours = 0, minutes = 0, seconds = 0;
    if (startIndex < textValue.length && textValue[startIndex] == 'T') {
      startIndex++;
      final hoursResult = _parseSection(textValue, startIndex, 'H');
      hours = hoursResult.result;
      startIndex = hoursResult.index;
      final minutesResult = _parseSection(textValue, startIndex, 'M');
      minutes = minutesResult.result;
      startIndex = minutesResult.index;
      final secondsResult = _parseSection(textValue, startIndex, 'S');
      seconds = secondsResult.result;
    }

    return IsoDuration(
      years: years,
      months: months,
      weeks: weeks,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      isNegativeDuration: isNegativeDuration,
    );
  }
}

/// To specify the free or busy time type.
///
/// Compare [ParameterType.freeBusyTimeType], [FreeBusyType]
enum FreeBusyStatus { free, busy, busyUnavailable, busyTentative, other }

extension ExtensionFreeBusyValue on FreeBusyStatus {
  String? get name {
    switch (this) {
      case FreeBusyStatus.free:
        return 'FREE';
      case FreeBusyStatus.busy:
        return 'BUSY';
      case FreeBusyStatus.busyUnavailable:
        return 'BUSY-UNAVAILABLE';
      case FreeBusyStatus.busyTentative:
        return 'BUSY-TENTATIVE';
      case FreeBusyStatus.other:
        return null;
    }
  }
}

/// The type of a user
enum CalendarUserType { individual, group, resource, room, unknown, other }

extension ExtensionCommonCalendarUserTypeValue on CalendarUserType {
  String? get name {
    switch (this) {
      case CalendarUserType.individual:
        return 'INDIVIDUAL';
      case CalendarUserType.group:
        return 'GROUP';
      case CalendarUserType.resource:
        return 'RESOURCE';
      case CalendarUserType.room:
        return 'ROOM';
      case CalendarUserType.unknown:
        return 'UNKNOWN';
      case CalendarUserType.other:
        return null;
    }
  }
}

/// Specifies the relationship of the alarm trigger with respect to the start or end of the calendar component.
///
/// It is used for example in the `RELATED` parameter, [TriggerAlarm]
enum AlarmTriggerRelationship {
  /// the trigger is specified relative to the start of the calendar component
  start,

  /// the trigger is specified releative to the end of the calendar component
  end
}

extension ExtensionAlarmTriggerRelationship on AlarmTriggerRelationship {
  String? get name {
    switch (this) {
      case AlarmTriggerRelationship.start:
        return 'START';
      case AlarmTriggerRelationship.end:
        return 'END';
    }
  }
}

/// To specify the type of hierarchical relationship associated with the calendar component specified by the property.
enum Relationship {
  /// Parent relationship - Default
  parent,

  /// Child relationship
  child,

  /// Sibling relationship
  sibling,

  /// other
  other
}

extension ExtensionRelationship on Relationship {
  String? get name {
    switch (this) {
      case Relationship.parent:
        return 'PARENT';
      case Relationship.child:
        return 'CHILD';
      case Relationship.sibling:
        return 'SIBLING';
      case Relationship.other:
        return null;
    }
  }
}

/// To specify the participation role for the calendar user specified by the property.
enum Role {
  /// Indicates chair of the calendar entity
  chair,

  /// Indicates a participant whose participation is required
  requiredParticipant,

  /// Indicates a participant whose participation is optional
  optionalParticipant,

  /// Indicates a participant who is copied for information purposes only
  nonParticpant,

  /// Other
  other
}

extension ExtensionRole on Role {
  String? get name {
    switch (this) {
      case Role.chair:
        return 'CHAIR';
      case Role.requiredParticipant:
        return 'REQ-PARTICIPANT';
      case Role.optionalParticipant:
        return 'OPT-PARTICIPANT';
      case Role.nonParticpant:
        return 'NON-PARTICIPANT';
      case Role.other:
        return null;
    }
  }
}

/// Provides the range of a change
///
/// The "RANGE" parameter is used to specify the effective range of
/// recurrence instances from the instance specified by the
/// "RECURRENCE-ID" property value.  The value for the range parameter
/// can only be "THISANDFUTURE" to indicate a range defined by the
/// given recurrence instance and all subsequent instances.
enum Range {
  /// Specifies the effective range of recurrence instances that is specified by the property.
  ///
  /// The effective range is from the recurrence identifier
  /// specified by the property.  If this parameter is not specified on
  /// an allowed property, then the default range is the single instance
  /// specified by the recurrence identifier value of the property.  The
  /// parameter value can only be "THISANDFUTURE" to indicate a range
  /// defined by the recurrence identifier and all subsequent instances.
  /// The value "THISANDPRIOR" is deprecated by this revision of
  /// iCalendar and MUST NOT be generated by applications.
  thisAndFuture,
}

extension ExtensionRange on Range {
  String get name => 'THISANDFUTURE';
}

enum ParticipantStatus {
  /// Default status
  needsAction,

  /// Accepted
  accepted,

  /// Declined
  declined,

  /// Accepted tentatively
  tentative,

  /// Delegated (for a task)
  delegated,

  /// In Process (for a task)
  inProcess,

  /// Completed (for a task)
  completed,

  /// Other status
  other
}

extension ExtensionParticpantStatus on ParticipantStatus {
  String? get name {
    switch (this) {
      case ParticipantStatus.needsAction:
        return 'NEEDS-ACTION';
      case ParticipantStatus.accepted:
        return 'ACCEPTED';
      case ParticipantStatus.declined:
        return 'DECLINED';
      case ParticipantStatus.tentative:
        return 'TENTATIVE';
      case ParticipantStatus.delegated:
        return 'DELEGATED';
      case ParticipantStatus.inProcess:
        return 'IN-PROCESS';
      case ParticipantStatus.completed:
        return 'COMPLETED';
      case ParticipantStatus.other:
        return null;
    }
  }
}

class ClassificationParser {
  ClassificationParser._();
  static Classification parse(String textValue) {
    switch (textValue) {
      case 'PUBLIC':
        return Classification.public;
      case 'PRIVATE':
        return Classification.private;
      case 'CONFIDENTIAL':
        return Classification.confidential;
      default:
        return Classification.other;
    }
  }
}

/// The action of an alarm
enum AlarmAction {
  /// An audio sound should be played.
  ///
  /// When the action is "AUDIO", the alarm can also include one and
  /// only one "ATTACH" property, which MUST point to a sound resource,
  /// which is rendered when the alarm is triggered.
  audio,

  /// A notice should be displayed.
  ///
  /// When the action is "DISPLAY", the alarm MUST also include a
  /// "DESCRIPTION" property, which contains the text to be displayed
  /// when the alarm is triggered.
  display,

  /// An email should be sent.
  ///
  /// When the action is "EMAIL", the alarm MUST include a "DESCRIPTION"
  /// property, which contains the text to be used as the message body,
  /// a "SUMMARY" property, which contains the text to be used as the
  /// message subject, and one or more "ATTENDEE" properties, which
  /// contain the email address of attendees to receive the message.  It
  /// can also include one or more "ATTACH" properties, which are
  /// intended to be sent as message attachments.  When the alarm is
  /// triggered, the email message is sent.
  email,

  /// A different, non-standard alarm action should be taken.
  other
}

/// Contains all relevant binary information
class Binary {
  /// The data in textual form
  final String value;

  /// The media like `image/png`
  final String? mediaType;

  /// The encoding type like `BASE64`
  final String? encoding;

  Binary(
      {required this.value, required this.mediaType, required this.encoding});
}

/// Provides access to a geolocation
class GeoLocation {
  final double latitude;
  final double longitude;

  GeoLocation(this.latitude, this.longitude);

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(latitude)
      ..write(';')
      ..write(longitude);
    return buffer.toString();
  }
}
