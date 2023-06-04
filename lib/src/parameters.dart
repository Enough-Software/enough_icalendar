import 'dart:core';
import 'types.dart';
import 'util.dart';

/// Contains a property parameter
///
/// In contrast to properties, the type of a parameter is always predefined.
abstract class Parameter<T> {
  /// Creates a new parameter
  Parameter(this.name, this.textValue, this.value);

  /// the name of this parameter
  final String name;

  /// the unparsed text value of this parameter
  final String textValue;

  /// The parsed value
  final T value;

  /// Parses the given [definition] and generates a corresponding Parameter.
  static Parameter parse(String definition) {
    final splitIndex = definition.indexOf('=');
    if (splitIndex == -1) {
      throw FormatException(
        'No equals sign (=) found in parameter [$definition]',
      );
    }
    final name = definition.substring(0, splitIndex);
    final textValue = definition.substring(splitIndex + 1);
    switch (name) {
      case 'ALTREP':
        return UriParameter(
          name,
          textValue,
        );
      case 'CN':
        return TextParameter(name, textValue);
      case 'CUTYPE':
        return CalendarUserTypeParameter(name, textValue);
      case 'DELEGATED-FROM':
        return UriParameter(name, textValue);
      case 'DELEGATED-TO':
        return UriParameter(name, textValue);
      case 'DIR':
        return UriParameter(name, textValue);
      case 'ENCODING':
        return TextParameter(name, textValue);
      case 'FMTTYPE':
        return TextParameter(name, textValue);
      case 'FBTYPE':
        return FreeBusyTimeTypeParameter(
          name,
          textValue,
        );
      case 'LANGUAGE':
        return TextParameter(name, textValue);
      case 'MEMBER':
        return UriListParameter(name, textValue);
      case 'PARTSTAT':
        return ParticipantStatusParameter(name, textValue);
      case 'RANGE':
        return RangeParameter(name, textValue);
      case 'RELATED':
        return AlarmTriggerRelationshipParameter(name, textValue);
      case 'RELTYPE':
        return RelationshipParameter(name, textValue);
      case 'ROLE':
        return ParticipantRoleParameter(name, textValue);
      case 'RSVP':
        return BooleanParameter(name, textValue);
      case 'SENT-BY':
        return UriParameter(name, textValue);
      case 'TZID':
        return TextParameter(name, textValue);
      case 'VALUE':
        return ValueParameter(name, textValue);
      case 'X-FILENAME':
        return TextParameter(name, textValue);
      case 'EMAIL':
        return TextParameter(name, textValue);
      default:
        print('Encountered unsupported parameter [$name]');
        return TextParameter(name, textValue);
    }
  }
}

/// Parameter that contain an URI like `ALTREP`
class UriParameter extends Parameter<Uri> {
  /// Creates a new [UriParameter]
  UriParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [UriParameter]
  UriParameter.value(String name, Uri value) : super(name, '"$value"', value);

  /// Retrieves the value as Uri
  Uri get uri => value;

  /// Parses the given [textValue] as an URI
  static Uri parse(String textValue) {
    var usedValue = textValue;
    if (usedValue.startsWith('"')) {
      usedValue = usedValue.substring(1, usedValue.length - 1);
    }
    if (usedValue.startsWith(':')) {
      usedValue = usedValue.substring(1);
    }

    return Uri.parse(usedValue);
  }

  /// Creates a new [UriParameter] when the [value] is not null
  static UriParameter? create(String name, Uri? value) {
    if (value == null) {
      return null;
    }

    return UriParameter.value(name, value);
  }
}

/// Parameter or value that contains one or several URIs like `MEMBER`
class UriListParameter extends Parameter<List<Uri>> {
  /// Creates a new [UriListParameter]
  UriListParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [UriListParameter]
  UriListParameter.value(String name, List<Uri> value)
      : super(name, renderUris(value), value);

  /// Retrieves the value as Uri
  List<Uri> get uris => value;

  /// Parses the given [textValue]
  static List<Uri> parse(final String textValue) {
    final runes = textValue.runes.toList();
    final result = <Uri>[];
    var isInQuote = false;
    var isLastBackslash = false;
    var lastQuoteStart = 0;
    for (var i = 0; i < runes.length; i++) {
      final rune = runes[i];
      if (isLastBackslash) {
        // ignore this char
        isLastBackslash = false;
      } else {
        if (rune == Rune.runeDoubleQuote) {
          if (isInQuote) {
            // this is the URI end
            final uriText = textValue.substring(lastQuoteStart, i);
            final uri = Uri.parse(uriText);
            result.add(uri);
            lastQuoteStart = i + 1;
            isInQuote = false;
          } else {
            isInQuote = true;
            lastQuoteStart = i;
          }
        } else if (rune == Rune.runeComma && !isInQuote) {
          if (lastQuoteStart < i - 2) {
            final uriText = textValue.substring(lastQuoteStart, i);
            final uri = Uri.parse(uriText);
            result.add(uri);
          }
          lastQuoteStart = i + 1;
        } else if (rune == Rune.runeBackslash) {
          isLastBackslash = true;
        }
      }
    }

    return result;
  }

  /// Encodes the given [uris]
  static String renderUris(List<Uri> uris) =>
      uris.map((uri) => '"$uri"').join(',');

  /// Creates a new [UriListParameter] when the [value] is not null
  static UriListParameter? create(String name, List<Uri>? value) {
    if (value == null) {
      return null;
    }

    return UriListParameter.value(name, value);
  }
}

/// Parameter containing text
class TextParameter extends Parameter<String> {
  /// Creates a new [TextParameter]
  TextParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [TextParameter]
  TextParameter.value(String name, String value)
      : super(name, _convertToSafeText(value), value);

  /// Retrieves the text
  String get text => value;

  static String _convertToSafeText(String value) {
    if (value.contains(';') || value.contains(',')) {
      return '"$value"';
    }

    return value;
  }

  /// Parses the [textValue]
  static String parse(String textValue) {
    if (textValue.startsWith('"')) {
      return textValue.substring(1, textValue.length - 1);
    }

    return textValue;
  }

  /// Creates a new [TextParameter] when the [value] is not null
  static TextParameter? create(String name, String? value) {
    if (value == null) {
      return null;
    }

    return TextParameter.value(name, value);
  }
}

/// Parameter containing boolean values
class BooleanParameter extends Parameter<bool> {
  /// Creates a new [BooleanParameter]
  BooleanParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [BooleanParameter]
  // ignore: avoid_positional_boolean_parameters
  BooleanParameter.value(String name, bool value)
      : super(name, value ? 'TRUE' : 'FALSE', value);

  /// Retrieves the value
  bool get boolValue => value;

  /// Parses the [textValue]
  static bool parse(String textValue) =>
      textValue == 'TRUE' || textValue == 'YES';

  /// Creates a new [BooleanParameter] when the [value] is not null
  // ignore: avoid_positional_boolean_parameters
  static BooleanParameter? create(String name, bool? value) {
    if (value == null) {
      return null;
    }

    return BooleanParameter.value(name, value);
  }
}

/// Parameter defining the type of calendar user
class CalendarUserTypeParameter extends Parameter<CalendarUserType> {
  /// Creates a new [CalendarUserTypeParameter]
  CalendarUserTypeParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [CalendarUserTypeParameter]
  CalendarUserTypeParameter.value(String name, CalendarUserType value)
      : super(name, value.typeName ?? '', value);

  /// Parses the given [textValue]
  static CalendarUserType parse(String textValue) {
    switch (textValue) {
      case 'INDIVIDUAL':
        return CalendarUserType.individual;
      case 'GROUP':
        return CalendarUserType.group;
      case 'RESOURCE':
        return CalendarUserType.resource;
      case 'ROOM':
        return CalendarUserType.room;
      case 'UNKNOWN':
        return CalendarUserType.unknown;
      default:
        return CalendarUserType.other;
    }
  }

  /// Creates a new [CalendarUserTypeParameter] when the [value] is not null
  static CalendarUserTypeParameter? create(
    String name,
    CalendarUserType? value,
  ) {
    if (value == null) {
      return null;
    }

    return CalendarUserTypeParameter.value(name, value);
  }
}

/// Parameter defining the status of a free busy property
class FreeBusyTimeTypeParameter extends Parameter<FreeBusyTimeType> {
  /// Creates a new [FreeBusyTimeTypeParameter]
  FreeBusyTimeTypeParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [FreeBusyTimeTypeParameter]
  FreeBusyTimeTypeParameter.value(String name, FreeBusyTimeType value)
      : super(name, value.typeName ?? '', value);

  /// Gets the value
  FreeBusyTimeType get timeType => value;

  /// Parses the given [textValue]
  static FreeBusyTimeType parse(String textValue) {
    switch (textValue) {
      case 'FREE':
        return FreeBusyTimeType.free;
      case 'BUSY':
        return FreeBusyTimeType.busy;
      case 'BUSY-UNAVAILABLE':
        return FreeBusyTimeType.busyUnavailable;
      case 'BUSY-TENTATIVE':
        return FreeBusyTimeType.busyTentative;
      default:
        return FreeBusyTimeType.other;
    }
  }

  /// Creates a new [FreeBusyTimeTypeParameter] when the [value] is not null
  static FreeBusyTimeTypeParameter? create(
    String name,
    FreeBusyTimeType? value,
  ) {
    if (value == null) {
      return null;
    }

    return FreeBusyTimeTypeParameter.value(name, value);
  }
}

/// Parameter defining the participant status
class ParticipantStatusParameter extends Parameter<ParticipantStatus> {
  /// Creates a new [ParticipantStatusParameter]
  ParticipantStatusParameter(String name, String textValue)
      : super(
          name,
          textValue,
          parse(textValue),
        );

  /// Creates a new [ParticipantStatusParameter]
  ParticipantStatusParameter.value(String name, ParticipantStatus status)
      : super(name, status.typeName ?? '', status);

  /// Retrieves the value
  ParticipantStatus get status => value;

  /// Parses the given [textValue]
  static ParticipantStatus parse(String textValue) {
    switch (textValue) {
      case 'NEEDS-ACTION':
        return ParticipantStatus.needsAction;
      case 'ACCEPTED':
        return ParticipantStatus.accepted;
      case 'DECLINED':
        return ParticipantStatus.declined;
      case 'TENTATIVE':
        return ParticipantStatus.tentative;
      case 'DELEGATED':
        return ParticipantStatus.delegated;
      case 'IN-PROCESS':
        return ParticipantStatus.inProcess;
      case 'PARTIAL':
        return ParticipantStatus.partial;
      case 'COMPLETED':
        return ParticipantStatus.completed;
      default:
        return ParticipantStatus.other;
    }
  }

  /// Creates a new [ParticipantStatusParameter] when the [value] is not null
  static ParticipantStatusParameter? create(
    String name,
    ParticipantStatus? value,
  ) {
    if (value == null) {
      return null;
    }

    return ParticipantStatusParameter.value(name, value);
  }
}

/// Parameter defining the range of a change
///
/// This parameter can be specified on a property that
/// specifies a recurrence identifier.  The parameter specifies the
/// effective range of recurrence instances that is specified by the
/// property.  The effective range is from the recurrence identifier
/// specified by the property.  If this parameter is not specified on
/// an allowed property, then the default range is the single instance
/// specified by the recurrence identifier value of the property.  The
/// parameter value can only be "THISANDFUTURE" to indicate a range
/// defined by the recurrence identifier and all subsequent instances.
/// The value "THISANDPRIOR" is deprecated by this revision of
/// iCalendar and MUST NOT be generated by applications.
class RangeParameter extends Parameter<Range> {
  /// Creates a new [RangeParameter]
  RangeParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [RangeParameter]
  RangeParameter.value(String name, Range range)
      : super(name, range.name, range);

  /// Retrieves the range
  Range get range => value;

  /// Checks is this range affects the current subsequent instances
  bool get isThisAndFuture => range == Range.thisAndFuture;

  /// Parses the given [textValue]
  static Range parse(String textValue) {
    switch (textValue) {
      case 'THISANDFUTURE':
        return Range.thisAndFuture;
      default:
        throw FormatException('Invalid range: [$textValue]');
    }
  }

  /// Creates a new [RangeParameter] when the [value] is not null
  static RangeParameter? create(String name, Range? value) {
    if (value == null) {
      return null;
    }

    return RangeParameter.value(name, value);
  }
}

/// Specifies the relationship of the alarm trigger with respect to the start
/// or end of the calendar component.
///
/// Example is the `RELATED` parameter.
class AlarmTriggerRelationshipParameter
    extends Parameter<AlarmTriggerRelationship> {
  /// Creates a new [AlarmTriggerRelationshipParameter]
  AlarmTriggerRelationshipParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [AlarmTriggerRelationshipParameter]
  AlarmTriggerRelationshipParameter.value(
    String name,
    AlarmTriggerRelationship relation,
  ) : super(name, relation.typeName ?? '', relation);

  /// Gets the value
  AlarmTriggerRelationship get relationship => value;

  /// Parses the given [textValue]
  static AlarmTriggerRelationship parse(String textValue) {
    switch (textValue) {
      case 'START':
        return AlarmTriggerRelationship.start;
      case 'END':
        return AlarmTriggerRelationship.end;
    }
    throw FormatException('Invalid RELATED content [$textValue]');
  }

  /// Creates a new [AlarmTriggerRelationshipParameter] when the [value]
  /// is not null
  static AlarmTriggerRelationshipParameter? create(
    String name,
    AlarmTriggerRelationship? value,
  ) {
    if (value == null) {
      return null;
    }

    return AlarmTriggerRelationshipParameter.value(name, value);
  }
}

/// Defines the relationship of the parameter's property
class RelationshipParameter extends Parameter<Relationship> {
  /// Creates a new [RelationshipParameter]
  RelationshipParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [RelationshipParameter]
  RelationshipParameter.value(String name, Relationship relationship)
      : super(name, relationship.typeName ?? '', relationship);

  /// Gets the value
  Relationship get relationship => value;

  /// Parses the given [textValue]
  static Relationship parse(String textValue) {
    switch (textValue) {
      case 'PARENT':
        return Relationship.parent;
      case 'CHILD':
        return Relationship.child;
      case 'SIBLING':
        return Relationship.sibling;
      default:
        return Relationship.other;
    }
  }

  /// Creates a new [RelationshipParameter] when the [value] is not null
  static RelationshipParameter? create(String name, Relationship? value) {
    if (value == null) {
      return null;
    }

    return RelationshipParameter.value(name, value);
  }
}

/// Defines the role of a given user
class ParticipantRoleParameter extends Parameter<Role> {
  /// Creates a new [ParticipantRoleParameter]
  ParticipantRoleParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [ParticipantRoleParameter]
  ParticipantRoleParameter.value(String name, Role role)
      : super(name, role.typeName ?? '', role);

  /// Gets the value
  Role get role => value;

  /// Parses the given [textValue]
  static Role parse(String textValue) {
    switch (textValue) {
      case 'CHAIR':
        return Role.chair;
      case 'REQ-PARTICIPANT':
        return Role.requiredParticipant;
      case 'OPT-PARTICIPANT':
        return Role.optionalParticipant;
      case 'NON-PARTICIPANT':
        return Role.nonParticipant;
      default:
        return Role.other;
    }
  }

  /// Creates a new [ParticipantRoleParameter] when the [value] is not null
  static ParticipantRoleParameter? create(String name, Role? value) {
    if (value == null) {
      return null;
    }

    return ParticipantRoleParameter.value(name, value);
  }
}

/// Defines the value type of the corresponding property.
///
/// With this mechanism a single property can have different value types.
class ValueParameter extends Parameter<ValueType> {
  /// Creates a new [ValueParameter]
  ValueParameter(String name, String textValue)
      : super(name, textValue, parse(textValue));

  /// Creates a new [ValueParameter]
  ValueParameter.value(String name, ValueType type)
      : super(name, type.typeName ?? '', type);

  /// Retrieves the value type
  ValueType get valueType => value;

  /// Parses the given [textValue]
  static ValueType parse(String textValue) {
    switch (textValue) {
      case 'BINARY':
        return ValueType.binary;
      case 'BOOLEAN':
        return ValueType.boolean;
      case 'CAL-ADDRESS':
        return ValueType.calendarAddress;
      case 'DATE':
        return ValueType.date;
      case 'DATE-TIME':
        return ValueType.dateTime;
      case 'DURATION':
        return ValueType.duration;
      case 'FLOAT':
        return ValueType.float;
      case 'INTEGER':
        return ValueType.integer;
      case 'PERIOD':
        return ValueType.period;
      case 'RECUR':
        return ValueType.recurrence;
      case 'TEXT':
        return ValueType.text;
      case 'TIME':
        return ValueType.time;
      case 'URI':
        return ValueType.uri;
      case 'UTC-OFFSET':
        return ValueType.utcOffset;
      default:
        return ValueType.other;
    }
  }

  /// Creates a new [ValueParameter] when the [value] is not null
  static ValueParameter? create(String name, ValueType? value) {
    if (value == null) {
      return null;
    }

    return ValueParameter.value(name, value);
  }
}

/// Common parameter types
enum ParameterType {
  /// `ALTREP` Alternate text representation [UriParameter]
  alternateRepresentation,

  /// `CN` common name [TextParameter]
  commonName,

  /// `CUTYPE` calendar user type [CalendarUserTypeParameter]
  calendarUserType,

  /// `DELEGATED-FROM` delegator [UriParameter]
  delegateFrom,

  /// `DELEGATED-TO` delegatee [UriParameter]
  delegateTo,

  /// `DIR` directory [UriParameter]
  directory,

  /// `ENCODING` inline encoding [TextParameter]
  encoding,

  /// `FMTTYPE` format type / media type / mime type, e.g. `text/plain` or `image/png`  [TextParameter]
  formatType,

  /// `FBTYPE` free busy time type [FreeBusyTimeTypeParameter]
  freeBusyTimeType,

  /// `LANGUAGE` language [TextParameter]
  language,

  /// `MEMBER` group or list membership [UriListParameter]
  member,

  /// `PARTSTAT` participant status - [ParticipantStatusParameter]
  participantStatus,

  /// `RANGE` recurrence identifier range [RangeParameter]
  range,

  /// `RELATED` alarm trigger relationship [AlarmTriggerRelationshipParameter]
  alarmTriggerRelationship,

  /// `RELTYPE` relationship type [RelationshipParameter]
  relationshipType,

  /// `ROLE` participant role [ParticipantRoleParameter]
  participantRole,

  /// `RSVP` répondez s'il vous plaît - answer is asked for [BooleanParameter]
  rsvp,

  /// `SENT-BY` sent by [UriParameter]
  sentBy,

  /// `TZID` reference to time zone object [TextParameter]
  timezoneId,

  /// `VALUE` property value data type, e.g. `BINARY` [ValueParameter]
  value,

  /// `X-FILENAME` parameter, used for attachments [TextParameter]
  xFilename,

  /// `EMAIL` parameter, used for attendees [TextParameter]
  email,

  /// Any other parameter type
  other,
}

/// Extends [ParameterType] with helpful functions
extension ExtensionParameterType on ParameterType {
  /// Retrieves the corresponding name
  String? get typeName {
    switch (this) {
      case ParameterType.alternateRepresentation:
        return 'ALTREP';
      case ParameterType.commonName:
        return 'CN';
      case ParameterType.calendarUserType:
        return 'CUTYPE';
      case ParameterType.delegateFrom:
        return 'DELEGATED-FROM';
      case ParameterType.delegateTo:
        return 'DELEGATED-TO';
      case ParameterType.directory:
        return 'DIR';
      case ParameterType.encoding:
        return 'ENCODING';
      case ParameterType.formatType:
        return 'FMTTYPE';
      case ParameterType.freeBusyTimeType:
        return 'FBTYPE';
      case ParameterType.language:
        return 'LANGUAGE';
      case ParameterType.member:
        return 'MEMBER';
      case ParameterType.participantStatus:
        return 'PARTSTAT';
      case ParameterType.range:
        return 'RANGE';
      case ParameterType.alarmTriggerRelationship:
        return 'RELATED';
      case ParameterType.relationshipType:
        return 'RELTYPE';
      case ParameterType.participantRole:
        return 'ROLE';
      case ParameterType.rsvp:
        return 'RSVP';
      case ParameterType.sentBy:
        return 'SENT-BY';
      case ParameterType.timezoneId:
        return 'TZID';
      case ParameterType.value:
        return 'VALUE';
      case ParameterType.xFilename:
        return 'X-FILENAME';
      case ParameterType.email:
        return 'EMAIL';
      case ParameterType.other:
        return null;
    }
  }
}
