# enough_icalendar
icalendar library in pure Dart. Fully compliant with [RFC 5545](https://datatracker.ietf.org/doc/html/rfc5545).

## Usage

Using `enough_icalendar` is pretty straight forward:

```dart
import 'package:enough_icalendar/enough_icalendar.dart';

void main() {
  final text = ''  final text = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
UID:uid1@example.com
DTSTAMP:19970714T170000Z
ORGANIZER;CN=John Doe:MAILTO:john.doe@example.com
DTSTART:19970714T170000Z
DTEND:19970715T035959Z
SUMMARY:Bastille Day Party
GEO:48.85299;2.36885
END:VEVENT
END:VCALENDAR''';
  final icalendar = VComponent.parse(text) as VCalendar;
  print(icalendar.productId); // -//hacksw/handcal//NONSGML v1.0//EN
  final event = icalendar.children.first as VEvent;
  print(event.summary); // Bastille Day Party
  print(event.start); // 1997-06-14 at 17:00
  print(event.end); // 1997-07-15 at 03:59:59
  print(event.organizer?.commonName); // John Doe
  print(event.organizer?.email); // john.doe@example.com
  print(event.geoLocation?.latitude); // 48.85299
  print(event.geoLocation?.longitude); // 2.36885
}
```

## Installation
Add this dependency your pubspec.yaml file:

```
dependencies:
  enough_icalendar: ^0.2.0
```
The latest version or `enough_icalendar` is [![enough_icalendar version](https://img.shields.io/pub/v/enough_icalendar.svg)](https://pub.dartlang.org/packages/enough_icalendar).



## API Documentation
Check out the full API documentation at https://pub.dev/documentation/enough_icalendar/latest/


## Features and bugs

`enough_icalendar` supports all icalendar components and provides easy to access models:
* `VCALENDAR` 
* `VEVENT` 
* `VTIMEZONE` with the `STANDARD` and `DAYLIGHT` subcomponents
* `VALARM`
* `VFREEBUSY`
* `VTODO`
* `VJOURNAL`


Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Enough-Software/enough_icalendar/issues

## Null-Safety
`enough_icalendar` is null-safe.

## License
`enough_icalendar` is licensed under the commercial friendly [Mozilla Public License 2.0](LICENSE)

