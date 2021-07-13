import 'package:enough_icalendar/enough_icalendar.dart';

import 'properties.dart';
import 'package:collection/collection.dart' show IterableExtension;

/// The type of the component, convenient for switch cases
enum ComponentType {
  calendar,
  event,
  todo,
  journal,
  freeBusy,
  timezone,
  timezonePhaseStandard,
  timezonePhaseDaylight,
  alarm,

  /// reserved for future / custom components
  other
}

/// Commmon properties
class Component {
  /// The type of the component, convenient for switch cases
  final ComponentType componentType;

  /// The name of the component like `VEVENT` or `VCALENDAR`
  final String name;

  /// The properties of the component
  final List<Property> properties = <Property>[];

  /// The parent component, if any
  final Component? parent;

  /// The children of this component, empty when there a no children
  final List<Component> children = <Component>[];

  Component(this.name, [this.parent]) : componentType = _getComponentType(name);

  static ComponentType _getComponentType(String name) {
    switch (name) {
      case VCalendar.componentName:
        return ComponentType.calendar;
      case VEvent.componentName:
        return ComponentType.event;
      case VTimezone.componentName:
        return ComponentType.timezone;
      case VTimezonePhase.componentNameStandard:
        return ComponentType.timezonePhaseStandard;
      case VTimezonePhase.componentNameDaylight:
        return ComponentType.timezonePhaseDaylight;
      case VTodo.componentName:
        return ComponentType.todo;
      case VJournal.componentName:
        return ComponentType.journal;
      case VAlarm.componentName:
        return ComponentType.alarm;
      case VFreeBusy.componentName:
        return ComponentType.freeBusy;
    }
    print(
        'Warning: Component not registered: $name (in Component._getComponentType)');
    return ComponentType.other;
  }

  /// Gets the version of this calendar, typically `2.0`
  String? get version =>
      getProperty<VersionProperty>(VersionProperty.propertyName)?.textValue;

  /// Checks if this version is `2.0`, which is assumed to be true unless a different version is specified.
  bool get isVersion2 =>
      getProperty<VersionProperty>(VersionProperty.propertyName)?.isVersion2 ??
      true;

  /// Retrieves the product identifier that generated this iCalendar object
  String? get productId =>
      getProperty<TextProperty>(TextProperty.propertyNameProductIdentifier)
          ?.textValue;

  /// Classes can implement this to check the validity.
  ///
  /// If the component missed required information, throw a [FormatException] with details.
  void checkValidity() {}

  /// Retrieves all properties with the name [propertyName]
  Iterable<Property> findProperties(final String propertyName) =>
      properties.where((p) => p.name == propertyName);

  /// Retrieves the property with the [propertyName]
  ///
  /// Optionally specify the type [T] for not needing to cast yourself
  T? getProperty<T extends Property>(final String propertyName) =>
      properties.firstWhereOrNull((prop) => prop.name == propertyName) as T?;

  /// Retrieves all matching properties with the name [propertyName].
  ///
  /// Optionally specify the type [T] for not needing to cast yourself
  Iterable<T> getProperties<T extends Property>(final String propertyName) =>
      properties.where((prop) => prop.name == propertyName).map((e) => e as T);

  /// Retrieves the first property with the name [propertyName]
  Property? operator [](final String propertyName) =>
      properties.firstWhereOrNull((prop) => prop.name == propertyName);

  /// Sets the property [property], replacing other properties with the given [propertyName] first.
  operator []=(final String propertyName, final Property property) {
    properties.removeWhere((prop) => prop.name == propertyName);
    properties.add(property);
  }

  /// Parses the component from the specified [text].
  ///
  /// When succeeding, this returns a [VCalendar], [VEvent] or similar component as defined by the given [text].
  /// The [text] can either contain `\r\n` (`CRLF`) or `\n` linebreaks, when both linebreak types are present in the [text], `CRLF` linebreaks are assumed.
  /// Folded lines are unfolded automatically.
  /// When you have a custom line delimiter, use [parseLines] instead.
  static Component parse(String text,
      {Property? Function(String name, String definition)? customParser}) {
    final containsStandardCompliantLineBreaks = text.contains('\r\n');
    final foldedLines = containsStandardCompliantLineBreaks
        ? text.split('\r\n')
        : text.split('\n');
    final lines = unfold(
      foldedLines,
      containsStandardCompliantLineBreaks: containsStandardCompliantLineBreaks,
    );
    if (lines.isEmpty) {
      throw FormatException('Invalid input: [$text]');
    }
    return parseLines(lines);
  }

  /// Parses the component from the specified text [lines].
  ///
  /// Compare [parse] for details.
  static Component parseLines(List<String> lines) {
    Component root = _createComponent(lines.first);
    Component current = root;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('BEGIN:')) {
        final child = _createComponent(line, parent: current);
        current.children.add(child);
        current = child;
      } else if (line.startsWith('END:')) {
        final expected = 'END:${current.name}';
        if (line != expected) {
          throw FormatException('Received $line but expected $expected');
        }
        current.checkValidity();
        final parent = current.parent;
        if (parent != null) {
          current = parent;
        }
      } else {
        final property = Property.parseProperty(line);
        current.properties.add(property);
      }
    }
    return root;
  }

  /// Creates the component based on the first line
  static Component _createComponent(String line, {Component? parent}) {
    switch (line) {
      case 'BEGIN:VCALENDAR':
        return VCalendar(parent: parent);
      case 'BEGIN:VEVENT':
        return VEvent(parent: parent);
      case 'BEGIN:VTIMEZONE':
        return VTimezone(parent: parent);
      case 'BEGIN:STANDARD':
        return VTimezonePhase(VTimezonePhase.componentNameStandard,
            parent: parent as VTimezone);
      case 'BEGIN:DAYLIGHT':
        return VTimezonePhase(VTimezonePhase.componentNameDaylight,
            parent: parent as VTimezone);
      case 'BEGIN:VTODO':
        return VTodo(parent: parent);
      case 'BEGIN:VJOURNAL':
        return VJournal(parent: parent);
      case 'BEGIN:VALARM':
        return VAlarm(parent: parent);
      case 'BEGIN:VFREEBUSY':
        return VFreeBusy(parent: parent);
      default:
        throw FormatException('Unknown component: $line');
    }
  }

  /// Unfolds the given [input] lines
  ///
  /// When [containsStandardCompliantLineBreaks] is not the default `true`, then extra care is taken
  /// to re-include lines that have been split in error.
  static List<String> unfold(List<String> input,
      {bool containsStandardCompliantLineBreaks = true}) {
    final output = <String>[];
    StringBuffer? buffer;
    for (var i = 0; i < input.length; i++) {
      final current = input[i];
      if (buffer != null) {
        if (current.startsWithWhiteSpace() && current.length > 1) {
          buffer.write(current.trimLeft());
          if (i == input.length - 1) {
            output.add(buffer.toString());
          }
          continue;
        } else if (!containsStandardCompliantLineBreaks &&
            !current.contains(':')) {
          // this can happen when the description or similiar fields also contain \n linebreaks
          buffer..write('\n')..write(current.trimLeft());
          if (i == input.length - 1) {
            output.add(buffer.toString());
          }
          continue;
        } else {
          // this is then end of the current fold:
          output.add(buffer.toString());
          buffer = null;
        }
      }
      if (i < input.length - 1) {
        final next = input[i + 1];
        if (next.startsWithWhiteSpace()) {
          buffer = StringBuffer();
          buffer.write(current);
        } else if (current.isNotEmpty) {
          output.add(current);
        }
      } else if (current.isNotEmpty) {
        output.add(current);
      }
    }
    return output;
  }

  /// Checks if the property with the given [name] is present.
  ///
  /// Throws [FormatException] when the property is missing.
  void checkMandatoryProperty(String name) {
    if (this[name] == null) {
      throw FormatException('Mandatory property "$name" is missing.');
    }
  }
}

extension WhiteSpaceDetector on String {
  bool startsWithWhiteSpace() {
    return startsWith(' ') || startsWith('\t');
  }
}

/// Contains a `VCALENDAR` component
///
/// Often the parent component for others such as [VEvent]
class VCalendar extends Component {
  static const String componentName = 'VCALENDAR';
  VCalendar({Component? parent}) : super(componentName, parent);

  /// Retrieves the scale of the calendar, typically `GREGORIAN`
  ///
  /// Compare [isGregorian]
  String get calendarScale =>
      getProperty<CalendarScaleProperty>(CalendarScaleProperty.propertyName)
          ?.textValue ??
      'GREGORIAN';

  /// Checks if this calendar has a Gregorian scale.
  ///
  /// Compare [calendarScale]
  bool get isGregorian => calendarScale == 'GREGORIAN';

  /// Retrieves the method by which answers are expected
  String? get method =>
      getProperty<TextProperty>(TextProperty.propertyNameMethod)?.textValue;

  /// Retrieves the global timezone ID like `America/New_York` or `Europe/Berlin` using the propriety but common `X-WR-TIMEZONE` property.
  ///
  /// Any dates of subsequent components without explicit timezoneId should be interpreted according to this
  /// timezone ID. For caveats compare https://blog.jonudell.net/2011/10/17/x-wr-timezone-considered-harmful/
  String? get timezoneId =>
      getProperty<TextProperty>(TextProperty.propertyNameXWrTimezone)
          ?.textValue;
}

class _UidMandatoryComponent extends Component {
  _UidMandatoryComponent(String name, [Component? parent])
      : super(name, parent);

  /// Retrieves the UID identifying this calendar component
  String get uid => this[TextProperty.propertyNameUid]!.textValue;

  /// Sets the UID identifying this calendar component
  set uid(String value) => this[TextProperty.propertyNameUid] =
      TextProperty('${TextProperty.propertyNameUid}:$value');

  /// Mandatory timestamp / `DTSTAMP` property
  DateTime get timeStamp =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameTimeStamp)!
          .dateTime;

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(TextProperty.propertyNameUid);
    checkMandatoryProperty(DateTimeProperty.propertyNameTimeStamp);
  }
}

class _EventTodoJournalComponent extends _UidMandatoryComponent {
  _EventTodoJournalComponent(String name, Component? parent)
      : super(name, parent);

  /// This property defines the access classification for a calendar component
  Classification? get classification =>
      getProperty<ClassificationProperty>(ClassificationProperty.propertyName)
          ?.classification;

  /// Retrieves the attachments
  List<AttachmentProperty> get attachments =>
      getProperties<AttachmentProperty>(AttachmentProperty.propertyName)
          .toList();

  /// Retrieves the free text categories
  List<String>? get categories =>
      getProperty<CategoriesProperty>(CategoriesProperty.propertyName)
          ?.categories;

  /// Gets the summmary / title
  String? get summary =>
      getProperty<TextProperty>(TextProperty.propertyNameSummary)?.textValue;

  /// Retrieves the description
  String? get description =>
      getProperty<TextProperty>(TextProperty.propertyNameDescription)?.text;

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Retrieves the organizer of this event
  OrganizerProperty? get organizer =>
      getProperty<OrganizerProperty>(OrganizerProperty.propertyName);

  /// Retrieves the contact for details
  UserProperty? get contact =>
      getProperty<UserProperty>(UserProperty.propertyNameContact);

  ///  Identifies a particular instance of a recurring event, to-do, or journal.
  ///
  ///  For a given pair of "UID" and "SEQUENCE" property values, the
  /// "RECURRENCE-ID" value for a recurrence instance is fixed.
  DateTime? get recurrenceId =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameRecurrenceId)
          ?.dateTime;

  /// Retrieves the recurrence rule of this event
  ///
  /// Compare [additionalRecurrenceDates], [excludingRecurrenceDates]
  Recurrence? get recurrenceRule =>
      getProperty<RecurrenceRuleProperty>(RecurrenceRuleProperty.propertyName)
          ?.rule;

  /// Retrieves additional reccurrence dates or durations as defined in the `RDATE` property
  ///
  /// Compare [excludingRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get additionalRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameRDate)
          ?.dates;

  /// Retrieves excluding reccurrence dates or durations as defined in the `EXDATE` property
  ///
  /// Compare [additionalRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get excludingRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameExDate)
          ?.dates;

  /// Retrieves the UID of a related event, to-do or journal.
  String? get relatedTo =>
      getProperty<TextProperty>(TextProperty.propertyNameRelatedTo)?.text;

  /// Retrieves the URL for additional information
  Uri? get url => getProperty<UriProperty>(UriProperty.propertyNameUrl)?.uri;

  /// The creation date
  DateTime? get created =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameCreated)
          ?.dateTime;

  /// The date of the last modification / update of this event.
  DateTime? get lastModified =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameLastModified)
          ?.dateTime;

  /// Gets the revision sequence number of this component
  int? get sequence =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameSequence)
          ?.intValue;

  /// Retrieves the request status, e.g. `4.1;Event conflict.  Date-time is busy.`
  String? get requestStatus =>
      getProperty<RequestStatusProperty>(RequestStatusProperty.propertyName)
          ?.requestStatus;
}

/// Contains information about an event.
class VEvent extends _EventTodoJournalComponent {
  static const String componentName = 'VEVENT';
  VEvent({Component? parent}) : super(componentName, parent);

  /// Tries to the timezone ID like `America/New_York` or `Europe/Berlin` from `DTSTART` property.
  String? get timezoneId {
    final prop = getProperty<DateTimeProperty>(
            DateTimeProperty.propertyNameStart) ??
        getProperty<DateTimeProperty>(DateTimeProperty.propertyNameEnd) ??
        getProperty<DateTimeProperty>(DateTimeProperty.propertyNameTimeStamp);
    return prop?.timezoneId;
  }

  /// The start time (inclusive) of this event.
  ///
  ///  is REQUIRED if the component appears in an iCalendar object that doesn't
  /// specify the "METHOD" property; otherwise, it is OPTIONAL; in any case, it MUST NOT occur
  /// more than once.
  DateTime? get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)
          ?.dateTime;

  /// The end date (exclusive) of this event.
  ///
  /// either `DTEND` or `DURATION` may occur, but not both
  /// Compare [duration]
  DateTime? get end =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameEnd)?.dateTime;

  /// The duration of this event.
  ///
  /// either `DTEND` or `DURATION` may occur, but not both
  /// Compare [end]
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// The location e.g. room number / name
  String? get location =>
      getProperty<TextProperty>(TextProperty.propertyNameLocation)?.textValue;

  /// The geo location of this event.
  GeoLocation? get geoLocation =>
      getProperty<GeoProperty>(GeoProperty.propertyName)?.location;

  /// Retrieves the transparency of this event in regards to busy time searches.
  TimeTransparency get timeTransparency =>
      getProperty<TimeTransparencyProperty>(
              TimeTransparencyProperty.propertyName)
          ?.transparency ??
      TimeTransparency.opaque;

  /// Retrieves the status of this event
  EventStatus? get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.eventStatus;

  /// Retrieves the priority as a numeric value between 1 (highest) and 9 (lowest) priority.
  int? get priorityInt =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.intValue;

  /// Retrieves the priority of this event
  Priority? get priority =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.priority;

  /// Retrieves the resources required for this event
  String? get resources =>
      getProperty<TextProperty>(TextProperty.propertyNameResources)?.text;
  // @override
  // void checkValidity() {
  //   super.checkValidity();
  // }
}

class VTodo extends _EventTodoJournalComponent {
  static const String componentName = 'VTODO';
  VTodo({Component? parent}) : super(componentName, parent);

  /// Gets the revision sequence number of this component
  int? get sequence =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameSequence)
          ?.intValue;

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Retrieves the organizer of this event
  OrganizerProperty? get organizer =>
      getProperty<OrganizerProperty>(OrganizerProperty.propertyName);

  /// The summmary / title
  String? get summary =>
      getProperty<TextProperty>(TextProperty.propertyNameSummary)?.textValue;

  /// The description
  String? get description =>
      getProperty<TextProperty>(TextProperty.propertyNameDescription)
          ?.textValue;

  /// The status of this todo
  TodoStatus get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.todoStatus ??
      TodoStatus.unknown;

  /// Retrieves the due date of this task
  DateTime? get due =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameDue)?.dateTime;

  /// Retrieves the start date of this task
  DateTime? get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)
          ?.dateTime;

  /// Retrieves the date when this task was completed
  DateTime? get completed =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameCompleted)
          ?.dateTime;

  /// Retrieves the duration of the task
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// The geo location of this event.
  GeoLocation? get geoLocation =>
      getProperty<GeoProperty>(GeoProperty.propertyName)?.location;

  /// The location e.g. room number / name
  String? get location =>
      getProperty<TextProperty>(TextProperty.propertyNameLocation)?.textValue;

  /// Retrieves the percentage value between 0 and 100 that shows how much is done of this task,
  ///
  /// 100 means the task is fully done; 0 means the task has not been started.
  int? get percentComplete =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNamePercentComplete)
          ?.intValue;

  /// Retrieves the priority as a numeric value between 1 (highest) and 9 (lowest) priority.
  int? get priorityInt =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.intValue;

  /// Retrieves the priority of this task
  Priority? get priority =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.priority;

  /// Retrieves the resources required for this task
  String? get resources =>
      getProperty<TextProperty>(TextProperty.propertyNameResources)?.text;
}

class VJournal extends _EventTodoJournalComponent {
  static const String componentName = 'VJOURNAL';
  VJournal({Component? parent}) : super(componentName, parent);

  /// Gets the revision sequence number of this component
  int? get sequence =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameSequence)
          ?.intValue;

  /// The status of this journal entry
  JournalStatus get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.journalStatus ??
      JournalStatus.unknown;
}

class VTimezone extends Component {
  static const String componentName = 'VTIMEZONE';
  VTimezone({Component? parent}) : super(componentName, parent);

  /// Retrieves the ID such as `America/New_York` or `Europe/Berlin`
  String get timezoneId =>
      getProperty<TextProperty>(TextProperty.propertyNameTimezoneId)!.textValue;

  Uri? get uri =>
      getProperty<UriProperty>(UriProperty.propertyNameTimezoneUrl)?.uri;

  /// The date of the last modification / update of this event.
  DateTime? get lastModified =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameLastModified)
          ?.dateTime;

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(TextProperty.propertyNameTimezoneId);
    if (children.length < 2) {
      throw FormatException(
          'A valid VTIMEZONE requires at least one STANDARD and one DAYLIGHT sub-component');
    }
    var numberOfStandardChildren = 0, numberOfDaylightChildren = 0;
    for (final phase in children) {
      if (phase.componentType == ComponentType.timezonePhaseStandard) {
        numberOfStandardChildren++;
      } else if (phase.componentType == ComponentType.timezonePhaseDaylight) {
        numberOfDaylightChildren++;
      }
    }
    if (numberOfStandardChildren == 0 || numberOfDaylightChildren == 0) {
      throw FormatException(
          'A valid VTIMEZONE requires at least one STANDARD and one DAYLIGHT sub-component');
    }
  }
}

class VTimezonePhase extends Component {
  static const String componentNameStandard = 'STANDARD';
  static const String componentNameDaylight = 'DAYLIGHT';

  VTimezonePhase(String componentName, {required VTimezone parent})
      : super(componentName, parent);
  DateTime get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)!
          .dateTime;

  UtcOffset get from => getProperty<UtfOffsetProperty>(
          UtfOffsetProperty.propertyNameTimezoneOffsetFrom)!
      .offset;

  UtcOffset get to => getProperty<UtfOffsetProperty>(
          UtfOffsetProperty.propertyNameTimezoneOffsetTo)!
      .offset;

  //TODO the name property can occur more than once
  String? get timezoneName =>
      getProperty<TextProperty>(TextProperty.propertyNameTimezoneName)
          ?.textValue;

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// Retrieves the recurrence rule of this event
  ///
  /// Compare [additionalRecurrenceDates], [excludingRecurrenceDates]
  Recurrence? get recurrenceRule =>
      getProperty<RecurrenceRuleProperty>(RecurrenceRuleProperty.propertyName)
          ?.rule;

  /// Retrieves additional reccurrence dates or durations as defined in the `RDATE` property
  ///
  /// Compare [excludingRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get additionalRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameRDate)
          ?.dates;

  /// Retrieves excluding reccurrence dates or durations as defined in the `EXDATE` property
  ///
  /// Compare [additionalRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get excludingRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameExDate)
          ?.dates;

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(DateTimeProperty.propertyNameStart);
    checkMandatoryProperty(UtfOffsetProperty.propertyNameTimezoneOffsetFrom);
    checkMandatoryProperty(UtfOffsetProperty.propertyNameTimezoneOffsetTo);
  }
}

class VAlarm extends Component {
  static const String componentName = 'VALARM';
  VAlarm({Component? parent}) : super(componentName, parent);

  DateTime? get triggerDate =>
      getProperty<TriggerProperty>(TriggerProperty.propertyName)?.dateTime;
  IsoDuration? get triggerRelativeDuration =>
      getProperty<TriggerProperty>(TriggerProperty.propertyName)?.duration;

  int get repeat =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameRepeat)
          ?.intValue ??
      0;

  AlarmAction get action =>
      getProperty<ActionProperty>(ActionProperty.propertyName)?.action ??
      AlarmAction.other;

  String? get actionText =>
      getProperty<ActionProperty>(ActionProperty.propertyName)?.textValue;

  /// Retrieves the duration of the alarm
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// Retrieves the attachments
  List<AttachmentProperty> get attachments =>
      getProperties<AttachmentProperty>(AttachmentProperty.propertyName)
          .toList();

  /// Gets the summmary / title
  String? get summary =>
      getProperty<TextProperty>(TextProperty.propertyNameSummary)?.textValue;

  /// Retrieves the description
  String? get description =>
      getProperty<TextProperty>(TextProperty.propertyNameDescription)?.text;

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(TriggerProperty.propertyName);
    checkMandatoryProperty(ActionProperty.propertyName);
  }
}

/// Provides information about free and busy times of a particular user
class VFreeBusy extends _UidMandatoryComponent {
  static const String componentName = 'VFREEBUSY';
  VFreeBusy({Component? parent}) : super(componentName, parent);

  /// Retrieves the list of free busy entries
  List<FreeBusyProperty> get freeBusyProperties =>
      getProperties<FreeBusyProperty>(FreeBusyProperty.propertyName).toList();

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// The start time (inclusive) of the free busy time.
  DateTime? get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)
          ?.dateTime;

  /// The end date (exclusive) of the free busy time.
  DateTime? get end =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameEnd)?.dateTime;

  /// Retrieves the contact for details
  UserProperty? get contact =>
      getProperty<UserProperty>(UserProperty.propertyNameContact);

  /// Retrieves the request status, e.g. `4.1;Event conflict.  Date-time is busy.`
  String? get requestStatus =>
      getProperty<RequestStatusProperty>(RequestStatusProperty.propertyName)
          ?.requestStatus;

  /// Retrieves the URL for additional information
  Uri? get url => getProperty<UriProperty>(UriProperty.propertyNameUrl)?.uri;

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Retrieves the organizer of this event
  OrganizerProperty? get organizer =>
      getProperty<OrganizerProperty>(OrganizerProperty.propertyName);
}
