import 'dart:math';

import 'package:enough_icalendar/enough_icalendar.dart';

import 'properties.dart';
import 'package:collection/collection.dart' show IterableExtension;

/// The type of the component, convenient for switch cases
enum VComponentType {
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
abstract class VComponent {
  /// The type of the component, convenient for switch cases
  final VComponentType componentType;

  /// The name of the component like `VEVENT` or `VCALENDAR`
  final String name;

  /// The properties of the component
  final List<Property> properties = <Property>[];

  /// The parent component, if any
  final VComponent? parent;

  /// The children of this component, empty when there a no children
  final List<VComponent> children = <VComponent>[];

  VComponent(this.name, [this.parent])
      : componentType = _getComponentType(name);

  static VComponentType _getComponentType(String name) {
    switch (name) {
      case VCalendar.componentName:
        return VComponentType.calendar;
      case VEvent.componentName:
        return VComponentType.event;
      case VTimezone.componentName:
        return VComponentType.timezone;
      case VTimezonePhase.componentNameStandard:
        return VComponentType.timezonePhaseStandard;
      case VTimezonePhase.componentNameDaylight:
        return VComponentType.timezonePhaseDaylight;
      case VTodo.componentName:
        return VComponentType.todo;
      case VJournal.componentName:
        return VComponentType.journal;
      case VAlarm.componentName:
        return VComponentType.alarm;
      case VFreeBusy.componentName:
        return VComponentType.freeBusy;
    }
    print(
        'Warning: Component not registered: $name (in Component._getComponentType)');
    return VComponentType.other;
  }

  /// Gets the version of this calendar, typically `2.0`
  String? get version =>
      getProperty<VersionProperty>(VersionProperty.propertyName)?.textValue;

  /// Sets the version of this calendar, typically `2.0`
  set version(String? value) => setOrRemoveProperty(
      VersionProperty.propertyName, VersionProperty.create(value));

  /// Checks if this version is `2.0`, which is assumed to be true unless a different version is specified.
  bool get isVersion2 =>
      getProperty<VersionProperty>(VersionProperty.propertyName)?.isVersion2 ??
      true;

  /// Retrieves the product identifier that generated this iCalendar object
  String? get productId =>
      getProperty<TextProperty>(TextProperty.propertyNameProductIdentifier)
          ?.textValue;

  /// Sets the product ID
  set productId(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameProductIdentifier,
      TextProperty.create(TextProperty.propertyNameProductIdentifier, value));

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

  /// Sets the property [property], replacing other properties with the [property.name] first.
  void setProperty(final Property property) => this[property.name] = property;

  /// Sets the given [props] by first removing any properties with the given [propertyName].
  void setProperties(final String propertyName, final List<Property> props) {
    properties.removeWhere((prop) => prop.name == propertyName);
    properties.addAll(props);
  }

  /// Sets the given [property] when it is not null and otherwises removes the property with the given [propertyName].
  void setOrRemoveProperty(
      final String propertyName, final Property? property) {
    if (property != null) {
      setProperty(property);
    } else {
      removeProperty(propertyName);
    }
  }

  /// Sets or removes the given [props] with the given [propertyName]
  void setOrRemoveProperties(
      final String propertyName, final List<Property>? props) {
    if (props != null) {
      setProperties(propertyName, props);
    } else {
      removeProperty(propertyName);
    }
  }

  /// Removes all properties with the specified [propertyName]
  void removeProperty(final String propertyName) =>
      properties.removeWhere((prop) => prop.name == propertyName);

  /// Parses the component from the specified [text].
  ///
  /// When succeeding, this returns a [VCalendar], [VEvent] or similar component as defined by the given [text].
  /// The [text] can either contain `\r\n` (`CRLF`) or `\n` linebreaks, when both linebreak types are present in the [text], `CRLF` linebreaks are assumed.
  /// Folded lines are unfolded automatically.
  /// When you have a custom line delimiter, use [parseLines] instead.
  static VComponent parse(String text,
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
  static VComponent parseLines(List<String> lines) {
    VComponent root = _createComponent(lines.first);
    VComponent current = root;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('BEGIN:')) {
        final child = _createComponent(line, parent: current);
        current.children.add(child);
        current = child;
      } else if (line.startsWith('END:')) {
        final expected = 'END:${current.name}';
        if (line != expected) {
          throw FormatException('Received [$line] but expected [$expected]');
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
  static VComponent _createComponent(String line, {VComponent? parent}) {
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

  /// Checks if this component can reply in its current state
  ///
  /// Subclasses have to implement this, wenn replies should be possible.
  /// Compare [reply] which needs to be overriden, too.
  bool get canReply => false;

  /// Creates a reply for this component.
  ///
  /// Subclasses have to implement this when they override [canReply].
  /// Compare [canReply]
  VComponent reply(
    AttendeeProperty attendee, {
    VComponent? parent,
    String? comment,
  }) {
    throw StateError('VComponent cannot reply');
  }

  void render(StringBuffer buffer) {
    buffer..write('BEGIN:')..write(name)..write('\r\n');
    for (final property in properties) {
      buffer.write(property.toString());
    }
    for (final component in children) {
      component.render(buffer);
    }
    buffer..write('END:')..write(name)..write('\r\n');
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    render(buffer);
    return buffer.toString();
  }

  /// Creates a new instance of this component
  VComponent instantiate({VComponent? parent});

  /// Copies this component
  VComponent copy() {
    final copied = instantiate();
    _copyInto(copied);
    return copied;
  }

  void _copyInto(VComponent target) {
    for (final prop in properties) {
      target.properties.add(prop.copy());
    }
    for (final child in children) {
      final copiedChild = child.instantiate(parent: target);
      target.children.add(copiedChild);
      child._copyInto(copiedChild);
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
/// The VCalendar is a parent component for others components such as [VEvent], [VTodo] or [VJournal]
class VCalendar extends VComponent {
  static const String componentName = 'VCALENDAR';
  VCalendar({VComponent? parent}) : super(componentName, parent);

  /// Retrieves the scale of the calendar, typically `GREGORIAN`
  ///
  /// Compare [isGregorian]
  String get calendarScale =>
      getProperty<CalendarScaleProperty>(CalendarScaleProperty.propertyName)
          ?.textValue ??
      'GREGORIAN';

  /// Convencience method for getting the first event child, if there is any:
  VEvent? get event => children.firstWhereOrNull(
          (component) => component.componentType == VComponentType.event)
      as VEvent?;

  /// Sets the scale of the calendar
  set calendarScale(String? value) => setOrRemoveProperty(
      CalendarScaleProperty.propertyName, CalendarScaleProperty.create(value));

  /// Checks if this calendar has a Gregorian scale.
  ///
  /// Compare [calendarScale]
  bool get isGregorian => calendarScale == 'GREGORIAN';

  /// Retrieves the method by which answers are expected
  Method? get method =>
      getProperty<MethodProperty>(MethodProperty.propertyName)?.method;

  /// Sets the method to the given value
  set method(Method? value) => setOrRemoveProperty(
      MethodProperty.propertyName, MethodProperty.create(value));

  /// Retrieves the global timezone ID like `America/New_York` or `Europe/Berlin` using the propriety but common `X-WR-TIMEZONE` property.
  ///
  /// Any dates of subsequent components without explicit timezoneId should be interpreted according to this
  /// timezone ID. For caveats compare https://blog.jonudell.net/2011/10/17/x-wr-timezone-considered-harmful/
  String? get timezoneId =>
      getProperty<TextProperty>(TextProperty.propertyNameXWrTimezone)
          ?.textValue;

  /// Sets the `X-WR-TIMEZONE` property
  set timezoneId(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameXWrTimezone,
      TextProperty.create(TextProperty.propertyNameXWrTimezone, value));

  @override
  bool get canReply =>
      method != null && children.any((child) => child.canReply);

  /// Creates a repy with the given [participantStatus] for the attendee with the given [attendeeEmail] or [attendee].
  ///
  /// Optionally specify a [comment] and specify a [productId]
  /// Specify the [delegatedToEmail] when setting the [participantStatus] to [ParticipantStatus.delegated]
  VCalendar replyWithParticipantStatus(
    ParticipantStatus participantStatus, {
    String? attendeeEmail,
    AttendeeProperty? attendee,
    String? comment,
    String productId = 'enough_icalendar',
    String? delegatedToEmail,
  }) {
    assert(attendee != null || attendeeEmail != null,
        'Either [attendee] or [attendeeEmail] must be specified.');
    final reply = VCalendar();
    reply.productId = productId;
    reply.version = '2.0';
    reply.method = Method.reply;
    // check if this attendee was delegated:
    if (attendee == null) {
      Uri? delegatedFrom;
      final childEvent =
          children.firstWhereOrNull((c) => c is VEvent) as VEvent?;
      if (childEvent != null) {
        final existing = childEvent.attendees
            .firstWhereOrNull((a) => a.email == attendeeEmail);
        delegatedFrom = existing?.delegatedFrom;
      }
      attendee = AttendeeProperty.create(
        attendeeEmail: attendeeEmail,
        participantStatus: participantStatus,
        delegatedToEmail: delegatedToEmail,
        delegatedFromUri: delegatedFrom,
      );
    }
    for (final child in children) {
      if (child.canReply) {
        final replyChild =
            child.reply(attendee, comment: comment, parent: reply);
        reply.children.add(replyChild);
        break;
      }
    }
    return reply;
  }

  /// Cancels this VCalendar event.
  ///
  /// Organizers of an calendar event can cancel an event.
  /// Compare [cancelEventForAttendees] when the event should only be cancelled for some attendees
  VCalendar cancelEvent({String? comment}) {
    return update(
      method: Method.cancel,
      comment: comment,
      eventStatus: EventStatus.cancelled,
    );
  }

  /// Cancels this VCalendar event for the specified [cancelledAttendees].
  ///
  /// Organizers of an calendar event can cancel an event for attendees.
  /// You must either specify [cancelledAttendees] or [cancelledAttendeeEmails].
  /// Compare [cancelEvent] in case you want to cancel the whole event
  VCalendar cancelEventForAttendees(
      {List<AttendeeProperty>? cancelledAttendees,
      List<String>? cancelledAttendeeEmails,
      String? comment}) {
    assert(cancelledAttendeeEmails != null || cancelledAttendees != null,
        'You must specify either cancelledAttendees or cancelledAttendeeEmails');
    assert(!(cancelledAttendeeEmails != null && cancelledAttendees != null),
        'You must specify either cancelledAttendees or cancelledAttendeeEmails, but not both');
    return update(
      method: Method.cancel,
      comment: comment,
      attendeeFilter: (attendee) => cancelledAttendeeEmails != null
          ? cancelledAttendeeEmails.contains(attendee.email)
          : cancelledAttendees!.any((a) => a.uri == attendee.uri),
    );
  }

  /// Prepares an update of this calendar.
  ///
  /// An organizer can use this to send an updated version around.
  /// Creates a copy with an updated [VEvent.timeStamp], an increased [VEvent.sequence] and the [method] set to [Method.request].
  /// All parameters are optional and are applied as a convenience.
  VCalendar update({
    Method? method,
    EventStatus? eventStatus,
    String? comment,
    List<AttendeeProperty>? addAttendees,
    List<String>? addAttendeeEmails,
    List<AttendeeProperty>? removeAttendees,
    List<String>? removeAttendesEmails,
    bool Function(AttendeeProperty)? attendeeFilter,
    String? description,
  }) {
    final copied = copy() as VCalendar;
    if (method != null) {
      copied.method = method;
    }
    final event =
        copied.children.firstWhereOrNull((ev) => ev is VEvent) as VEvent?;
    if (event != null) {
      final sequence = event.sequence;
      if (sequence != null) {
        event.sequence = sequence + 1;
      } else {
        event.sequence = 1;
      }
      event.timeStamp = DateTime.now();
      if (eventStatus != null) {
        event.status = eventStatus;
      }
      if (comment != null) {
        event.comment = comment;
      }
      if (addAttendees != null) {
        event.properties.addAll(addAttendees);
      }
      if (addAttendeeEmails != null) {
        for (final email in addAttendeeEmails) {
          event.addAttendee(AttendeeProperty.create(attendeeEmail: email));
        }
      }
      if (removeAttendees != null) {
        for (final prop in removeAttendees) {
          event.removeAttendeeWithUri(prop.uri);
        }
      }
      if (removeAttendesEmails != null) {
        for (final email in removeAttendesEmails) {
          event.removeAttendeeWithEmail(email);
        }
      }
      if (attendeeFilter != null) {
        final attendees = event.attendees;
        for (final attendee in attendees) {
          if (!attendeeFilter(attendee)) {
            event.removeAttendee(attendee);
          }
        }
      }
      if (description != null) {
        event.description = description;
      }
    }
    return copied;
  }

  /// Creates a counter proposal for this calendar.
  ///
  /// Optionally specify the rationale for the change in [comment].
  /// You can also set a different [start], [end], [duration], [location] or [description] directly.
  /// Any other changes have to be done directly on the children of the returned VCalendar.
  /// Any attendee can propose a counter, for example with different time, location or attendees.
  /// The [method] is set to [Method.counter], the [VEvent.sequence] stays the same, but the [VEvent.timeStamp] is updated.
  VCalendar counter({
    String? comment,
    DateTime? start,
    DateTime? end,
    IsoDuration? duration,
    String? location,
    String? description,
  }) {
    final copied = copy() as VCalendar;
    copied.method = Method.counter;
    final event =
        copied.children.firstWhereOrNull((ev) => ev is VEvent) as VEvent?;
    if (event != null) {
      event.timeStamp = DateTime.now();
      if (comment != null) {
        event.comment = comment;
      }
      if (location != null) {
        event.location = location;
      }
      if (start != null) {
        event.start = start;
      }
      if (end != null) {
        event.end = end;
      }
      if (duration != null) {
        event.duration = duration;
      }
      if (description != null) {
        event.description = description;
      }
    }
    return copied;
  }

  /// Declines a counter proposal.
  ///
  /// An organizer can decline the counter proposal and optionally provide the reasoning in the [comment].
  /// When either the [attendee] or [attendeeEmail] is specified, only that attendee will be kept.
  /// When the current [method] must be [Method.counter].
  /// The [sequence] stays the same.
  VCalendar declineCounter(
      {AttendeeProperty? attendee, String? attendeeEmail, String? comment}) {
    assert(method == Method.counter,
        'The current method is not Method.counter but instead $method. Only counter proposals can be declined.');

    final copied = copy() as VCalendar;
    copied.method = Method.declineCounter;
    final event =
        copied.children.firstWhereOrNull((ev) => ev is VEvent) as VEvent?;
    if (event != null) {
      if (comment != null) {
        event.comment = comment;
      }
      if (attendee != null) {
        attendeeEmail = attendee.email;
      }
      if (attendeeEmail != null) {
        event.properties.removeWhere(
            (p) => p is AttendeeProperty && p.email != attendeeEmail);
      }
    }
    return copied;
  }

  /// Delegates this calendar from the user with [fromEmail] to the user [toEmail] / [to].
  ///
  /// The optional parameters [rsvp] and [toStatus] are ignored when [to] is specified.
  /// Optionally explain the reason in the [comment].
  VCalendar delegate({
    required String fromEmail,
    String? toEmail,
    AttendeeProperty? to,
    bool rsvp = true,
    ParticipantStatus? toStatus,
    String? comment,
  }) {
    assert(!(toEmail == null && to == null),
        'Either to or toEmail must be specified.');
    final copied = copy() as VCalendar;
    copied.method = Method.request;
    final event =
        copied.children.firstWhereOrNull((ev) => ev is VEvent) as VEvent?;
    if (event != null) {
      if (comment != null) {
        event.comment = comment;
      }
      event.removeAttendeeWithEmail(fromEmail);
      event.addAttendee(
        AttendeeProperty.create(
          attendeeEmail: fromEmail,
          participantStatus: ParticipantStatus.delegated,
          delegatedToEmail: toEmail,
          delegatedToUri: to?.uri,
        ),
      );
      to ??= AttendeeProperty.create(
        attendeeEmail: toEmail,
        participantStatus: toStatus,
        rsvp: rsvp,
        delegatedFromEmail: fromEmail,
      );
      event.removeAttendeeWithUri(to.uri);
      event.addAttendee(to);
    }
    return copied;
  }

  @override
  VComponent instantiate({VComponent? parent}) {
    return VCalendar(parent: parent);
  }

  static VCalendar createEvent({
    String? organizerEmail,
    OrganizerProperty? organizer,
    List<String>? attendeeEmails,
    List<AttendeeProperty>? attendees,
    bool? rsvp,
    required DateTime start,
    DateTime? end,
    IsoDuration? duration,
    String? location,
    Uri? url,
    String? summary,
    String? description,
    String productId = 'enough_icalendar',
    String? calendarScale,
    String? timezoneId,
    DateTime? timeStamp,
    String? uid,
  }) {
    assert(organizer != null || organizerEmail != null,
        'Either organizer or organizerEmail needs to be specified.');
    assert(attendees != null || attendeeEmails != null,
        'Either attendees or attendeeEmails needs to be specified.');
    assert(end != null || duration != null,
        'Either end or duration must be specified.');
    final calendar = VCalendar()
      ..calendarScale = calendarScale
      ..productId = productId
      ..version = '2.0'
      ..timezoneId = timezoneId;
    final event = VEvent(parent: calendar);
    calendar.children.add(event);
    organizer ??= OrganizerProperty.create(email: organizerEmail);
    event
      ..timeStamp = timeStamp ?? DateTime.now()
      ..uid = uid ?? createUid(organizerUri: organizer!.uri)
      ..start = start
      ..end = end
      ..duration = duration
      ..organizer = organizer
      ..summary = summary
      ..description = description
      ..location = location
      ..url = url
      ..attendees = attendees ??
          attendeeEmails!
              .map((email) =>
                  AttendeeProperty.create(attendeeEmail: email, rsvp: rsvp))
              .toList();
    final test = attendeeEmails!
        .map((email) => AttendeeProperty.create(attendeeEmail: email))
        .toList();
    assert(test.isNotEmpty, 'unable to map attendees');
    return calendar;
  }

  /// Creates a new randomized ID text.
  ///
  /// Specify [length] when a different length than 18 characters should be used.
  /// This can be used as a UID, for example.
  static String _createRandomId({int length = 18, StringBuffer? buffer}) {
    final characters =
        '0123456789_abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final characterRunes = characters.runes.toList();
    final max = characters.length;
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    buffer ??= StringBuffer();
    for (var count = length; count > 0; count--) {
      final charIndex = random.nextInt(max);
      final rune = characterRunes.elementAt(charIndex);
      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  /// Creates a random UID for the given [domain].
  ///
  /// Instead of the [domain] you can also specify the [organizerUri].
  /// When neither the [domain] nor the [organizerUri] is specified, a default domain will be appended.
  static String createUid({String? domain, Uri? organizerUri}) {
    final buffer = StringBuffer();
    _createRandomId(buffer: buffer);
    if (domain == null) {
      if (organizerUri != null) {
        if (organizerUri.host.isNotEmpty) {
          domain = organizerUri.host;
        } else {
          final path = organizerUri.path;
          final atIndex = path.indexOf('@');
          if (atIndex != -1) {
            domain = path.substring(atIndex + 1);
          }
        }
      }
      domain ??= 'enough.de';
    }
    buffer..write('@')..write(domain);
    return buffer.toString();
  }
}

abstract class _UidMandatoryComponent extends VComponent {
  _UidMandatoryComponent(String name, [VComponent? parent])
      : super(name, parent);

  /// Retrieves the UID identifying this calendar component
  String get uid => this[TextProperty.propertyNameUid]!.textValue;

  /// Sets the UID identifying this calendar component
  set uid(String value) =>
      setProperty(TextProperty.create(TextProperty.propertyNameUid, value)!);

  /// Mandatory timestamp / `DTSTAMP` property
  DateTime get timeStamp =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameTimeStamp)!
          .dateTime;

  /// Sets the timeStamp  / `DTSTAMP` property
  set timeStamp(DateTime value) => setProperty(
      DateTimeProperty.create(DateTimeProperty.propertyNameTimeStamp, value)!);

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(TextProperty.propertyNameUid);
    checkMandatoryProperty(DateTimeProperty.propertyNameTimeStamp);
  }
}

abstract class _EventTodoJournalComponent extends _UidMandatoryComponent {
  _EventTodoJournalComponent(String name, VComponent? parent)
      : super(name, parent);

  /// This property defines the access classification for a calendar component
  Classification? get classification =>
      getProperty<ClassificationProperty>(ClassificationProperty.propertyName)
          ?.classification;

  /// Sets the classification
  set classification(Classification? value) => setOrRemoveProperty(
      ClassificationProperty.propertyName,
      ClassificationProperty.create(value));

  /// Retrieves the attachments
  List<AttachmentProperty> get attachments =>
      getProperties<AttachmentProperty>(AttachmentProperty.propertyName)
          .toList();

  /// Sets the attachments
  set attachments(List<AttachmentProperty> value) =>
      setOrRemoveProperties(AttachmentProperty.propertyName, value);

  /// Adds the given [attachment]
  void addAttachment(AttachmentProperty attachment) {
    properties.add(attachment);
  }

  /// Removes the given [attachment] returning `true` when the attachment was found
  bool removeAttachment(AttachmentProperty attachment) {
    return properties.remove(attachment);
  }

  /// Removes the attachment with the given [uri], returning it when it was found.
  AttachmentProperty? removeAttachmentWithUri(Uri uri) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttachmentProperty && p.uri == uri) as AttachmentProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Retrieves the free text categories
  List<String>? get categories =>
      getProperty<CategoriesProperty>(CategoriesProperty.propertyName)
          ?.categories;

  /// Sets the free text categories
  set categories(List<String>? value) => setOrRemoveProperty(
      CategoriesProperty.propertyName, CategoriesProperty.create(value));

  /// Gets the summmary / title
  String? get summary =>
      getProperty<TextProperty>(TextProperty.propertyNameSummary)?.textValue;

  /// Sets the comment
  set summary(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameSummary,
      TextProperty.create(TextProperty.propertyNameSummary, value));

  /// Retrieves the description
  String? get description =>
      getProperty<TextProperty>(TextProperty.propertyNameDescription)?.text;

  /// Sets the description
  set description(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameDescription,
      TextProperty.create(TextProperty.propertyNameDescription, value));

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// Sets the comment
  set comment(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameComment,
      TextProperty.create(TextProperty.propertyNameComment, value));

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Sets the attendees
  set attendees(List<AttendeeProperty> value) =>
      setOrRemoveProperties(AttendeeProperty.propertyName, value);

  /// Adds the given [attendee]
  void addAttendee(AttendeeProperty attendee) {
    properties.add(attendee);
  }

  /// Removes the given [attendee] returning `true` when the attendee was found
  bool removeAttendee(AttendeeProperty attendee) {
    return properties.remove(attendee);
  }

  /// Removes the attendee with the given [uri], returning it when it was found.
  AttendeeProperty? removeAttendeeWithUri(Uri uri) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.uri == uri) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Removes the attendee with the given [email], returning it when it was found.
  AttendeeProperty? removeAttendeeWithEmail(String email) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.email == email) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Retrieves the organizer of this event / task / journal
  OrganizerProperty? get organizer =>
      getProperty<OrganizerProperty>(OrganizerProperty.propertyName);

  /// Sets the organizer of this event / task / journal
  set organizer(OrganizerProperty? value) =>
      setOrRemoveProperty(OrganizerProperty.propertyName, value);

  /// Retrieves the contact for details
  UserProperty? get contact =>
      getProperty<UserProperty>(UserProperty.propertyNameContact);

  /// Sets the contact
  set contact(UserProperty? value) =>
      setOrRemoveProperty(OrganizerProperty.propertyName, value);

  ///  Identifies a particular instance of a recurring event, to-do, or journal.
  ///
  ///  For a given pair of "UID" and "SEQUENCE" property values, the
  /// "RECURRENCE-ID" value for a recurrence instance is fixed.
  DateTime? get recurrenceId =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameRecurrenceId)
          ?.dateTime;

  /// Sets the recurrenceId
  set recurrenceId(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameRecurrenceId,
      DateTimeProperty.create(
          DateTimeProperty.propertyNameRecurrenceId, value));

  /// Retrieves the recurrence rule of this event
  ///
  /// Compare [additionalRecurrenceDates], [excludingRecurrenceDates]
  Recurrence? get recurrenceRule =>
      getProperty<RecurrenceRuleProperty>(RecurrenceRuleProperty.propertyName)
          ?.rule;

  /// Sets the reccurenceRule
  set recurrenceRule(Recurrence? value) => setOrRemoveProperty(
      RecurrenceRuleProperty.propertyName,
      RecurrenceRuleProperty.create(value));

  /// Retrieves additional reccurrence dates or durations as defined in the `RDATE` property
  ///
  /// Compare [excludingRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get additionalRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameRDate)
          ?.dates;

  /// Sets the additional recurrence dates or durations
  set additionalRecurrenceDates(List<DateTimeOrDuration>? value) =>
      setOrRemoveProperty(
          RecurrenceDateProperty.propertyNameRDate,
          RecurrenceDateProperty.create(
              RecurrenceDateProperty.propertyNameRDate, value));

  /// Retrieves excluding reccurrence dates or durations as defined in the `EXDATE` property
  ///
  /// Compare [additionalRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get excludingRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameExDate)
          ?.dates;

  /// Sets exluding recurrence dates or durations
  set excludingRecurrenceDates(List<DateTimeOrDuration>? value) =>
      setOrRemoveProperty(
          RecurrenceDateProperty.propertyNameExDate,
          RecurrenceDateProperty.create(
              RecurrenceDateProperty.propertyNameExDate, value));

  /// Retrieves the UID of a related event, todo or journal.
  String? get relatedTo =>
      getProperty<TextProperty>(TextProperty.propertyNameRelatedTo)?.text;

  /// Sets the UID of the related event, todo or journal
  set relatedTo(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameRelatedTo,
      TextProperty.create(TextProperty.propertyNameRelatedTo, value));

  /// Retrieves the URL for additional information
  Uri? get url => getProperty<UriProperty>(UriProperty.propertyNameUrl)?.uri;

  /// Sets the URL for additional information
  set url(Uri? value) => setOrRemoveProperty(UriProperty.propertyNameUrl,
      UriProperty.create(UriProperty.propertyNameUrl, value));

  /// The creation date
  DateTime? get created =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameCreated)
          ?.dateTime;

  /// Sets the creation date
  set created(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameCreated,
      DateTimeProperty.create(DateTimeProperty.propertyNameCreated, value));

  /// The date of the last modification / update of this event.
  DateTime? get lastModified =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameLastModified)
          ?.dateTime;

  /// Sets the last modification date
  set lastModified(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameLastModified,
      DateTimeProperty.create(
          DateTimeProperty.propertyNameLastModified, value));

  /// Gets the revision sequence number of this component
  int? get sequence =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameSequence)
          ?.intValue;

  /// Sets the sequence
  set sequence(int? value) => setOrRemoveProperty(
      IntegerProperty.propertyNameSequence,
      IntegerProperty.create(IntegerProperty.propertyNameSequence, value));

  /// Retrieves the request status, e.g. `4.1;Event conflict.  Date-time is busy.`
  String? get requestStatus =>
      getProperty<RequestStatusProperty>(RequestStatusProperty.propertyName)
          ?.requestStatus;

  /// Sets the request status
  set requestStatus(String? value) => setOrRemoveProperty(
      RequestStatusProperty.propertyName, RequestStatusProperty.create(value));

  /// Checks if the request status is a success, this defaults to `true` when no `REQUEST-STATUS` is set.
  bool get requestStatusIsSuccess => requestStatus?.startsWith('2.') ?? true;
}

/// Contains information about an event.
class VEvent extends _EventTodoJournalComponent {
  static const String componentName = 'VEVENT';
  VEvent({VComponent? parent}) : super(componentName, parent);

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

  /// Sets the start date (inclusive)
  set start(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameStart,
      DateTimeProperty.create(DateTimeProperty.propertyNameStart, value));

  /// The end date (exclusive) of this event.
  ///
  /// either `DTEND` or `DURATION` may occur, but not both
  /// Compare [duration]
  DateTime? get end =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameEnd)?.dateTime;

  /// Sets the end date (exclusive)
  set end(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameEnd,
      DateTimeProperty.create(DateTimeProperty.propertyNameEnd, value));

  /// The duration of this event.
  ///
  /// either `DTEND` or `DURATION` may occur, but not both
  /// Compare [end]
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// Sets the duration
  set duration(IsoDuration? value) => setOrRemoveProperty(
      DurationProperty.propertyName, DurationProperty.create(value));

  /// The location e.g. room number / name
  String? get location =>
      getProperty<TextProperty>(TextProperty.propertyNameLocation)?.textValue;

  /// Sets the location
  set location(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameLocation,
      TextProperty.create(TextProperty.propertyNameLocation, value));

  /// The geo location of this event.
  GeoLocation? get geoLocation =>
      getProperty<GeoProperty>(GeoProperty.propertyName)?.location;

  /// Sets the geo location
  set geoLocation(GeoLocation? value) =>
      setOrRemoveProperty(GeoProperty.propertyName, GeoProperty.create(value));

  /// Retrieves the transparency of this event in regards to busy time searches.
  TimeTransparency get timeTransparency =>
      getProperty<TimeTransparencyProperty>(
              TimeTransparencyProperty.propertyName)
          ?.transparency ??
      TimeTransparency.opaque;

  /// Sets the time transparency
  set timeTransparency(TimeTransparency? value) => setOrRemoveProperty(
      TimeTransparencyProperty.propertyName,
      TimeTransparencyProperty.create(value));

  /// Retrieves the status of this event
  EventStatus? get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.eventStatus;

  /// Sets the status
  set status(EventStatus? value) => setOrRemoveProperty(
      StatusProperty.propertyName, StatusProperty.createEventStatus(value));

  /// Retrieves the priority as a numeric value between 1 (highest) and 9 (lowest) priority.
  int? get priorityInt =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.intValue;

  /// Sets the priority as a numeric value
  set priorityInt(int? value) => setOrRemoveProperty(
      PriorityProperty.propertyName, PriorityProperty.createNumeric(value));

  /// Retrieves the priority of this event
  Priority? get priority =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.priority;

  /// Sets the priority
  set priority(Priority? value) => setOrRemoveProperty(
      PriorityProperty.propertyName, PriorityProperty.createPriority(value));

  /// Retrieves the resources required for this event
  String? get resources =>
      getProperty<TextProperty>(TextProperty.propertyNameResources)?.text;

  /// Set the resources required for this event
  set resource(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameResources,
      TextProperty.create(TextProperty.propertyNameResources, value));
  // @override
  // void checkValidity() {
  //   super.checkValidity();
  // }

  @override
  bool get canReply => organizer != null;

  @override
  VComponent reply(AttendeeProperty attendee,
      {VComponent? parent, String? comment}) {
    final event = VEvent(parent: parent);
    if (comment != null) {
      event.comment = comment;
    }
    if (sequence != null) {
      event.sequence = sequence;
    }
    event.organizer = organizer;
    event.uid = uid;
    event.properties.add(attendee);
    final delegatedFrom = attendee.delegatedFrom;
    if (delegatedFrom != null) {
      final delegator =
          attendees.firstWhereOrNull((a) => a.uri == delegatedFrom);
      if (delegator != null) {
        event.properties.add(delegator);
      }
    }
    event.timeStamp = DateTime.now();
    event.requestStatus = '2.0;Success';
    return event;
  }

  @override
  VComponent instantiate({VComponent? parent}) {
    return VEvent(parent: parent);
  }
}

class VTodo extends _EventTodoJournalComponent {
  static const String componentName = 'VTODO';
  VTodo({VComponent? parent}) : super(componentName, parent);

  /// The status of this todo
  TodoStatus get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.todoStatus ??
      TodoStatus.unknown;

  /// Sets the status
  set status(TodoStatus? value) => setOrRemoveProperty(
      StatusProperty.propertyName, StatusProperty.createTodoStatus(value));

  /// Retrieves the due date of this task
  DateTime? get due =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameDue)?.dateTime;

  /// Sets the due date
  set due(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameDue,
      DateTimeProperty.create(DateTimeProperty.propertyNameDue, value));

  /// Retrieves the start date of this task
  DateTime? get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)
          ?.dateTime;

  /// Sets the due date
  set start(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameStart,
      DateTimeProperty.create(DateTimeProperty.propertyNameStart, value));

  /// Retrieves the date when this task was completed
  DateTime? get completed =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameCompleted)
          ?.dateTime;

  /// Sets the due date
  set completed(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameCompleted,
      DateTimeProperty.create(DateTimeProperty.propertyNameCompleted, value));

  /// Retrieves the duration of the task
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// Sets the duration
  set duration(IsoDuration? value) => setOrRemoveProperty(
      DurationProperty.propertyName, DurationProperty.create(value));

  /// The geo location of this task.
  GeoLocation? get geoLocation =>
      getProperty<GeoProperty>(GeoProperty.propertyName)?.location;

  /// Sets the geo location
  set geoLocation(GeoLocation? value) =>
      setOrRemoveProperty(GeoProperty.propertyName, GeoProperty.create(value));

  /// The location e.g. room number / name
  String? get location =>
      getProperty<TextProperty>(TextProperty.propertyNameLocation)?.textValue;

  /// Sets the location
  set location(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameLocation,
      TextProperty.create(TextProperty.propertyNameLocation, value));

  /// Retrieves the percentage value between 0 and 100 that shows how much is done of this task,
  ///
  /// 100 means the task is fully done; 0 means the task has not been started.
  int? get percentComplete =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNamePercentComplete)
          ?.intValue;

  /// Sets the percentage between 0 and 100.
  set percentComplete(int? value) => setOrRemoveProperty(
      IntegerProperty.propertyNamePercentComplete,
      IntegerProperty.create(
          IntegerProperty.propertyNamePercentComplete, value));

  /// Retrieves the priority as a numeric value between 1 (highest) and 9 (lowest) priority.
  int? get priorityInt =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.intValue;

  /// Sets the priority as a numeric value
  set priorityInt(int? value) => setOrRemoveProperty(
      PriorityProperty.propertyName, PriorityProperty.createNumeric(value));

  /// Retrieves the priority of this task
  Priority? get priority =>
      getProperty<PriorityProperty>(PriorityProperty.propertyName)?.priority;

  /// Sets the priority
  set priority(Priority? value) => setOrRemoveProperty(
      PriorityProperty.propertyName, PriorityProperty.createPriority(value));

  /// Retrieves the resources required for this task
  String? get resources =>
      getProperty<TextProperty>(TextProperty.propertyNameResources)?.text;

  /// Set the resources required for this event
  set resource(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameResources,
      TextProperty.create(TextProperty.propertyNameResources, value));

  @override
  VComponent instantiate({VComponent? parent}) {
    return VTodo(parent: parent);
  }
}

class VJournal extends _EventTodoJournalComponent {
  static const String componentName = 'VJOURNAL';
  VJournal({VComponent? parent}) : super(componentName, parent);

  /// The status of this journal entry
  JournalStatus get status =>
      getProperty<StatusProperty>(StatusProperty.propertyName)?.journalStatus ??
      JournalStatus.unknown;

  /// Sets the status
  set status(JournalStatus? value) => setOrRemoveProperty(
      StatusProperty.propertyName, StatusProperty.createJournalStatus(value));

  @override
  VComponent instantiate({VComponent? parent}) {
    return VJournal(parent: parent);
  }
}

class VTimezone extends VComponent {
  static const String componentName = 'VTIMEZONE';
  VTimezone({VComponent? parent}) : super(componentName, parent);

  /// Retrieves the ID such as `America/New_York` or `Europe/Berlin`
  String get timezoneId =>
      getProperty<TextProperty>(TextProperty.propertyNameTimezoneId)!.textValue;

  /// Sets the timezone ID
  set timezoneId(String value) => setProperty(
      TextProperty.create(TextProperty.propertyNameTimezoneId, value)!);

  /// Retrieves the optional URL for more information
  Uri? get url =>
      getProperty<UriProperty>(UriProperty.propertyNameTimezoneUrl)?.uri;

  /// Retrieves the optional URL for more information
  set url(Uri? value) => setOrRemoveProperty(
      UriProperty.propertyNameTimezoneUrl,
      UriProperty.create(UriProperty.propertyNameTimezoneUrl, value));

  /// The date of the last modification / update of this timezone.
  DateTime? get lastModified =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameLastModified)
          ?.dateTime;

  /// Sets the last modification date
  set lastModified(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameLastModified,
      DateTimeProperty.create(
          DateTimeProperty.propertyNameLastModified, value));

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
      if (phase.componentType == VComponentType.timezonePhaseStandard) {
        numberOfStandardChildren++;
      } else if (phase.componentType == VComponentType.timezonePhaseDaylight) {
        numberOfDaylightChildren++;
      }
    }
    if (numberOfStandardChildren == 0 || numberOfDaylightChildren == 0) {
      throw FormatException(
          'A valid VTIMEZONE requires at least one STANDARD and one DAYLIGHT sub-component');
    }
  }

  @override
  VComponent instantiate({VComponent? parent}) {
    return VTimezone(parent: parent);
  }
}

/// Contains the standard or daylight timezone subcomponent
class VTimezonePhase extends VComponent {
  static const String componentNameStandard = 'STANDARD';
  static const String componentNameDaylight = 'DAYLIGHT';

  VTimezonePhase(String componentName, {required VTimezone parent})
      : super(componentName, parent);

  /// Gets the start datetime of this phase
  DateTime get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)!
          .dateTime;

  /// Sets the last modification date
  set start(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameStart,
      DateTimeProperty.create(DateTimeProperty.propertyNameStart, value));

  /// Gets the UTC offset before this phase
  UtcOffset get from => getProperty<UtfOffsetProperty>(
          UtfOffsetProperty.propertyNameTimezoneOffsetFrom)!
      .offset;

  /// Sets the UTC offset before this phase
  set from(UtcOffset value) => setProperty(UtfOffsetProperty.create(
      UtfOffsetProperty.propertyNameTimezoneOffsetFrom, value)!);

  /// Gets the UTC offset during this phase
  UtcOffset get to => getProperty<UtfOffsetProperty>(
          UtfOffsetProperty.propertyNameTimezoneOffsetTo)!
      .offset;

  /// Sets the UTC offset during this phase
  set to(UtcOffset value) => setProperty(UtfOffsetProperty.create(
      UtfOffsetProperty.propertyNameTimezoneOffsetTo, value)!);

  //TODO the name property can occur more than once in theory
  /// Retrieves the (first) name of the timezone
  String? get timezoneName =>
      getProperty<TextProperty>(TextProperty.propertyNameTimezoneName)
          ?.textValue;

  /// Sets the timezone's name
  set timezoneName(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameTimezoneName,
      TextProperty.create(TextProperty.propertyNameTimezoneName, value));

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// Sets the comment
  set comment(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameComment,
      TextProperty.create(TextProperty.propertyNameComment, value));

  /// Retrieves the recurrence rule of this event
  ///
  /// Compare [additionalRecurrenceDates], [excludingRecurrenceDates]
  Recurrence? get recurrenceRule =>
      getProperty<RecurrenceRuleProperty>(RecurrenceRuleProperty.propertyName)
          ?.rule;

  /// Sets the reccurenceRule
  set recurrenceRule(Recurrence? value) => setOrRemoveProperty(
      RecurrenceRuleProperty.propertyName,
      RecurrenceRuleProperty.create(value));

  /// Retrieves additional reccurrence dates or durations as defined in the `RDATE` property
  ///
  /// Compare [excludingRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get additionalRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameRDate)
          ?.dates;

  /// Sets the additional recurrence dates or durations
  set additionalRecurrenceDates(List<DateTimeOrDuration>? value) =>
      setOrRemoveProperty(
          RecurrenceDateProperty.propertyNameRDate,
          RecurrenceDateProperty.create(
              RecurrenceDateProperty.propertyNameRDate, value));

  /// Retrieves excluding reccurrence dates or durations as defined in the `EXDATE` property
  ///
  /// Compare [additionalRecurrenceDates], [recurrenceRule]
  List<DateTimeOrDuration>? get excludingRecurrenceDates =>
      getProperty<RecurrenceDateProperty>(
              RecurrenceDateProperty.propertyNameExDate)
          ?.dates;

  /// Sets exluding recurrence dates or durations
  set excludingRecurrenceDates(List<DateTimeOrDuration>? value) =>
      setOrRemoveProperty(
          RecurrenceDateProperty.propertyNameExDate,
          RecurrenceDateProperty.create(
              RecurrenceDateProperty.propertyNameExDate, value));

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(DateTimeProperty.propertyNameStart);
    checkMandatoryProperty(UtfOffsetProperty.propertyNameTimezoneOffsetFrom);
    checkMandatoryProperty(UtfOffsetProperty.propertyNameTimezoneOffsetTo);
  }

  @override
  VComponent instantiate({VComponent? parent}) {
    return VTimezonePhase(name, parent: parent as VTimezone);
  }
}

/// Contains an alarm definition with a trigger ([triggerDate] or [triggerRelativeDuration]) and an [action].
class VAlarm extends VComponent {
  static const String componentName = 'VALARM';
  VAlarm({VComponent? parent}) : super(componentName, parent);

  /// Retrieves the date of the trigger.
  ///
  /// Compare [triggerRelativeDuration] for the alternative relative duration
  DateTime? get triggerDate =>
      getProperty<TriggerProperty>(TriggerProperty.propertyName)?.dateTime;

  /// Sets the trigger date time
  set triggerDate(DateTime? value) => setOrRemoveProperty(
      TriggerProperty.propertyName, TriggerProperty.createWithDateTime(value));

  /// Retrieves the relative duration of the trigger, e.g. -15 minutes (`-PT15M`) as a reminder before an event starts.
  ///
  /// Compare [triggerDate] for a fixed date.
  /// Compare [triggerRelation] to see if the [triggerRelativeDuration] is calculated in relation to the [VEvent.start] or [VEvent.end] time.
  IsoDuration? get triggerRelativeDuration =>
      getProperty<TriggerProperty>(TriggerProperty.propertyName)?.duration;

  /// Sets the trigger relative duration
  set triggerRelativeDuration(IsoDuration? value) => setOrRemoveProperty(
      TriggerProperty.propertyName, TriggerProperty.createWithDuration(value));

  /// Resolves if the [triggerRelativeDuration] is calculated in relation to the [VEvent.start] or [VEvent.end] time.
  ///
  /// Defaults to [VEvent.start] / [AlarmTriggerRelationship.start].
  /// Compare [triggerRelativeDuration]
  AlarmTriggerRelationship get triggerRelation =>
      getProperty<TriggerProperty>(TriggerProperty.propertyName)
          ?.triggerRelation ??
      AlarmTriggerRelationship.start;

  /// Sets the trigger, this is useful when you also want to specify the [AlarmTriggerRelationship], for example
  set trigger(TriggerProperty? value) =>
      setOrRemoveProperty(TriggerProperty.propertyName, value);

  /// How often the alarm can be repeated, defaults to `0`, ie no additional repeats after the first alaram.
  int get repeat =>
      getProperty<IntegerProperty>(IntegerProperty.propertyNameRepeat)
          ?.intValue ??
      0;

  /// Sets the number of repeats
  set repeat(int? value) => setOrRemoveProperty(
      IntegerProperty.propertyNameRepeat,
      IntegerProperty.create(IntegerProperty.propertyNameRepeat, value));

  /// Retrieves the action in case it is one described by the icalendar standard or  [AlarmAction.other] in other cases.
  ///
  /// Compare [actionText] in case of a non-standard alarm action.
  AlarmAction get action =>
      getProperty<ActionProperty>(ActionProperty.propertyName)?.action ??
      AlarmAction.other;

  /// Sets the action
  set action(AlarmAction? value) => setOrRemoveProperty(
      ActionProperty.propertyName, ActionProperty.createWithAction(value));

  /// Retrieve the alarm action as a text.
  ///
  /// Compare [action] for easier retrieval in case of a standardized action.
  String? get actionText =>
      getProperty<ActionProperty>(ActionProperty.propertyName)?.textValue;

  /// Sets the action
  set actionText(String? value) => setOrRemoveProperty(
      ActionProperty.propertyName, ActionProperty.createWithActionText(value));

  /// Retrieves the duration of the alarm
  IsoDuration? get duration =>
      getProperty<DurationProperty>(DurationProperty.propertyName)?.duration;

  /// Sets the duration
  set duration(IsoDuration? value) => setOrRemoveProperty(
      DurationProperty.propertyName, DurationProperty.create(value));

  /// Retrieves the attachments
  ///
  /// In case the [action] is an [AlarmAction.audio], one attachment describing the audio is expected.
  List<AttachmentProperty> get attachments =>
      getProperties<AttachmentProperty>(AttachmentProperty.propertyName)
          .toList();

  /// Sets the attachments
  set attachments(List<AttachmentProperty> value) =>
      setOrRemoveProperties(AttachmentProperty.propertyName, value);

  /// Adds the given [attachment]
  void addAttachment(AttachmentProperty attachment) {
    properties.add(attachment);
  }

  /// Removes the given [attachment] returning `true` when the attachment was found
  bool removeAttachment(AttachmentProperty attachment) {
    return properties.remove(attachment);
  }

  /// Removes the attachment with the given [uri], returning it when it was found.
  AttachmentProperty? removeAttachmentWithUri(Uri uri) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttachmentProperty && p.uri == uri) as AttachmentProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Gets the summmary / title
  String? get summary =>
      getProperty<TextProperty>(TextProperty.propertyNameSummary)?.textValue;

  /// Sets the comment
  set summary(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameSummary,
      TextProperty.create(TextProperty.propertyNameSummary, value));

  /// Retrieves the description
  String? get description =>
      getProperty<TextProperty>(TextProperty.propertyNameDescription)?.text;

  /// Sets the description
  set description(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameDescription,
      TextProperty.create(TextProperty.propertyNameDescription, value));

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Sets the attendees
  set attendees(List<AttendeeProperty> value) =>
      setOrRemoveProperties(AttendeeProperty.propertyName, value);

  /// Adds the given [attendee]
  void addAttendee(AttendeeProperty attendee) {
    properties.add(attendee);
  }

  /// Removes the given [attendee] returning `true` when the attendee was found
  bool removeAttendee(AttendeeProperty attendee) {
    return properties.remove(attendee);
  }

  /// Removes the attendee with the given [uri], returning it when it was found.
  AttendeeProperty? removeAttendeeWithUri(Uri uri) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.uri == uri) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Removes the attendee with the given [email], returning it when it was found.
  AttendeeProperty? removeAttendeeWithEmail(String email) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.email == email) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  @override
  void checkValidity() {
    super.checkValidity();
    checkMandatoryProperty(TriggerProperty.propertyName);
    checkMandatoryProperty(ActionProperty.propertyName);
  }

  @override
  VComponent instantiate({VComponent? parent}) {
    return VAlarm(parent: parent);
  }
}

/// Provides information about free and busy times of a particular user
class VFreeBusy extends _UidMandatoryComponent {
  static const String componentName = 'VFREEBUSY';
  VFreeBusy({VComponent? parent}) : super(componentName, parent);

  /// Retrieves the list of free busy entries
  List<FreeBusyProperty> get freeBusyProperties =>
      getProperties<FreeBusyProperty>(FreeBusyProperty.propertyName).toList();

  /// Set the free busy entries
  set freeBusyProperties(List<FreeBusyProperty> value) =>
      setOrRemoveProperties(FreeBusyProperty.propertyName, value);

  /// Retrieves the comment
  String? get comment =>
      getProperty<TextProperty>(TextProperty.propertyNameComment)?.text;

  /// Sets the comment
  set comment(String? value) => setOrRemoveProperty(
      TextProperty.propertyNameComment,
      TextProperty.create(TextProperty.propertyNameComment, value));

  /// The start time (inclusive) of the free busy time.
  DateTime? get start =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameStart)
          ?.dateTime;

  /// Sets the start date (inclusive)
  set start(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameStart,
      DateTimeProperty.create(DateTimeProperty.propertyNameStart, value));

  /// The end date (exclusive) of this event.
  ///
  /// either `DTEND` or `DURATION` may occur, but not both
  /// Compare [duration]
  DateTime? get end =>
      getProperty<DateTimeProperty>(DateTimeProperty.propertyNameEnd)?.dateTime;

  /// Sets the end date (exclusive)
  set end(DateTime? value) => setOrRemoveProperty(
      DateTimeProperty.propertyNameEnd,
      DateTimeProperty.create(DateTimeProperty.propertyNameEnd, value));

  /// Retrieves the contact for details
  UserProperty? get contact =>
      getProperty<UserProperty>(UserProperty.propertyNameContact);

  /// Sets the contact
  set contact(UserProperty? value) =>
      setOrRemoveProperty(OrganizerProperty.propertyName, value);

  /// Retrieves the request status, e.g. `4.1;Event conflict.  Date-time is busy.`
  String? get requestStatus =>
      getProperty<RequestStatusProperty>(RequestStatusProperty.propertyName)
          ?.requestStatus;

  /// Sets the request status
  set requestStatus(String? value) => setOrRemoveProperty(
      RequestStatusProperty.propertyName, RequestStatusProperty.create(value));

  /// Checks if the request status is a success, this defaults to `true` when no `REQUEST-STATUS` is set.
  bool get requestStatusIsSuccess => requestStatus?.startsWith('2.') ?? true;

  /// Retrieves the URL for additional information
  Uri? get url => getProperty<UriProperty>(UriProperty.propertyNameUrl)?.uri;

  /// Retrieves the attendees
  List<AttendeeProperty> get attendees =>
      getProperties<AttendeeProperty>(AttendeeProperty.propertyName).toList();

  /// Sets the attendees
  set attendees(List<AttendeeProperty> value) =>
      setOrRemoveProperties(AttendeeProperty.propertyName, value);

  /// Adds the given [attendee]
  void addAttendee(AttendeeProperty attendee) {
    properties.add(attendee);
  }

  /// Removes the given [attendee] returning `true` when the attendee was found
  bool removeAttendee(AttendeeProperty attendee) {
    return properties.remove(attendee);
  }

  /// Removes the attendee with the given [uri], returning it when it was found.
  AttendeeProperty? removeAttendeeWithUri(Uri uri) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.uri == uri) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Removes the attendee with the given [email], returning it when it was found.
  AttendeeProperty? removeAttendeeWithEmail(String email) {
    final match = properties.firstWhereOrNull(
        (p) => p is AttendeeProperty && p.email == email) as AttendeeProperty?;
    if (match != null) {
      properties.remove(match);
    }
    return match;
  }

  /// Retrieves the organizer of this event / task / journal
  OrganizerProperty? get organizer =>
      getProperty<OrganizerProperty>(OrganizerProperty.propertyName);

  /// Sets the organizer of this event / task / journal
  set organizer(OrganizerProperty? value) =>
      setOrRemoveProperty(OrganizerProperty.propertyName, value);

  @override
  VComponent instantiate({VComponent? parent}) {
    return VFreeBusy(parent: parent);
  }
}
