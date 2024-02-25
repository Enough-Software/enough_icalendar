import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:test/test.dart';

void main() {
  test('trigger date', () {
    final alarm = VAlarm()
      ..triggerDate = DateTime.utc(2024, 02, 25, 05, 00, 00);
    expect(alarm.triggerDate, isNotNull);
    expect(
      alarm.toString(),
      // cSpell:ignore VALARM
      'BEGIN:VALARM\r\n'
      'TRIGGER;VALUE=DATE-TIME:20240225T050000Z\r\n'
      'END:VALARM\r\n',
    );
  });
}
