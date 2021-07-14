import 'parameters.dart';
import 'types.dart';
import 'util.dart';

class Property {
  Property(this.definition, ValueType defaultValueType)
      : name = _getName(definition),
        textValue = _getTextContent(definition),
        parameters = _parseParameters(definition) {
    value = _parsePropertyValue(this, defaultValueType);
  }

  /// The value of this property
  late dynamic value;

  /// Full property content, e.g. `DTSTAMP;TZID=America/New_York:19970610T172345Z`
  final String definition;

  /// Name of the property, e.g. `DTSTAMP`
  final String name;

  /// Value of the property, e.g. `19970610T172345Z`
  final String textValue;

  /// Additional parameters for this property, e.g. `{'TZID' : TextValueType('America/New_York')}}
  final Map<String, Parameter> parameters;

  dynamic parse(String textValue) {
    throw FormatException(
        'Implement parse to allow custom value in property: $definition');
  }

  Parameter? operator [](ParameterType param) => parameters[param.name];

  operator []=(String name, Parameter value) => parameters[name] = value;

  T? getParameterValue<T>(ParameterType param) =>
      parameters[param.name]?.value as T?;

  static String? _lastContent;
  static List<int>? _lastRunes;
  static int _getNameEndIndex(String content) => _getIndex(content);
  static int _getValueStartIndex(String content) =>
      _getIndex(content, searchNameEndIndex: false);

  static int _getIndex(String content, {bool searchNameEndIndex = true}) {
    final runes =
        content == _lastContent ? _lastRunes! : content.runes.toList();
    var isInQuote = false;
    var isLastBackSlash = false;
    int? index;
    for (int i = 0; i < runes.length; i++) {
      final rune = runes[i];
      if (isLastBackSlash) {
        isLastBackSlash = false;
      } else {
        if (rune == Rune.runeDoubleQuote) {
          isInQuote = !isInQuote;
        } else {
          if (rune == Rune.runeBackslash) {
            isLastBackSlash = true;
          } else if (!isInQuote) {
            if (rune == Rune.runeColon) {
              index = i;
              break;
            } else if (searchNameEndIndex && rune == Rune.runeSemicolon) {
              index = i;
              break;
            }
          }
        }
      }
    }
    if (index == null) {
      throw FormatException('Invalid property: no colon : found in [$content]');
    }
    _lastContent = content;
    _lastRunes = runes;
    return index;
  }

  static String _getName(String content) {
    final nameEndIndex = _getNameEndIndex(content);
    return content.substring(0, nameEndIndex);
  }

  static String _getTextContent(String content) {
    final valueStartIndex = _getValueStartIndex(content);
    return content.substring(valueStartIndex + 1);
  }

  static int? _getNextParameterStartIndex(List<int> runes, int startIndex) {
    var isInQuote = false;
    var isLastBackSlash = false;
    for (int i = startIndex; i < runes.length; i++) {
      final rune = runes[i];
      if (isLastBackSlash) {
        isLastBackSlash = false;
      } else {
        if (rune == Rune.runeDoubleQuote) {
          isInQuote = !isInQuote;
        } else {
          if (rune == Rune.runeBackslash) {
            isLastBackSlash = true;
          } else if (!isInQuote) {
            if (rune == Rune.runeColon) {
              return i;
            } else if (rune == Rune.runeSemicolon) {
              return i;
            }
          }
        }
      }
    }
    return null;
  }

  static Map<String, Parameter> _parseParameters(String content) {
    final result = <String, Parameter>{};
    final nameEndIndex = _getNameEndIndex(content);
    final valueStartIndex = _getValueStartIndex(content);
    if (valueStartIndex > nameEndIndex + 1) {
      final parametersText =
          content.substring(nameEndIndex + 1, valueStartIndex);
      final runes = parametersText.runes.toList();
      var lastStartIndex = 0;
      int? nextStartIndex;
      while (true) {
        nextStartIndex = _getNextParameterStartIndex(runes, lastStartIndex);
        final parameterText = nextStartIndex == null
            ? parametersText.substring(lastStartIndex)
            : parametersText.substring(lastStartIndex, nextStartIndex);
        try {
          final parameter = Parameter.parse(parameterText);
          result[parameter.name] = parameter;
        } on FormatException catch (e, s) {
          print(e.message);
          print(s);
          throw FormatException('${e.message} in property $content');
        }
        if (nextStartIndex == null) {
          break;
        }
        lastStartIndex = nextStartIndex + 1;
      }
    }
    return result;
  }

  static dynamic _parsePropertyValue(
      Property property, ValueType defaultValueType) {
    final valueType =
        (property[ParameterType.value] as ValueParameter?)?.valueType ??
            defaultValueType;
    final textValue = property.textValue;
    switch (valueType) {
      case ValueType.binary:
        return Binary(
          value: textValue,
          mediaType: property[ParameterType.formatType]?.textValue,
          encoding: property[ParameterType.encoding]?.textValue,
        );
      case ValueType.boolean:
        return BooleanParameter.parse(textValue);
      case ValueType.calendarAddress:
        return CalendarAddressParameter.parse(textValue);
      case ValueType.date:
        return DateParser.parseDate(textValue);
      case ValueType.dateTime:
        return DateParser.parseDateTime(textValue);
      case ValueType.duration:
        return IsoDuration.parse(textValue);
      case ValueType.float:
        return double.parse(textValue);
      case ValueType.integer:
        return int.parse(textValue);
      case ValueType.period:
        return Period.parse(textValue);
      case ValueType.periodList:
        return textValue.split(',').map((text) => Period.parse(text)).toList();
      case ValueType.recurrence:
        return Recurrence.parse(textValue);
      case ValueType.text:
        return textValue;
      case ValueType.time:
        return TimeOfDayWithSeconds.parse(textValue);
      case ValueType.uri:
        return UriParameter.parse(textValue);
      case ValueType.utcOffset:
        return UtcOffset(textValue);
      case ValueType.typeUriList:
        return UriListParameter.parse(textValue);
      case ValueType.typeClassification:
        return ClassificationParser.parse(textValue);
      case ValueType.other:
        return property.parse(textValue);
      case ValueType.typeFreeBusy:
      case ValueType.typeParticipantStatus:
      case ValueType.typeRange:
      case ValueType.typeAlarmTriggerRelationship:
      case ValueType.typeRelationship:
      case ValueType.typeRole:
      case ValueType.typeValue:
        throw FormatException(
            'Unable to parse ${property.name} with value $textValue and invalid valueType of $valueType');
      case ValueType.typeDateTimeList:
        return textValue
            .split(',')
            .map((text) => DateTimeOrDuration.parse(text, ValueType.dateTime))
            .toList();
    }
  }

  static Property parseProperty(String definition,
      {Property? Function(String name, String definition)? customParser}) {
    final name = _getName(definition);
    switch (name) {
      case TextProperty.propertyNameUid:
      case TextProperty.propertyNameMethod:
      case TextProperty.propertyNameProductIdentifier:
      case TextProperty.propertyNameComment:
      case TextProperty.propertyNameDescription:
      case TextProperty.propertyNameSummary:
      case TextProperty.propertyNameLocation:
      case TextProperty.propertyNameResources:
      case TextProperty.propertyNameTimezoneId:
      case TextProperty.propertyNameTimezoneName:
      case TextProperty.propertyNameRelatedTo:
      case TextProperty.propertyNameXWrTimezone:
        return TextProperty(definition);
      case DateTimeProperty.propertyNameCompleted:
      case DateTimeProperty.propertyNameDue:
      case DateTimeProperty.propertyNameEnd:
      case DateTimeProperty.propertyNameStart:
      case DateTimeProperty.propertyNameTimeStamp:
      case DateTimeProperty.propertyNameCreated:
      case DateTimeProperty.propertyNameLastModified:
      case DateTimeProperty.propertyNameRecurrenceId:
        return DateTimeProperty(definition);
      case IntegerProperty.propertyNamePercentComplete:
      case IntegerProperty.propertyNameSequence:
      case IntegerProperty.propertyNameRepeat:
        return IntegerProperty(definition);
      case CalendarScaleProperty.propertyName:
        return CalendarScaleProperty(definition);
      case UtfOffsetProperty.propertyNameTimezoneOffsetFrom:
      case UtfOffsetProperty.propertyNameTimezoneOffsetTo:
        return UtfOffsetProperty(definition);
      case RecurrenceRuleProperty.propertyName:
        return RecurrenceRuleProperty(definition);
      case UriProperty.propertyNameTimezoneUrl:
      case UriProperty.propertyNameUrl:
        return UriProperty(definition);
      case GeoProperty.propertyName:
        return GeoProperty(definition);
      case AttendeeProperty.propertyName:
        return AttendeeProperty(definition);
      case OrganizerProperty.propertyName:
        return OrganizerProperty(definition);
      case UserProperty.propertyNameContact:
        return UserProperty(definition);
      case VersionProperty.propertyName:
        return VersionProperty(definition);
      case AttachmentProperty.propertyName:
        return AttachmentProperty(definition);
      case CategoriesProperty.propertyName:
        return CategoriesProperty(definition);
      case ClassificationProperty.propertyName:
        return ClassificationProperty(definition);
      case PriorityProperty.propertyName:
        return PriorityProperty(definition);
      case StatusProperty.propertyName:
        return StatusProperty(definition);
      case DurationProperty.propertyName:
        return DurationProperty(definition);
      case TimeTransparencyProperty.propertyName:
        return TimeTransparencyProperty(definition);
      case FreeBusyProperty.propertyName:
        return FreeBusyProperty(definition);
      case ActionProperty.propertyName:
        return ActionProperty(definition);
      case TriggerProperty.propertyName:
        return TriggerProperty(definition);
      case RecurrenceDateProperty.propertyNameRDate:
      case RecurrenceDateProperty.propertyNameExDate:
        return RecurrenceDateProperty(definition);

      default:
        if (customParser != null) {
          final prop = customParser(name, definition);
          if (prop != null) {
            return prop;
          }
        }
        print('No property implementation found for $definition');
        return Property(definition, ValueType.text);
    }
  }
}

class RecurrenceRuleProperty extends Property {
  static const String propertyName = 'RRULE';
  Recurrence get rule => value as Recurrence;

  RecurrenceRuleProperty(String definition)
      : super(definition, ValueType.other);

  Recurrence parse(String texValue) {
    return Recurrence.parse(textValue);
  }
}

class UriProperty extends Property {
  static const String propertyNameTimezoneUrl = 'TZURL';
  static const String propertyNameUrl = 'URL';

  Uri get uri => value as Uri;
  UriProperty(String definition) : super(definition, ValueType.uri);
}

class UserProperty extends UriProperty {
  static const String propertyNameContact = 'CONTACT';
  UserProperty(String definition) : super(definition);

  String? get commonName => getParameterValue<String>(ParameterType.commonName);

  Uri? get directory => getParameterValue<Uri>(ParameterType.directory);

  Uri? get alternateRepresentation =>
      getParameterValue<Uri>(ParameterType.alternateRepresentation);

  CalendarUserType? get userType =>
      getParameterValue<CalendarUserType>(ParameterType.calendarUserType);

  String? get email => uri.isScheme('MAILTO') ? uri.path : null;
}

class AttendeeProperty extends UserProperty {
  static const String propertyName = 'ATTENDEE';
  Uri get attendee => uri;

  bool get rsvp => getParameterValue<bool>(ParameterType.rsvp) ?? false;

  Role get role =>
      getParameterValue<Role>(ParameterType.participantRole) ??
      Role.requiredParticipant;

  ParticipantStatus? get participantStatus =>
      getParameterValue<ParticipantStatus>(ParameterType.participantStatus);

  AttendeeProperty(String definition) : super(definition);
}

class OrganizerProperty extends UserProperty {
  static const String propertyName = 'ORGANIZER';
  Uri get organizer => uri;

  Uri? get sentBy => getParameterValue<Uri>(ParameterType.sentBy);

  OrganizerProperty(String definition) : super(definition);
}

class GeoProperty extends Property {
  static const String propertyName = 'GEO';

  GeoLocation get location => value as GeoLocation;
  GeoProperty(String definition) : super(definition, ValueType.other);

  GeoProperty.value(GeoLocation location)
      : this('GEO:${location.latitude};${location.longitude}');

  GeoLocation parse(String content) {
    final semicolonIndex = content.indexOf(';');
    if (semicolonIndex == -1) {
      throw FormatException('Invalid GEO property $content');
    }
    final latitudeText = content.substring(0, semicolonIndex);
    final latitude = double.tryParse(latitudeText);
    if (latitude == null) {
      throw FormatException(
          'Invalid GEO property - unable to parse latitude value $latitudeText in  $content');
    }
    final longitudeText = content.substring(semicolonIndex + 1);
    final longitude = double.tryParse(longitudeText);
    if (longitude == null) {
      throw FormatException(
          'Invalid GEO property - unable to parse longitude value $longitudeText in  $content');
    }
    return GeoLocation(latitude, longitude);
  }
}

class AttachmentProperty extends Property {
  static const String propertyName = 'ATTACH';

  /// Retrieves the URI of the data such as `https://domain.com/assets/image.png`
  Uri? get uri => value is Uri ? value : null;

  /// Retrieves the binary data information
  Binary? get binary => value is Binary ? value : null;

  /// Retrieves the mime type / media type / format type like `image/png` as specified in the `FMTTYPE` parameter.
  String? get mediaType => getParameterValue<String>(ParameterType.formatType);

  /// Retrieves the encoding such as `BASE64`, only relevant when the content is binary
  ///
  /// Compare [isBinary]
  String? get encoding => getParameterValue<String>(ParameterType.encoding);

  /// Checks if this contains binary data
  ///
  /// Compare [binary]
  bool get isBinary => value is Binary;

  AttachmentProperty(String content) : super(content, ValueType.uri);
}

class CalendarScaleProperty extends Property {
  static const String propertyName = 'CALSCALE';
  bool get isGregorianCalendar => textValue == 'GREGORIAN';

  CalendarScaleProperty(String definition) : super(definition, ValueType.text);
}

class VersionProperty extends Property {
  static const String propertyName = 'VERSION';

  bool get isVersion2 => textValue == '2.0';

  VersionProperty(String definition) : super(definition, ValueType.text);
}

class CategoriesProperty extends Property {
  static const String propertyName = 'CATEGORIES';

  List<String> get categories => textValue.split(',');

  CategoriesProperty(String definition) : super(definition, ValueType.text);
}

class ClassificationProperty extends Property {
  static const String propertyName = 'CLASS';

  Classification get classification => value as Classification;

  ClassificationProperty(String definition)
      : super(definition, ValueType.typeClassification);
}

class TextProperty extends Property {
  static const String propertyNameComment = 'COMMENT';
  static const String propertyNameDescription = 'DESCRIPTION';
  static const String propertyNameProductIdentifier = 'PRODID';
  static const String propertyNameMethod = 'METHOD';
  static const String propertyNameSummary = 'SUMMARY';
  static const String propertyNameLocation = 'LOCATION';
  static const String propertyNameResources = 'RESOURCES';
  static const String propertyNameUid = 'UID';
  static const String propertyNameXWrTimezone = 'X-WR-TIMEZONE';
  static const String propertyNameTimezoneId = 'TZID';
  static const String propertyNameTimezoneName = 'TZNAME';
  static const String propertyNameRelatedTo = 'RELATED-TO';

  String? get language => this[ParameterType.language]?.textValue;
  Uri? get alternateRepresentation =>
      (this[ParameterType.alternateRepresentation] as UriParameter?)?.uri;

  String get text => value as String;

  TextProperty(String definition) : super(definition, ValueType.text);
}

class IntegerProperty extends Property {
  static const String propertyNamePercentComplete = 'PERCENT-COMPLETE';
  static const String propertyNameSequence = 'SEQUENCE';
  static const String propertyNameRepeat = 'REPEAT';

  int get intValue => value as int;

  IntegerProperty(String definition) : super(definition, ValueType.integer);
}

class DateTimeProperty extends Property {
  static const String propertyNameCompleted = 'COMPLETED';
  static const String propertyNameEnd = 'DTEND';
  static const String propertyNameStart = 'DTSTART';
  static const String propertyNameDue = 'DUE';
  static const String propertyNameTimeStamp = 'DTSTAMP';
  static const String propertyNameCreated = 'CREATED';
  static const String propertyNameLastModified = 'LAST-MODIFIED';
  static const String propertyNameRecurrenceId = 'RECURRENCE-ID';

  DateTime get dateTime => value as DateTime;

  /// Retrieves the timezone ID like `America/New_York` or `Europe/Berlin` from the `TZID` parameter.
  String? get timezoneId => this[ParameterType.timezoneId]?.textValue;

  DateTimeProperty(String definition) : super(definition, ValueType.dateTime);
}

class DurationProperty extends Property {
  static const String propertyName = 'DURATION';

  IsoDuration get duration => value as IsoDuration;

  DurationProperty(String definition) : super(definition, ValueType.duration);
}

class PeriodProperty extends Property {
  //static const String propertyNameFreeBusy = 'FREEBUSY';

  Period get period => value as Period;

  PeriodProperty(String definition) : super(definition, ValueType.period);
}

class UtfOffsetProperty extends Property {
  static const String propertyNameTimezoneOffsetFrom = 'TZOFFSETFROM';
  static const String propertyNameTimezoneOffsetTo = 'TZOFFSETTO';

  UtcOffset get offset => value as UtcOffset;

  UtfOffsetProperty(String definition) : super(definition, ValueType.utcOffset);
}

class FreeBusyProperty extends Property {
  static const String propertyName = 'FREEBUSY';

  FreeBusyStatus get freeBusyType =>
      getParameterValue<FreeBusyStatus>(ParameterType.freeBusyTimeType) ??
      FreeBusyStatus.busy;

  List<Period> get periods => value as List<Period>;

  FreeBusyProperty(String definition) : super(definition, ValueType.periodList);
}

enum Priority { high, medium, low, undefined }

extension ExtensionPriority on Priority {
  int toInt() {
    switch (this) {
      case Priority.high:
        return 1;
      case Priority.medium:
        return 5;
      case Priority.low:
        return 9;
      case Priority.undefined:
        return 0;
    }
  }
}

class PriorityProperty extends IntegerProperty {
  static const String propertyName = 'PRIORITY';

  Priority get priority {
    final number = intValue;
    if (number == 0) {
      return Priority.undefined;
    } else if (number < 5) {
      return Priority.high;
    } else if (number == 5) {
      return Priority.medium;
    } else if (number < 10) {
      return Priority.low;
    }
    return Priority.undefined;
  }

  PriorityProperty(String definition) : super(definition);
}

enum EventStatus { tentative, confirmed, cancelled, unknown }

enum TodoStatus { needsAction, completed, inProcess, cancelled, unknown }

enum JournalStatus { draft, finalized, cancelled, unknown }

class StatusProperty extends TextProperty {
  static const String propertyName = 'STATUS';

  EventStatus get eventStatus {
    final text = textValue;
    switch (text) {
      case 'TENTATIVE':
        return EventStatus.tentative;
      case 'CONFIRMED':
        return EventStatus.confirmed;
      case 'CANCELLED':
        return EventStatus.cancelled;
      default:
        return EventStatus.unknown;
    }
  }

  TodoStatus get todoStatus {
    final text = textValue;
    switch (text) {
      case 'NEEDS-ACTION':
        return TodoStatus.needsAction;
      case 'IN-PROCESS':
        return TodoStatus.inProcess;
      case 'COMPLETED':
        return TodoStatus.completed;
      case 'CANCELLED':
        return TodoStatus.cancelled;
      default:
        return TodoStatus.unknown;
    }
  }

  JournalStatus get journalStatus {
    final text = textValue;
    switch (text) {
      case 'DRAFT':
        return JournalStatus.draft;
      case 'FINAL':
        return JournalStatus.finalized;
      case 'CANCELLED':
        return JournalStatus.cancelled;
      default:
        return JournalStatus.unknown;
    }
  }

  StatusProperty(String definition) : super(definition);
}

/// Transparency for busy time searches
enum TimeTransparency {
  /// The associated event's timeslot is visible in busy time searches
  opaque,

  /// The associated event's timeslot is hiddem from busy time searches
  transparent,
}

/// This property defines whether or not an event is transparent to busy time searches.
class TimeTransparencyProperty extends TextProperty {
  static const String propertyName = 'TRANSP';

  /// Retrieves the transparency
  TimeTransparency get transparency {
    final text = textValue;
    switch (text) {
      case 'OPAQUE':
        return TimeTransparency.opaque;
      case 'TRANSPARENT':
        return TimeTransparency.transparent;
      default:
        return TimeTransparency.opaque;
    }
  }

  TimeTransparencyProperty(String definition) : super(definition);
}

class RecurrenceDateProperty extends Property {
  static const String propertyNameRDate = 'RDATE';
  static const String propertyNameExDate = 'EXDATE';

  List<DateTimeOrDuration> get dates => value as List<DateTimeOrDuration>;

  RecurrenceDateProperty(String definition)
      : super(definition, ValueType.typeDateTimeList);
}

class TriggerProperty extends Property {
  static const String propertyName = 'TRIGGER';

  IsoDuration? get duration => value is IsoDuration ? value : null;
  DateTime? get dateTime => value is DateTime ? value : null;
  AlarmTriggerRelationship get triggerRelation =>
      getParameterValue<AlarmTriggerRelationship>(
          ParameterType.alarmTriggerRelationship) ??
      AlarmTriggerRelationship.start;

  TriggerProperty(String definition) : super(definition, ValueType.duration);
}

class ActionProperty extends TextProperty {
  static const String propertyName = 'ACTION';

  AlarmAction? _action;
  AlarmAction get action {
    var act = _action;
    if (act == null) {
      switch (textValue) {
        case 'AUDIO':
          act = AlarmAction.audio;
          break;
        case 'DISPLAY':
          act = AlarmAction.display;
          break;
        case 'EMAIL':
          act = AlarmAction.email;
          break;
        default:
          act = AlarmAction.other;
          break;
      }
      _action = act;
    }
    return act;
  }

  ActionProperty(String definition) : super(definition);
}

class RequestStatusProperty extends TextProperty {
  static const String propertyName = 'REQUEST-STATUS';

  //TODO consider extracting status code from text, compare https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.4.5
  String get requestStatus => text;

  RequestStatusProperty(String definition) : super(definition);
}
