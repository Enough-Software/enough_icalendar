import 'parameters.dart';
import 'types.dart';
import 'util.dart';

class Property {
  Property(this.definition, ValueType defaultValueType,
      {dynamic Function(Property property, String textValue)? parser})
      : name = _getName(definition),
        textValue = _getTextContent(definition),
        parameters = _parseParameters(definition) {
    if (parser != null) {
      value = parser(this, textValue);
    } else {
      value = _parsePropertyValue(this, defaultValueType);
    }
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

  Parameter? operator [](ParameterType type) => parameters[type.name];

  operator []=(ParameterType type, Parameter value) =>
      parameters[value.name] = value;

  void setParameter(Parameter value) => parameters[value.name] = value;

  void setOrRemoveParameter(ParameterType type, Parameter? value) {
    if (value == null) {
      parameters.remove(type.name);
    } else {
      parameters[type.name!] = value;
    }
  }

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
      case MethodProperty.propertyName:
        return MethodProperty(definition);
      case RequestStatusProperty.propertyName:
        return RequestStatusProperty(definition);
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
    buffer..write(name);
    if (parameters.isNotEmpty) {
      for (final parameter in parameters.values) {
        buffer
          ..write(';')
          ..write(parameter.name)
          ..write('=')
          ..write(parameter.textValue);
      }
    }
    buffer..write(':')..write(textValue);
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
      wrappedBuffer..write(definition.substring(0, startIndex))..write('\r\n');
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
  operator ==(Object other) => other.toString() == toString();

  /// Creates a copy of this property
  Property copy() {
    final buffer = StringBuffer();
    render(buffer);
    return Property.parseProperty(buffer.toString());
  }
}

class RecurrenceRuleProperty extends Property {
  /// `RRULE`
  static const String propertyName = 'RRULE';
  Recurrence get rule => value as Recurrence;

  RecurrenceRuleProperty(String definition)
      : super(definition, ValueType.other);

  Recurrence parse(String texValue) {
    return Recurrence.parse(textValue);
  }

  static RecurrenceRuleProperty? create(Recurrence? value) {
    if (value == null) {
      return null;
    }
    return RecurrenceRuleProperty('$propertyName:$value');
  }
}

class UriProperty extends Property {
  /// `TZURL`
  static const String propertyNameTimezoneUrl = 'TZURL';

  /// `URL`
  static const String propertyNameUrl = 'URL';

  Uri get uri => value as Uri;
  UriProperty(String definition) : super(definition, ValueType.uri);

  static UriProperty? create(String propertyName, Uri? value) {
    if (value == null) {
      return null;
    }
    return UriProperty('$propertyName:$value');
  }
}

class UserProperty extends UriProperty {
  /// `CONTACT`
  static const String propertyNameContact = 'CONTACT';
  UserProperty(String definition) : super(definition);

  /// Gets the common name associated with this calendar user
  String? get commonName => getParameterValue<String>(ParameterType.commonName);

  /// Sets the common name associated with this calendar user
  set commonName(String? value) => setOrRemoveParameter(
      ParameterType.commonName,
      TextParameter.create(ParameterType.commonName, value));

  /// Gets the directory link, for example an LDAP URI
  Uri? get directory => getParameterValue<Uri>(ParameterType.directory);

  /// Sets the directory
  set directory(Uri? value) => setOrRemoveParameter(ParameterType.directory,
      UriParameter.create(ParameterType.directory, value));

  /// Gets the alternative representation, e.g. a link to a VCARD
  Uri? get alternateRepresentation =>
      getParameterValue<Uri>(ParameterType.alternateRepresentation);

  /// Sets the alternative representation
  set alternateRepresentation(Uri? value) => setOrRemoveParameter(
      ParameterType.alternateRepresentation,
      UriParameter.create(ParameterType.alternateRepresentation, value));

  /// Retrieves the type of the user.
  ///
  /// Defaults to [CalendarUserType.unknown].
  CalendarUserType get userType =>
      getParameterValue<CalendarUserType>(ParameterType.calendarUserType) ??
      CalendarUserType.unknown;

  /// Set the type of the user
  set userType(CalendarUserType? value) => setOrRemoveParameter(
      ParameterType.calendarUserType, CalendarUserTypeParameter.create(value));

  /// Retrieve the email from this value
  String? get email => uri.isScheme('MAILTO') ? uri.path : null;
}

class AttendeeProperty extends UserProperty {
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
      ParameterType.rsvp, BooleanParameter.create(ParameterType.rsvp, value));

  /// Gets the role of this participant, defaults to [Role.requiredParticipant]
  Role get role =>
      getParameterValue<Role>(ParameterType.participantRole) ??
      Role.requiredParticipant;

  /// Sets the role of this participant
  set role(Role? value) => setOrRemoveParameter(
      ParameterType.participantRole, ParticipantRoleParameter.create(value));

  /// Gets the participant status of this attendee
  ///
  /// The possible values depend on the type of the component.
  ParticipantStatus? get participantStatus =>
      getParameterValue<ParticipantStatus>(ParameterType.participantStatus);

  /// Sets the participant status
  set participantStatus(ParticipantStatus? value) => setOrRemoveParameter(
      ParameterType.participantStatus,
      ParticipantStatusParameter.create(value));

  /// Retrieves the URI of the the user that this attendee has delegated the event or task to
  Uri? get delegatedTo => getParameterValue<Uri>(ParameterType.delegateTo);

  /// Sets the delegatedTo URI
  set delegatedTo(Uri? value) => setOrRemoveParameter(ParameterType.delegateTo,
      UriParameter.create(ParameterType.delegateTo, value));

  /// Retrieves the email of the the user that this attendee has delegated the event or task to
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

  /// Retrieves the URI of the the user that this attendee has delegated the event or task from
  Uri? get delegatedFrom => getParameterValue<Uri>(ParameterType.delegateFrom);

  /// Sets the delegatedFrom URI
  set delegatedFrom(Uri? value) => setOrRemoveParameter(
      ParameterType.delegateFrom,
      UriParameter.create(ParameterType.delegateTo, value));

  /// Retrieves the email of the the user that this attendee has delegated the event or task from
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

  AttendeeProperty(String definition) : super(definition);

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
      prop[ParameterType.participantStatus] =
          ParticipantStatusParameter.value(participantStatus);
    }
    if (delegatedToEmail != null) {
      delegatedToUri = Uri.parse('mailto:$delegatedToEmail');
    }
    if (delegatedToUri != null) {
      prop[ParameterType.delegateTo] =
          UriParameter.value(ParameterType.delegateTo, delegatedToUri);
    }
    if (delegatedFromEmail != null) {
      delegatedFromUri = Uri.parse('mailto:$delegatedFromEmail');
    }
    if (delegatedFromUri != null) {
      prop[ParameterType.delegateFrom] =
          UriParameter.value(ParameterType.delegateFrom, delegatedFromUri);
    }
    if (role != null) {
      prop[ParameterType.participantRole] =
          ParticipantRoleParameter.value(role);
    }
    if (rsvp != null) {
      prop[ParameterType.rsvp] =
          BooleanParameter.value(ParameterType.rsvp, rsvp);
    }
    if (userType != null) {
      prop[ParameterType.calendarUserType] =
          CalendarUserTypeParameter.value(userType);
    }
    if (commonName != null) {
      prop[ParameterType.commonName] =
          TextParameter.value(ParameterType.commonName, commonName);
    }
    if (alternateRepresentation != null) {
      prop[ParameterType.alternateRepresentation] = UriParameter.value(
          ParameterType.alternateRepresentation, alternateRepresentation);
    }
    if (directory != null) {
      prop[ParameterType.directory] =
          UriParameter.value(ParameterType.directory, directory);
    }
    return prop;
  }
}

class OrganizerProperty extends UserProperty {
  /// `ORGANIZER`
  static const String propertyName = 'ORGANIZER';
  Uri get organizer => uri;

  /// Gets the sender of this organizer
  Uri? get sentBy => getParameterValue<Uri>(ParameterType.sentBy);

  /// Sets the sender of this organizer
  set sentBy(Uri? value) => setOrRemoveParameter(
      ParameterType.sentBy, UriParameter.create(ParameterType.sentBy, value));

  OrganizerProperty(String definition) : super(definition);

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
          UriParameter.value(ParameterType.sentBy, sentBy);
    }
    if (commonName != null) {
      prop.commonName = commonName;
    }
    return prop;
  }
}

class GeoProperty extends Property {
  /// `GEO`
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

  static GeoProperty? create(GeoLocation? value) {
    if (value == null) {
      return null;
    }
    return GeoProperty('$propertyName:$value');
  }
}

class AttachmentProperty extends Property {
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
      TextParameter.create(ParameterType.formatType, value));

  /// Retrieves the encoding such as `BASE64`, only relevant when the content is binary
  ///
  /// Compare [isBinary]
  String? get encoding => getParameterValue<String>(ParameterType.encoding);

  /// Sets the encoding
  set encoding(String? value) => setOrRemoveParameter(ParameterType.encoding,
      TextParameter.create(ParameterType.encoding, value));

  /// Checks if this contains binary data
  ///
  /// Compare [binary]
  bool get isBinary => value is Binary;

  AttachmentProperty(String content) : super(content, ValueType.uri);
}

class CalendarScaleProperty extends Property {
  /// `CALSCALE`
  static const String propertyName = 'CALSCALE';
  bool get isGregorianCalendar => textValue == 'GREGORIAN';

  CalendarScaleProperty(String definition) : super(definition, ValueType.text);

  static CalendarScaleProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return CalendarScaleProperty('$propertyName:$value');
  }
}

class VersionProperty extends Property {
  /// `VERSION`
  static const String propertyName = 'VERSION';

  bool get isVersion2 => textValue == '2.0';

  VersionProperty(String definition) : super(definition, ValueType.text);

  static VersionProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return VersionProperty('$propertyName:$value');
  }
}

class CategoriesProperty extends Property {
  /// `CATEGORIES`
  static const String propertyName = 'CATEGORIES';

  List<String> get categories => textValue.split(',');

  CategoriesProperty(String definition) : super(definition, ValueType.text);

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
  /// `CLASS`
  static const String propertyName = 'CLASS';

  Classification get classification => value as Classification;

  ClassificationProperty(String definition)
      : super(definition, ValueType.typeClassification);

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

class TextProperty extends Property {
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

  /// Retrieve the language
  String? get language => this[ParameterType.language]?.textValue;

  /// Sets the language
  set language(String? value) => setOrRemoveParameter(ParameterType.language,
      TextParameter.create(ParameterType.language, value));

  /// Gets a link to an alternative representation
  Uri? get alternateRepresentation =>
      (this[ParameterType.alternateRepresentation] as UriParameter?)?.uri;

  /// Sets a link to an alternative representation
  set alternateRepresentation(Uri? value) => setOrRemoveParameter(
      ParameterType.alternateRepresentation,
      UriParameter.create(ParameterType.alternateRepresentation, value));

  String get text => value as String;

  TextProperty(String definition) : super(definition, ValueType.text);

  static TextProperty? create(String name, String? value,
      {String? language, Uri? alternateRepresentation}) {
    if (value == null) {
      return null;
    }
    final prop = TextProperty('$name:$value');
    if (language != null) {
      prop.setParameter(TextParameter.value(ParameterType.language, language));
    }
    if (alternateRepresentation != null) {
      prop.setParameter(UriParameter.value(
          ParameterType.alternateRepresentation, alternateRepresentation));
    }
    return prop;
  }
}

class MethodProperty extends Property {
  /// `METHOD`
  static const String propertyName = 'METHOD';

  MethodProperty(String definition)
      : super(definition, ValueType.text, parser: _parse);

  /// Retrieves the method
  Method get method => value as Method;

  static _parse(final Property property, final String textValue) {
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
  /// `PERCENT-COMPLETE`
  static const String propertyNamePercentComplete = 'PERCENT-COMPLETE';

  /// `SEQUENCE`
  static const String propertyNameSequence = 'SEQUENCE';

  /// `REPEAT`
  static const String propertyNameRepeat = 'REPEAT';

  int get intValue => value as int;

  IntegerProperty(String definition) : super(definition, ValueType.integer);

  static IntegerProperty? create(String name, int? value) {
    if (value == null) {
      return null;
    }
    return IntegerProperty('$name:$value');
  }
}

class DateTimeProperty extends Property {
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
      TextParameter.create(ParameterType.timezoneId, value));

  DateTimeProperty(String definition) : super(definition, ValueType.dateTime);

  static DateTimeProperty? create(String name, DateTime? value,
      {String? timeZoneId}) {
    if (value == null) {
      return null;
    }
    final prop =
        DateTimeProperty('$name:${DateHelper.toDateTimeString(value)}');
    if (timeZoneId != null) {
      prop[ParameterType.timezoneId] =
          TextParameter.value(ParameterType.timezoneId, timeZoneId);
    }
    return prop;
  }
}

class DurationProperty extends Property {
  /// `DURATION`
  static const String propertyName = 'DURATION';

  IsoDuration get duration => value as IsoDuration;

  DurationProperty(String definition) : super(definition, ValueType.duration);

  static DurationProperty? create(IsoDuration? value) {
    if (value == null) {
      return null;
    }
    return DurationProperty('$propertyName:$value');
  }
}

class PeriodProperty extends Property {
  //static const String propertyNameFreeBusy = 'FREEBUSY';

  Period get period => value as Period;

  PeriodProperty(String definition) : super(definition, ValueType.period);
}

class UtfOffsetProperty extends Property {
  /// `TZOFFSETFROM`
  static const String propertyNameTimezoneOffsetFrom = 'TZOFFSETFROM';

  /// `TZOFFSETTO`
  static const String propertyNameTimezoneOffsetTo = 'TZOFFSETTO';

  UtcOffset get offset => value as UtcOffset;

  UtfOffsetProperty(String definition) : super(definition, ValueType.utcOffset);

  static UtfOffsetProperty? create(String propertyName, UtcOffset? value) {
    if (value == null) {
      return null;
    }
    return UtfOffsetProperty('$propertyName:$value');
  }
}

class FreeBusyProperty extends Property {
  /// `FREEBUSY`
  static const String propertyName = 'FREEBUSY';

  /// Gets the type, defaults to [FreeBusyTimeType.busy]
  FreeBusyTimeType get freeBusyType =>
      getParameterValue<FreeBusyTimeType>(ParameterType.freeBusyTimeType) ??
      FreeBusyTimeType.busy;

  /// Sets the type
  set freeBusyType(FreeBusyTimeType? value) => setOrRemoveParameter(
      ParameterType.freeBusyTimeType, FreeBusyTimeTypeParameter.create(value));

  List<Period> get periods => value as List<Period>;

  FreeBusyProperty(String definition) : super(definition, ValueType.periodList);
}

class PriorityProperty extends IntegerProperty {
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

  PriorityProperty(String definition) : super(definition);

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

  StatusProperty(String definition) : super(definition);

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

  TimeTransparencyProperty(String definition) : super(definition);

  static TimeTransparencyProperty? create(TimeTransparency? value) {
    if (value == null) {
      return null;
    }
    return TimeTransparencyProperty('$propertyName:${value.name}');
  }
}

class RecurrenceDateProperty extends Property {
  /// `RDATE`
  static const String propertyNameRDate = 'RDATE';

  /// `EXDATE`
  static const String propertyNameExDate = 'EXDATE';

  List<DateTimeOrDuration> get dates => value as List<DateTimeOrDuration>;

  RecurrenceDateProperty(String definition)
      : super(definition, ValueType.typeDateTimeList);

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

class TriggerProperty extends Property {
  /// `TRIGGER`
  static const String propertyName = 'TRIGGER';

  IsoDuration? get duration => value is IsoDuration ? value : null;
  DateTime? get dateTime => value is DateTime ? value : null;

  /// Does the trigger relate to the start or the end of the enclosing VEvent?
  AlarmTriggerRelationship get triggerRelation =>
      getParameterValue<AlarmTriggerRelationship>(
          ParameterType.alarmTriggerRelationship) ??
      AlarmTriggerRelationship.start;

  /// Sets the trigger relation
  set triggerRelation(AlarmTriggerRelationship? value) => setOrRemoveParameter(
      ParameterType.alarmTriggerRelationship,
      AlarmTriggerRelationshipParameter.create(value));

  TriggerProperty(String definition) : super(definition, ValueType.duration);

  static TriggerProperty? createWithDateTime(DateTime? value,
      {AlarmTriggerRelationship? relation}) {
    if (value == null) {
      return null;
    }
    final prop =
        TriggerProperty('$propertyName:${DateHelper.toDateTimeString(value)}');
    if (relation != null) {
      prop[ParameterType.alarmTriggerRelationship] =
          AlarmTriggerRelationshipParameter.value(relation);
    }
    return prop;
  }

  static TriggerProperty? createWithDuration(IsoDuration? value,
      {AlarmTriggerRelationship? relation}) {
    if (value == null) {
      return null;
    }
    final prop = TriggerProperty('$propertyName;VALUE=DURATION:$value');
    if (relation != null) {
      prop[ParameterType.alarmTriggerRelationship] =
          AlarmTriggerRelationshipParameter.value(relation);
    }
    return prop;
  }
}

class ActionProperty extends TextProperty {
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

  ActionProperty(String definition) : super(definition);

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
  /// `REQUEST-STATUS`
  static const String propertyName = 'REQUEST-STATUS';

  //TODO consider extracting status code from text, compare https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.4.5
  String get requestStatus => text;

  RequestStatusProperty(String definition) : super(definition);

  static RequestStatusProperty? create(String? value) {
    if (value == null) {
      return null;
    }
    return RequestStatusProperty('$propertyName:$value');
  }
}
