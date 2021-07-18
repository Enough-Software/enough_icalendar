import 'dart:core';
import 'types.dart';
import 'util.dart';

/// Contains a property parameter
///
/// In contrast to properties, the type of a parameter is always predefined.
abstract class Parameter<T> {
  /// the standard type or ParameterType.other
  final ParameterType type;

  /// the name of this parameter
  final String name;

  /// the unparsed text value of this parameter
  final String textValue;

  /// The parsed value
  final T value;

  /// The type of the value
  final ValueType valueType;

  /// Creates a new parameter
  Parameter(this.type, this.name, this.textValue, this.valueType, this.value);

  /// Parses the given [definition] and generates a corresponding Parameter.
  static Parameter parse(String definition) {
    final splitIndex = definition.indexOf('=');
    if (splitIndex == -1) {
      throw FormatException(
          'No equals sign (=) found in parameter [$definition]');
    }
    final name = definition.substring(0, splitIndex);
    final textValue = definition.substring(splitIndex + 1);
    switch (name) {
      case 'ALTREP':
        return UriParameter(
            ParameterType.alternateRepresentation, name, textValue);
      case 'CN':
        return TextParameter(ParameterType.commonName, name, textValue);
      case 'CUTYPE':
        return CalendarUserTypeParameter(
            ParameterType.calendarUserType, name, textValue);
      case 'DELEGATED-FROM':
        return UriParameter(ParameterType.delegateFrom, name, textValue);
      case 'DELEGATED-TO':
        return UriParameter(ParameterType.delegateTo, name, textValue);
      case 'DIR':
        return UriParameter(ParameterType.directory, name, textValue);
      case 'ENCODING':
        return TextParameter(ParameterType.encoding, name, textValue);
      case 'FMTTYPE':
        return TextParameter(ParameterType.formatType, name, textValue);
      case 'FBTYPE':
        return FreeBusyTimeTypeParameter(
            ParameterType.freeBusyTimeType, name, textValue);
      case 'LANGUAGE':
        return TextParameter(ParameterType.language, name, textValue);
      case 'MEMBER':
        return UriListParameter(ParameterType.member, name, textValue);
      case 'PARTSTAT':
        return ParticipantStatusParameter(
            ParameterType.participantStatus, name, textValue);
      case 'RANGE':
        return RangeParameter(ParameterType.range, name, textValue);
      case 'RELATED':
        return AlarmTriggerRelationshipParameter(
            ParameterType.alarmTriggerRelationship, name, textValue);
      case 'RELTYPE':
        return RelationshipParameter(
            ParameterType.relationshipType, name, textValue);
      case 'ROLE':
        return ParticipantRoleParameter(
            ParameterType.participantRole, name, textValue);
      case 'RSVP':
        return BooleanParameter(ParameterType.rsvp, name, textValue);
      case 'SENT-BY':
        return UriParameter(ParameterType.sentBy, name, textValue);
      case 'TZID':
        return TextParameter(ParameterType.timezoneId, name, textValue);
      case 'VALUE':
        return ValueParameter(ParameterType.value, name, textValue);
      default:
        print('Encountered unsupported parameter [$name]');
        return TextParameter(ParameterType.other, name, textValue);
    }
  }
}

/// Parameter that contain an URI like `ALTREP`
class UriParameter extends Parameter<Uri> {
  /// Retrieves the value as Uri
  Uri get uri => value;

  UriParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.uri, parse(textValue));

  UriParameter.value(ParameterType type, Uri value)
      : super(type, type.name!, '"$value"', ValueType.uri, value);

  static Uri parse(String textValue) {
    if (textValue.startsWith('"')) {
      textValue = textValue.substring(1, textValue.length - 1);
    }
    return Uri.parse(textValue);
  }
}

/// Parameter or value that contains one or several URIs like `MEMBER`
class UriListParameter extends Parameter<List<Uri>> {
  /// Retrieves the value as Uri
  List<Uri> get uris => value;

  UriListParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeUriList, parse(textValue));

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
}

/// Parameter containing text
class TextParameter extends Parameter<String> {
  String get text => value;

  TextParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.text, parse(textValue));

  TextParameter.value(ParameterType type, String value)
      : super(type, type.name!, value, ValueType.text, value);

  static String parse(String textValue) {
    if (textValue.startsWith('"')) {
      textValue = textValue.substring(1, textValue.length - 1);
    }
    return textValue;
  }
}

/// Parameter containing boolean values
class BooleanParameter extends Parameter<bool> {
  bool get boolValue => value;

  BooleanParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.boolean, parse(textValue));
  BooleanParameter.value(ParameterType type, bool value)
      : super(type, type.name!, value ? 'TRUE' : 'FALSE', ValueType.boolean,
            value);

  static bool parse(String textValue) {
    return (textValue == 'TRUE' || textValue == 'YES');
  }
}

/// Parameter defining the type of calendar user
class CalendarUserTypeParameter extends Parameter<CalendarUserType> {
  CalendarUserTypeParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.other, parse(textValue));
  CalendarUserTypeParameter.value(CalendarUserType value)
      : super(
            ParameterType.calendarUserType,
            ParameterType.calendarUserType.name!,
            value.name!,
            ValueType.other,
            value);

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
}

/// Parameter defining the status of a free busy property
class FreeBusyTimeTypeParameter extends Parameter<FreeBusyTimeType> {
  FreeBusyTimeType get timeType => value;

  FreeBusyTimeTypeParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeFreeBusy, parse(textValue));

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
}

/// Parameter definining the participant status
class ParticipantStatusParameter extends Parameter<ParticipantStatus> {
  ParticipantStatus get status => value;

  ParticipantStatusParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeParticipantStatus,
            parse(textValue));
  ParticipantStatusParameter.value(ParticipantStatus status)
      : super(
            ParameterType.participantStatus,
            ParameterType.participantStatus.name!,
            status.name!,
            ValueType.typeParticipantStatus,
            status);

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
  Range get range => value;
  bool get isThisAndFuture => range == Range.thisAndFuture;

  RangeParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeRange, parse(textValue));

  static Range parse(String textValue) {
    switch (textValue) {
      case 'THISANDFUTURE':
        return Range.thisAndFuture;
      default:
        throw FormatException('Invalid range: [$textValue]');
    }
  }
}

/// Specifies the relationship of the alarm trigger with respect to the start or end of the calendar component.
///
/// Example is the `RELATED` parameter.
class AlarmTriggerRelationshipParameter
    extends Parameter<AlarmTriggerRelationship> {
  AlarmTriggerRelationship get relationship => value;

  AlarmTriggerRelationshipParameter(
      ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeAlarmTriggerRelationship,
            parse(textValue));
  AlarmTriggerRelationshipParameter.value(AlarmTriggerRelationship relation)
      : super(
            ParameterType.alarmTriggerRelationship,
            ParameterType.alarmTriggerRelationship.name!,
            relation.name!,
            ValueType.typeAlarmTriggerRelationship,
            relation);

  static AlarmTriggerRelationship parse(String textValue) {
    switch (textValue) {
      case 'START':
        return AlarmTriggerRelationship.start;
      case 'END':
        return AlarmTriggerRelationship.end;
    }
    throw FormatException('Invalid RELATED content [$textValue]');
  }
}

/// Defines the relationship of the parameter's property
class RelationshipParameter extends Parameter<Relationship> {
  Relationship get relationship => value;

  RelationshipParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeRelationship,
            parse(textValue));

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
}

/// Defines the role of a given user
class ParticipantRoleParameter extends Parameter<Role> {
  Role get role => value;

  ParticipantRoleParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeRole, parse(textValue));

  ParticipantRoleParameter.value(Role role)
      : super(
            ParameterType.participantRole,
            ParameterType.participantRole.name!,
            role.name!,
            ValueType.typeRole,
            role);

  static Role parse(String content) {
    switch (content) {
      case 'CHAIR':
        return Role.chair;
      case 'REQ-PARTICIPANT':
        return Role.requiredParticipant;
      case 'OPT-PARTICIPANT':
        return Role.optionalParticipant;
      case 'NON-PARTICIPANT':
        return Role.nonParticpant;
      default:
        return Role.other;
    }
  }
}

/// Defines the value type of the corresponding property.
///
/// With this mechanism a single property can have different value types.
class ValueParameter extends Parameter<ValueType> {
  ValueType get valueType => value;

  ValueParameter(ParameterType type, String name, String textValue)
      : super(type, name, textValue, ValueType.typeValue, parse(textValue));

  static ValueType parse(String content) {
    switch (content) {
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

  /// `DELEGATED-TO` delgatee [UriParameter]
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

  /// Any other parameter type
  other,
}

extension ExtensionParameterType on ParameterType {
  String? get name {
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
      case ParameterType.other:
        return null;
    }
  }
}
