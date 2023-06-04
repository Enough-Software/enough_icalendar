import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:test/test.dart';

void main() {
  test('Calendar simple', () {
    const text =
        '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
X-XXX-NUMBER:123
BEGIN:VEVENT
UID:19970610T172345Z-AF23B2@example.com
DTSTAMP:19970610T172345Z
DTSTART:19970714T170000Z
DTEND:19970715T040000Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR''';
    // final calendar = VComponent.parse(text);
    final calendar = VComponent.parse(text, customParser: (name, definition) {
      if (name == 'X-XXX-NUMBER') {
        return IntegerProperty(definition);
      }
      return null;
    });
    expect(calendar, isA<VCalendar>());
    expect(calendar.children, isNotEmpty);
    expect(calendar.getProperty('X-XXX-NUMBER'), isA<IntegerProperty>());
    expect(
        calendar.getProperty<IntegerProperty>('X-XXX-NUMBER')?.intValue, 123);
  });
}
