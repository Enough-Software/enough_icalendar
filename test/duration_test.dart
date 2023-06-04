import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:test/test.dart';

void main() {
  test('Google formatting', () {
    // compare https://github.com/Enough-Software/enough_icalendar/issues/2
    const textValue = 'P0DT3H0M0S';
    final duration = IsoDuration.parse(textValue);
    expect(duration.months, 0);
    expect(duration.weeks, 0);
    expect(duration.days, 0);
    expect(duration.hours, 3);
    expect(duration.minutes, 0);
    expect(duration.seconds, 0);
  });
}
