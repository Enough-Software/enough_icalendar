import 'package:enough_icalendar/enough_icalendar.dart';

void main() {
  final text = '''BEGIN:VCALENDAR
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
  final icalendar = Component.parse(text) as VCalendar;
  print(icalendar.productId);
  final event = icalendar.children.first as VEvent;
  print(event.summary); // Bastille Day Party
  print(event.start); // 1997-06-14 at 17:00
  print(event.end); // 1997-07-15 at 03:59:59
  print(event.organizer?.commonName); // John Doe
  print(event.organizer?.email); // john.doe@example.com
  print(event.geoLocation?.latitude); // 48.85299
  print(event.geoLocation?.longitude); // 2.36885
}
