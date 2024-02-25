import 'parameters.dart';
import 'types.dart';
import 'util.dart';

/// Defines an iCalendar property
class Property {
  /// Creates a new [Property]
  Property(
    this.definition,
    ValueType defaultValueType, {
    dynamic Function(Property property, String textValue)? parser,
  })  : name = _getName(definition),
        textValue = _getTextContent(definition),
        parameters = _parseParameters(definition) {
    value = parser != null
        ? parser(this, textValue)
        : _parsePropertyValue(this, defaultValueType);
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

  /// Parses this property.
  ///
  /// The default implementation does not support parsing and
  /// throws a [FormatException]
  dynamic parse(String textValue) {
    throw FormatException(
      'Implement parse to allow custom value in property: $definition',
    );
  }

  /// Retrieves the parameter with the given [type]
  Parameter? operator [](ParameterType type) => parameters[type.typeName];

  /// Sets the parameter [value] for the given [type]
  void operator []=(ParameterType type, Parameter value) =>
      parameters[value.name] = value;

  /// Sets the parameter [value]
  void setParameter(Parameter value) => parameters[value.name] = value;

  /// Sets the parameter when [value] is not null
  /// and removes the parameter when [value] is null.
  void setOrRemoveParameter(ParameterType type, Parameter? value) {
    if (value == null) {
      parameters.remove(type.typeName);
    } else {
      parameters[type.typeName ?? ''] = value;
    }
  }

  /// Retrieves the parameter value for [type]
  T? getParameterValue<T>(ParameterType type) =>
      parameters[type.typeName]?.value as T?;

  static String? _lastContent;
  static List<int>? _lastRunes;
  static int _getNameEndIndex(String content) => _getIndex(content);
  static int _getValueStartIndex(String content) =>
      _getIndex(content, searchNameEndIndex: false);

  static int _getIndex(String content, {bool searchNameEndIndex = true}) {
    final lastRunes = _lastRunes;
    final runes = content == _lastContent && lastRunes != null
        ? lastRunes
        : content.runes.toList();
    var isInQuote = false;
    var isLastBackSlash = false;
    int? index;
    for (var i = 0; i < runes.length; i++) {
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
    for (var i = startIndex; i < runes.length; i++) {
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
    Property property,
    ValueType defaultValueType,
  ) {
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
        return UriParameter.parse(textValue);
      case ValueType.date:
        return DateHelper.parseDate(textValue);
      case ValueType.dateTime:
        return DateHelper.parseDateTime(textValue);
      case ValueType.duration:
        return IsoDuration.parse(textValue);
      case ValueType.float:
        return double.parse(textValue);
      case ValueType.integer:
        return int.parse(textValue);
      case ValueType.period:
        return Period.parse(textValue);
      case ValueType.periodList:
        return textValue.split(',').map(Period.parse).toList();
      case ValueType.recurrence:
        return Recurrence.parse(textValue);
      case ValueType.text:
        return TextProperty.parseText(textValue);
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
      case TextProperty.propertyNameXTimezoneLocation:
      case TextProperty.propertyNameXCalendarName:
      case TextProperty.propertyNameXMicrosoftSkypeTeamsMeetingUrl:
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
      case BooleanProperty.propertyNameAllDayEvent:
        return BooleanProperty(definition);
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
      case MethodProperty.propertyName:
        return MethodProperty(definition);
      case RequestStatusProperty.propertyName:
        return RequestStatusProperty(definition);
      case EventBusyStatusProperty.propertyName:
        return EventBusyStatusProperty(definition);
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

  /// Renders this parameter into the given [buffer] without folding / wrapping lines and without `CRLF` at the end.
  void render(final StringBuffer buffer) {
    buffer.write(name);
    if (parameters.isNotEmpty) {
      for (final parameter in parameters.values) {
        buffer
          ..write(';')
          ..write(parameter.name)
          ..write('=')
          ..write(parameter.textValue);
      }
    }
    buffer
      ..write(':')
      ..write(textValue);
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    render(buffer);
    if (buffer.length > 72) {
      // wrap parameter:
      final definition = buffer.toString();
      final wrappedBuffer = StringBuffer();
      var startIndex = 72;
      wrappedBuffer
        ..write(definition.substring(0, startIndex))
        ..write('\r\n');
      while (startIndex < definition.length - 73) {
        wrappedBuffer
          ..write(' ')
          ..write(definition.substring(startIndex, startIndex + 71))
          ..write('\r\n');
        startIndex += 71;
      }
      if (startIndex < definition.length) {
        wrappedBuffer
          ..write(' ')
          ..write(definition.substring(startIndex))
          ..write('\r\n');
      }
      buffer = wrappedBuffer;
    } else {
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) => other.toString() == toString();

  /// Creates a copy of this property
  Property copy() {
    final buffer = StringBuffer();
    render(buffer);
    return Property.parseProperty(buffer.toString());
  }
}

class RecurrenceRuleProperty extends Property {
  RecurrenceRuleProperty(String definition)
      : super(definition, ValueType.other);

  /// `RRULE`
  static const String propertyName = 'RRULE';
  Recurrence get rule => value as Recurrence;

  @override
  Recurrence parse(String texValue) => Recurrence.parse(textValue);

  static RecurrenceRuleProperty? create(Recurrence? value) {
    if (value == null) {
      return null;
    }

    return RecurrenceRuleProperty('$propertyName:$value');
  }
}

class UriProperty extends Property {
  UriProperty(String definition) : super(definition, ValueType.uri);

  /// `TZURL`
  static const String propertyNameTimezoneUrl = 'TZURL';

  /// `URL`
  static const String propertyNameUrl = 'URL';

  Uri get uri => value as Uri;

  static UriProperty? create(String propertyName, Uri? value) {
    if (value == null) {
      return null;
    }
    return UriProperty('$propertyName:$value');
  }
}

class UserProperty extends UriProperty {
  UserProperty(super.definition);

  /// `CONTACT`
  static const String propertyNameContact = 'CONTACT';

  /// Gets the common name associated with this calendar user
  String? get commonName => getParameterValue<String>(ParameterType.commonName);

  /// Sets the common name associated with this calendar user
  set commonName(String? value) => setOrRemoveParameter(
        ParameterType.commonName,
        TextParameter.create(ParameterType.commonName.typeName ?? '', value),
      );

  /// Gets the directory link, for example an LDAP URI
  Uri? get directory => getParameterValue<Uri>(ParameterType.directory);

  /// Sets the directory
  set directory(Uri? value) => setOrRemoveParameter(
        ParameterType.directory,
        UriParameter.create(ParameterType.directory.typeName ?? '', value),
      );

  /// Gets the alternative representation, e.g. a link to a VCARD
  Uri? get alternateRepresentation =>
      getParameterValue<Uri>(ParameterType.alternateRepresentation);

  /// Sets the alternative representation
  set alternateRepresentation(Uri? value) => setOrRemoveParameter(
        ParameterType.alternateRepresentation,
        UriParameter.create(
          ParameterType.alternateRepresentation.typeName ?? '',
          value,
        ),
      );

  /// Retrieves the type of the user.
  ///
  /// Defaults to [CalendarUserType.unknown].
  CalendarUserType get userType =>
      getParameterValue<CalendarUserType>(ParameterType.calendarUserType) ??
      CalendarUserType.unknown;

  /// Set the type of the user
  set userType(CalendarUserType? value) => setOrRemoveParameter(
        ParameterType.calendarUserType,
        CalendarUserTypeParameter.create(
          ParameterType.calendarUserType.typeName ?? '',
          value,
        ),
      );

  /// Retrieve the email from this value
  String? get email => uri.isScheme('MAILTO')
      ? uri.path
      : getParameterValue<String>(ParameterType.email);

  /// Sets the email as an additional parameter
  set email(String? value) => setOrRemoveParameter(
        ParameterType.email,
        TextParameter.create(ParameterType.email.typeName ?? '', value),
      );
}

/// Describes an attendee
class AttendeeProperty extends UserProperty {
  /// Creates a new [AttendeeProperty]
  AttendeeProperty(super.definition);

  /// `ATTENDEE`
  static const String propertyName = 'ATTENDEE';

  /// Gets the URI of the attendee, e.g. `Uri.parse('mailto:a@example.com')`
  Uri get attendee => uri;

  /// Checks if an answer is expected.
  ///
  /// Stands for "Répondez s'il vous plaît", meaning "Please respond".
  bool get rsvp => getParameterValue<bool>(ParameterType.rsvp) ?? false;

  /// Sets the rsvp request value
  set rsvp(bool? value) => setOrRemoveParameter(
        ParameterType.rsvp,
        BooleanParameter.create(ParameterType.rsvp.typeName ?? '', value),
      );

  /// Gets the role of this participant, defaults to [Role.requiredParticipant]
  Role get role =>
      getParameterValue<Role>(ParameterType.participantRole) ??
      Role.requiredParticipant;

  /// Sets the role of this participant
  set role(Role? value) => setOrRemoveParameter(
        ParameterType.participantRole,
        ParticipantRoleParameter.create(
          ParameterType.participantRole.typeName ?? '',
          value,
        ),
      );

  /// Gets the participant status of this attendee
  ///
  /// The possible values depend on the type of the component.
  ParticipantStatus? get participantStatus =>
      getParameterValue<ParticipantStatus>(ParameterType.participantStatus);

  /// Sets the participant status
  set participantStatus(ParticipantStatus? value) => setOrRemoveParameter(
        ParameterType.participantStatus,
        ParticipantStatusParameter.create(
          ParameterType.participantStatus.typeName ?? '',
          value,
        ),
      );

  /// Retrieves the URI of the the user that this attendee has delegated the
  /// event or task to
  Uri? get delegatedTo => getParameterValue<Uri>(ParameterType.delegateTo);

  /// Sets the delegatedTo URI
  set delegatedTo(Uri? value) => setOrRemoveParameter(
        ParameterType.delegateTo,
        UriParameter.create(ParameterType.delegateTo.typeName ?? '', value),
      );

  /// Retrieves the email of the the user that this attendee has delegated the
  /// event or task to
  String? get delegatedToEmail {
    final uri = delegatedTo;
    if (uri == null || !uri.isScheme('MAILTO')) {
      return null;
    }

    return uri.path;
  }

  /// Sets the delegatedToEmail, will generate a delegatedToUri
  set delegatedToEmail(String? value) =>
      delegatedTo = value == null ? null : Uri.parse('mailto:$value');

  /// Retrieves the URI of the the user that this attendee has delegated the
  /// event or task from
  Uri? get delegatedFrom => getParameterValue<Uri>(ParameterType.delegateFrom);

  /// Sets the delegatedFrom URI
  set delegatedFrom(Uri? value) => setOrRemoveParameter(
        ParameterType.delegateFrom,
        UriParameter.create(ParameterType.delegateTo.typeName ?? '', value),
      );

  /// Retrieves the email of the the user that this attendee has delegated the
  /// event or task from
  String? get delegatedFromEmail {
    final uri = delegatedFrom;
    if (uri == null || !uri.isScheme('MAILTO')) {
      return null;
    }
    return uri.path;
  }

  /// Sets the delegatedFromEmail, will generate a delegatedFromUri
  set delegatedFromEmail(String? value) =>
      delegatedFrom = value == null ? null : Uri.parse('mailto:$value');

  /// Creates an attendee with the specified [attendeeUri] or [attendeeEmail].
  ///
  /// Any other parameters are optional.
  static AttendeeProperty? create({
    Uri? attendeeUri,
    String? attendeeEmail,
    ParticipantStatus? participantStatus,
    Uri? delegatedToUri,
    String? delegatedToEmail,
    Uri? delegatedFromUri,
    String? delegatedFromEmail,
    Role? role,
    bool? rsvp,
    CalendarUserType? userType,
    String? commonName,
    Uri? alternateRepresentation,
    Uri? directory,
  }) {
    if (attendeeEmail == null && attendeeUri == null) {
      return null;
    }
    attendeeUri ??= Uri.parse('mailto:$attendeeEmail');
    final prop = AttendeeProperty('$propertyName:$attendeeUri');
    if (participantStatus != null) {
      prop[ParameterType.participantStatus] = ParticipantStatusParameter.value(
        ParameterType.participantStatus.typeName ?? '',
        participantStatus,
      );
    }
    if (delegatedToEmail != null) {
      delegatedToUri = Uri.parse('mailto:$delegatedToEmail');
    }
    if (delegatedToUri != null) {
      prop[ParameterType.delegateTo] = UriParameter.value(
        ParameterType.delegateTo.typeName ?? '',
        delegatedToUri,
      );
    }
    if (delegatedFromEmail != null) {
      delegatedFromUri = Uri.parse('mailto:$delegatedFromEmail');
    }
    if (delegatedFromUri != null) {
      prop[ParameterType.delegateFrom] = UriParameter.value(
        ParameterType.delegateFrom.typeName ?? '',
        delegatedFromUri,
      );
    }
    if (role != null) {
      prop[ParameterType.participantRole] = ParticipantRoleParameter.value(
        ParameterType.participantRole.typeName ?? '',
        role,
      );
    }
    if (rsvp != null) {
      prop[ParameterType.rsvp] =
          BooleanParameter.value(ParameterType.rsvp.typeName ?? '', rsvp);
    }
    if (userType != null) {
      prop[ParameterType.calendarUserType] = CalendarUserTypeParameter.value(
        ParameterType.calendarUserType.typeName ?? '',
        userType,
      );
    }
    if (commonName != null) {
      prop[ParameterType.commonName] = TextParameter.value(
        ParameterType.commonName.typeName ?? '',
        commonName,
      );
    }
    if (alternateRepresentation != null) {
      prop[ParameterType.alternateRepresentation] = UriParameter.value(
        ParameterType.alternateRepresentation.typeName ?? '',
        alternateRepresentation,
      );
    }
    if (directory != null) {
      prop[ParameterType.directory] =
          UriParameter.value(ParameterType.directory.typeName ?? '', directory);
    }

    return prop;
  }
}

/// Defines the organizer of a meeting
class OrganizerProperty extends UserProperty {
  /// Creates a new [OrganizerProperty]
  OrganizerProperty(super.definition);

  /// `ORGANIZER`
  static const String propertyName = 'ORGANIZER';

  /// Retrieves the link to the organizer, e.g. a mailto-link
  Uri get organizer => uri;

  /// Gets the sender of this organizer
  Uri? get sentBy => getParameterValue<Uri>(ParameterType.sentBy);

  /// Sets the sender of this organizer
  set sentBy(Uri? value) => setOrRemoveParameter(
        ParameterType.sentBy,
        UriParameter.create(ParameterType.sentBy.typeName ?? '', value),
      );

  /// Creates a new [OrganizerProperty]
  static OrganizerProperty? create({
    String? email,
    Uri? uri,
    Uri? sentBy,
    String? sentByEmail,
    String? commonName,
  }) {
    if (email == null && uri == null) {
      return null;
    }
    uri ??= Uri.parse('mailto:$email');
    final prop = OrganizerProperty('$propertyName:$uri');
    if (sentByEmail != null) {
      sentBy = Uri.parse('mailto:$sentByEmail');
    }
    if (sentBy != null) {
      prop[ParameterType.sentBy] =
          UriParameter.value(ParameterType.sentBy.typeName ?? '', sentBy);
    }
    if (commonName != null) {
      prop.commonName = commonName;
    }

    return prop;
  }
}

/// Defines a geo position
class GeoProperty extends Property {
  /// Creates a new [GeoProperty]
  GeoProperty(String definition) : super(definition, ValueType.other);

  /// Creates a new [GeoProperty] based on the given [location]
  GeoProperty.value(GeoLocation location)
      : this('GEO:${location.latitude};${location.longitude}');

  /// `GEO`
  static const String propertyName = 'GEO';

  /// Retrieves the geo location
  GeoLocation get location => value as GeoLocation;

  /// Pareses the given textual representation
  @override
  GeoLocation parse(String content) {
    final semicolonIndex = content.indexOf(';');
    if (semicolonIndex == -1) {
      throw FormatException('Invalid GEO property $content');
    }
    final latitudeText = content.substring(0, semicolonIndex);
    final latitude = double.tryParse(latitudeText);
    if (latitude == null) {
      throw FormatException(
        'Invalid GEO property - unable to parse latitude value '
        '$latitudeText in  $content',
      );
    }
    final longitudeText = content.substring(semicolonIndex + 1);
    final longitude = double.tryParse(longitudeText);
    if (longitude == null) {
      throw FormatException(
        'Invalid GEO property - unable to parse longitude value '
        '$longitudeText in  $content',
      );
    }

    return GeoLocation(latitude, longitude);
  }

  /// Creates a new [GeoProperty]
  static GeoProperty? create(GeoLocation? value) {
    if (value == null) {
      return null;
    }

    return GeoProperty('$propertyName:$value');
  }
}

class AttachmentProperty extends Property {
  AttachmentProperty(String content) : super(content, ValueType.uri);

  /// `ATTACH`
  static const String propertyName = 'ATTACH';

  /// Retrieves the URI of the data such as `https://domain.com/assets/image.png`
  Uri? get uri => value is Uri ? value : null;

  /// Retrieves the binary data information
  Binary? get binary => value is Binary ? value : null;

  /// Retrieves the mime type / media type / format type like `image/png` as specified in the `FMTTYPE` parameter.
  String? get mediaType => getParameterValue<String>(ParameterType.formatType);

  /// Sets the media type
  set mediaType(String? value) => setOrRemoveParameter(ParameterType.formatType,
      TextParameter.create(ParameterType.formatType.typeName ?? '', value));

  /// Retrieves the encoding such as `BASE64`, only relevant when the content is binary
  ///
  /// Compare [isBinary]
  String? get encoding => getParameterValue<String>(ParameterType.encoding);

  /// Sets the encoding
  set encoding(String? value) => setOrRemoveParameter(
        ParameterType.encoding,
        TextParameter.create(ParameterType.encoding.typeName ?? '', value),
      );

  /// Retrieves the mime type / media type / format type like `image/png` as specified in the `FMTTYPE` parameter.
  String? get filename => getParameterValue<String>(ParameterType.xFilename);

  /// Sets the media type
  set filename(String? value) => setOrRemoveParameter(
        ParameterType.xFilename,
        TextParameter.create(ParameterType.xFilename.typeName ?? '', value),
      );

  /// Checks if this contains binary data
  ///
  /// Compare [binary]
  bool get isBinary => value is Binary;
}

class CalendarScaleProperty extends Property {
  CalendarScaleProperty(String definition) : super(definition, ValueType.text);

  /// `CALSCALE`
  static const String propertyName = 'CALSCALE';
  bool get isGregorianCalendar => textValue == 'GREGORIAN';

  static CalendarScaleProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return CalendarScaleProperty('$propertyName:$value');
  }
}

class VersionProperty extends Property {
  VersionProperty(String definition) : super(definition, ValueType.text);

  /// `VERSION`
  static const String propertyName = 'VERSION';

  bool get isVersion2 => textValue == '2.0';

  static VersionProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return VersionProperty('$propertyName:$value');
  }
}

class CategoriesProperty extends Property {
  CategoriesProperty(String definition) : super(definition, ValueType.text);

  /// `CATEGORIES`
  static const String propertyName = 'CATEGORIES';

  List<String> get categories => textValue.split(',');

  static CategoriesProperty? create(List<String>? value) {
    if (value == null) {
      return null;
    }
    final containsComma = value.any((t) => t.contains(','));
    if (containsComma) {
      value = value.map((t) => '"$t"').toList();
    }
    final text = value.join(',');
    return CategoriesProperty('$propertyName:$text');
  }
}

class ClassificationProperty extends Property {
  ClassificationProperty(String definition)
      : super(definition, ValueType.typeClassification);

  /// `CLASS`
  static const String propertyName = 'CLASS';

  Classification get classification => value as Classification;

  static ClassificationProperty? create(Classification? value) {
    if (value == null) {
      return null;
    }
    if (value == Classification.other) {
      throw FormatException(
          'Unknown classification / CLASS value $value. You can set a custom value with a TextProperty.');
    }
    return ClassificationProperty('$propertyName:${value.name}');
  }
}

/// Contains texts
class TextProperty extends Property {
  TextProperty(String definition) : super(definition, ValueType.text);

  /// `COMMENT`
  static const String propertyNameComment = 'COMMENT';

  /// `DESCRIPTION`
  static const String propertyNameDescription = 'DESCRIPTION';

  /// `PRODID`
  static const String propertyNameProductIdentifier = 'PRODID';

  /// `SUMMARY`
  static const String propertyNameSummary = 'SUMMARY';

  /// `LOCATION`
  static const String propertyNameLocation = 'LOCATION';

  /// `RESOURCES`
  static const String propertyNameResources = 'RESOURCES';

  /// `UID`
  static const String propertyNameUid = 'UID';

  /// `X-WR-TIMEZONE`
  static const String propertyNameXWrTimezone = 'X-WR-TIMEZONE';

  /// `TZID`
  static const String propertyNameTimezoneId = 'TZID';

  /// `TZNAME`
  static const String propertyNameTimezoneName = 'TZNAME';

  /// `RELATED-TO`
  static const String propertyNameRelatedTo = 'RELATED-TO';

  /// `X-LIC-LOCATION`, often the same as the `TZID`
  static const String propertyNameXTimezoneLocation = 'X-LIC-LOCATION';

  /// `X-WR-CALNAME` calendar name property
  static const String propertyNameXCalendarName = 'X-WR-CALNAME';

  /// `X-MICROSOFT-SKYPETEAMSMEETINGURL` meeting URL property
  static const String propertyNameXMicrosoftSkypeTeamsMeetingUrl =
      'X-MICROSOFT-SKYPETEAMSMEETINGURL';

  /// Retrieve the language
  String? get language => this[ParameterType.language]?.textValue;

  /// Sets the language
  set language(String? value) => setOrRemoveParameter(
        ParameterType.language,
        TextParameter.create(ParameterType.language.typeName ?? '', value),
      );

  /// Gets a link to an alternative representation
  Uri? get alternateRepresentation =>
      (this[ParameterType.alternateRepresentation] as UriParameter?)?.uri;

  /// Sets a link to an alternative representation
  set alternateRepresentation(Uri? value) => setOrRemoveParameter(
        ParameterType.alternateRepresentation,
        UriParameter.create(
            ParameterType.alternateRepresentation.typeName ?? '', value),
      );

  String get text => value as String;

  static TextProperty? create(String name, String? value,
      {String? language, Uri? alternateRepresentation}) {
    if (value == null) {
      return null;
    }
    value = value.replaceAll(',', '\\,');
    value = value.replaceAll('\n', '\\n');
    final prop = TextProperty('$name:$value');
    if (language != null) {
      prop.setParameter(
        TextParameter.value(ParameterType.language.typeName ?? '', language),
      );
    }
    if (alternateRepresentation != null) {
      prop.setParameter(
        UriParameter.value(
          ParameterType.alternateRepresentation.typeName ?? '',
          alternateRepresentation,
        ),
      );
    }
    return prop;
  }

  static String parseText(String textValue) {
    textValue = textValue.replaceAll('\\,', ',');
    textValue = textValue.replaceAll('\\n', '\n');
    return textValue;
  }
}

class MethodProperty extends Property {
  MethodProperty(String definition)
      : super(definition, ValueType.text, parser: _parse);

  /// `METHOD`
  static const String propertyName = 'METHOD';

  /// Retrieves the method
  Method get method => value as Method;

  static Method _parse(final Property property, final String textValue) {
    switch (textValue) {
      case 'PUBLISH':
        return Method.publish;
      case 'REQUEST':
        return Method.request;
      case 'REPLY':
        return Method.reply;
      case 'ADD':
        return Method.add;
      case 'CANCEL':
        return Method.cancel;
      case 'REFRESH':
        return Method.refresh;
      case 'COUNTER':
        return Method.counter;
      case 'DECLINECOUNTER':
        return Method.declineCounter;
      default:
        throw FormatException(
            'Unknown method value [$textValue] in property $property');
    }
  }

  /// Creates a new property with the specified value
  static MethodProperty? create(Method? method) {
    if (method == null) {
      return null;
    }
    return MethodProperty('$propertyName:${method.name}');
  }
}

class IntegerProperty extends Property {
  IntegerProperty(String definition) : super(definition, ValueType.integer);

  /// `PERCENT-COMPLETE`
  static const String propertyNamePercentComplete = 'PERCENT-COMPLETE';

  /// `SEQUENCE`
  static const String propertyNameSequence = 'SEQUENCE';

  /// `REPEAT`
  static const String propertyNameRepeat = 'REPEAT';

  int get intValue => value as int;

  static IntegerProperty? create(String name, int? value) {
    if (value == null) {
      return null;
    }
    return IntegerProperty('$name:$value');
  }
}

class BooleanProperty extends Property {
  BooleanProperty(String definition) : super(definition, ValueType.boolean);

  /// `X-MICROSOFT-CDO-ALLDAYEVENT`
  static const String propertyNameAllDayEvent = 'X-MICROSOFT-CDO-ALLDAYEVENT';

  bool get boolValue => value as bool;

  static BooleanProperty? create(String name, bool? value) {
    if (value == null) {
      return null;
    }
    return BooleanProperty('$name:${value ? 'TRUE' : 'FALSE'}');
  }
}

class DateTimeProperty extends Property {
  DateTimeProperty(String definition) : super(definition, ValueType.dateTime);

  /// `COMPLETED`
  static const String propertyNameCompleted = 'COMPLETED';

  /// `DTEND`
  static const String propertyNameEnd = 'DTEND';

  /// `DTSTART`
  static const String propertyNameStart = 'DTSTART';

  /// `DUE`
  static const String propertyNameDue = 'DUE';

  /// `DTSTAMP`
  static const String propertyNameTimeStamp = 'DTSTAMP';

  /// `CREATED`
  static const String propertyNameCreated = 'CREATED';

  /// `LAST-MODIFIED`
  static const String propertyNameLastModified = 'LAST-MODIFIED';

  /// `RECURRENCE-ID`
  static const String propertyNameRecurrenceId = 'RECURRENCE-ID';

  DateTime get dateTime => value as DateTime;

  /// Retrieves the timezone ID like `America/New_York` or `Europe/Berlin` from the `TZID` parameter.
  String? get timezoneId => this[ParameterType.timezoneId]?.textValue;

  /// Set the timezone ID
  set timezoneId(String? value) => setOrRemoveParameter(
        ParameterType.timezoneId,
        TextParameter.create(ParameterType.timezoneId.typeName ?? '', value),
      );

  static DateTimeProperty? create(
    String name,
    DateTime? value, {
    String? timeZoneId,
  }) {
    if (value == null) {
      return null;
    }
    final prop =
        DateTimeProperty('$name:${DateHelper.toDateTimeString(value)}');
    if (timeZoneId != null) {
      prop[ParameterType.timezoneId] = TextParameter.value(
        ParameterType.timezoneId.typeName ?? '',
        timeZoneId,
      );
    }
    return prop;
  }
}

class DurationProperty extends Property {
  DurationProperty(String definition) : super(definition, ValueType.duration);

  /// `DURATION`
  static const String propertyName = 'DURATION';

  IsoDuration get duration => value as IsoDuration;

  static DurationProperty? create(IsoDuration? value) {
    if (value == null) {
      return null;
    }
    return DurationProperty('$propertyName:$value');
  }
}

class PeriodProperty extends Property {
  PeriodProperty(String definition) : super(definition, ValueType.period);
  //static const String propertyNameFreeBusy = 'FREEBUSY';

  Period get period => value as Period;
}

class UtfOffsetProperty extends Property {
  UtfOffsetProperty(String definition) : super(definition, ValueType.utcOffset);

  /// `TZOFFSETFROM`
  static const String propertyNameTimezoneOffsetFrom = 'TZOFFSETFROM';

  /// `TZOFFSETTO`
  static const String propertyNameTimezoneOffsetTo = 'TZOFFSETTO';

  UtcOffset get offset => value as UtcOffset;

  static UtfOffsetProperty? create(String propertyName, UtcOffset? value) {
    if (value == null) {
      return null;
    }
    return UtfOffsetProperty('$propertyName:$value');
  }
}

class FreeBusyProperty extends Property {
  FreeBusyProperty(String definition) : super(definition, ValueType.periodList);

  /// `FREEBUSY`
  static const String propertyName = 'FREEBUSY';

  /// Gets the type, defaults to [FreeBusyTimeType.busy]
  FreeBusyTimeType get freeBusyType =>
      getParameterValue<FreeBusyTimeType>(ParameterType.freeBusyTimeType) ??
      FreeBusyTimeType.busy;

  /// Sets the type
  set freeBusyType(FreeBusyTimeType? value) => setOrRemoveParameter(
        ParameterType.freeBusyTimeType,
        FreeBusyTimeTypeParameter.create(
          ParameterType.freeBusyTimeType.typeName ?? '',
          value,
        ),
      );

  List<Period> get periods => value as List<Period>;
}

class PriorityProperty extends IntegerProperty {
  PriorityProperty(super.definition);

  /// `PRIORITY`
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

  static PriorityProperty? createNumeric(int? value) {
    if (value == null) {
      return null;
    }
    return PriorityProperty('$propertyName:$value');
  }

  static PriorityProperty? createPriority(Priority? value) =>
      createNumeric(value?.numericValue);
}

class StatusProperty extends TextProperty {
  StatusProperty(super.definition);

  /// `STATUS`
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

  static StatusProperty? createEventStatus(EventStatus? value) {
    if (value == null || value == EventStatus.unknown) {
      return null;
    }
    return StatusProperty('$propertyName:${value.name}');
  }

  static StatusProperty? createTodoStatus(TodoStatus? value) {
    if (value == null || value == TodoStatus.unknown) {
      return null;
    }
    return StatusProperty('$propertyName:${value.name}');
  }

  static StatusProperty? createJournalStatus(JournalStatus? value) {
    if (value == null || value == JournalStatus.unknown) {
      return null;
    }
    return StatusProperty('$propertyName:${value.name}');
  }
}

/// This property defines whether or not an event is transparent to busy time searches.
class TimeTransparencyProperty extends TextProperty {
  TimeTransparencyProperty(super.definition);

  /// `TRANSP`
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

  static TimeTransparencyProperty? create(TimeTransparency? value) {
    if (value == null) {
      return null;
    }
    return TimeTransparencyProperty('$propertyName:${value.name}');
  }
}

class RecurrenceDateProperty extends Property {
  RecurrenceDateProperty(String definition)
      : super(definition, ValueType.typeDateTimeList);

  /// `RDATE`
  static const String propertyNameRDate = 'RDATE';

  /// `EXDATE`
  static const String propertyNameExDate = 'EXDATE';

  List<DateTimeOrDuration> get dates => value as List<DateTimeOrDuration>;

  static RecurrenceDateProperty? create(
      String propertyName, List<DateTimeOrDuration>? value) {
    if (value == null) {
      return null;
    }
    if (value.isEmpty) {
      throw FormatException('Unable to set empty $propertyName');
    }
    if (value.first.duration != null) {
      propertyName += ';VALUE=DURATION';
    }

    return RecurrenceDateProperty('$propertyName:${value.join(',')}');
  }
}

/// Defines an alarm trigger
class TriggerProperty extends Property {
  /// Creates a new [TriggerProperty]
  TriggerProperty(String definition) : super(definition, ValueType.duration);

  /// Creates a new [TriggerProperty]
  TriggerProperty.dateTime(String definition)
      : super(definition, ValueType.dateTime);

  /// `TRIGGER`
  static const String propertyName = 'TRIGGER';

  IsoDuration? get duration => value is IsoDuration ? value : null;
  DateTime? get dateTime => value is DateTime ? value : null;

  /// Does the trigger relate to the start or the end of the enclosing VEvent?
  AlarmTriggerRelationship get triggerRelation =>
      getParameterValue<AlarmTriggerRelationship>(
        ParameterType.alarmTriggerRelationship,
      ) ??
      AlarmTriggerRelationship.start;

  /// Sets the trigger relation
  set triggerRelation(AlarmTriggerRelationship? value) => setOrRemoveParameter(
        ParameterType.alarmTriggerRelationship,
        AlarmTriggerRelationshipParameter.create(
          ParameterType.alarmTriggerRelationship.typeName ?? '',
          value,
        ),
      );

  static TriggerProperty? createWithDateTime(
    DateTime? value, {
    AlarmTriggerRelationship? relation,
  }) {
    if (value == null) {
      return null;
    }
    final prop = TriggerProperty.dateTime(
      '$propertyName:${DateHelper.toDateTimeString(value)}',
    );
    prop[ParameterType.value] =
        ValueParameter.value('VALUE', ValueType.dateTime);
    if (relation != null) {
      prop[ParameterType.alarmTriggerRelationship] =
          AlarmTriggerRelationshipParameter.value(
        ParameterType.alarmTriggerRelationship.typeName ?? '',
        relation,
      );
    }

    return prop;
  }

  static TriggerProperty? createWithDuration(
    IsoDuration? value, {
    AlarmTriggerRelationship? relation,
  }) {
    if (value == null) {
      return null;
    }
    final prop = TriggerProperty('$propertyName;VALUE=DURATION:$value');
    if (relation != null) {
      prop[ParameterType.alarmTriggerRelationship] =
          AlarmTriggerRelationshipParameter.value(
        ParameterType.alarmTriggerRelationship.typeName ?? '',
        relation,
      );
    }

    return prop;
  }
}

class ActionProperty extends TextProperty {
  ActionProperty(super.definition);

  /// `ACTION`
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

  static ActionProperty? createWithAction(AlarmAction? value) {
    if (value == null || value == AlarmAction.other) {
      return null;
    }
    return ActionProperty('$propertyName:${value.name}');
  }

  static ActionProperty? createWithActionText(String? value) {
    if (value == null) {
      return null;
    }
    return ActionProperty('$propertyName:$value');
  }
}

class RequestStatusProperty extends TextProperty {
  RequestStatusProperty(super.definition);

  /// `REQUEST-STATUS`
  static const String propertyName = 'REQUEST-STATUS';

  //TODO consider extracting status code from text, compare https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.4.5
  String get requestStatus => text;

  static RequestStatusProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return RequestStatusProperty('$propertyName:$value');
  }
}

class EventBusyStatusProperty extends Property {
  EventBusyStatusProperty(String definition)
      : super(definition, ValueType.other,
            parser: (property, textValue) => _parse(textValue));
  EventBusyStatusProperty.value(EventBusyStatus value)
      : this('$propertyName:${value.name}');

  /// `X-MICROSOFT-CDO-BUSYSTATUS`
  static const String propertyName = 'X-MICROSOFT-CDO-BUSYSTATUS';

  EventBusyStatus get eventBusyStatus => value as EventBusyStatus;

  static EventBusyStatus _parse(String textValue) {
    switch (textValue) {
      case 'FREE':
        return EventBusyStatus.free;
      case 'TENTATIVE':
        return EventBusyStatus.tentative;
      case 'BUSY':
        return EventBusyStatus.busy;
      case 'OOF':
        return EventBusyStatus.outOfOffice;
    }
    throw FormatException(
        'Unable to parse value [$textValue] for X-MICROSOFT-CDO-BUSYSTATUS');
  }

  static EventBusyStatusProperty? create(EventBusyStatus? value) {
    if (value == null) {
      return null;
    }
    return EventBusyStatusProperty.value(value);
  }
}
