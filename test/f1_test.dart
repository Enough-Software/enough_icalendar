import 'dart:io';

import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:test/test.dart';

// cSpell:disable
void main() {
  test('unfold lines with various line splits', () {
    final file = File('test/f1.ics');
    final input = file.readAsStringSync();
    final parsed = VComponent.unfold(input);
    expect(parsed, isNotEmpty);
    expect(parsed.length, 3162);

    for (var i = 0; i < parsed.length; i++) {
      final line = parsed[i];
      expect(line, isNotEmpty);
      expect(
        line.endsWith('\n'),
        isFalse,
        reason: '$i: "$line" ends with unix linebreak',
      );
      expect(
        line.endsWith('\r\n'),
        isFalse,
        reason: '$i: "$line" ends with standard linebreak',
      );
      expect(
        line.endsWith('\r'),
        isFalse,
        reason: '$i: "$line" ends with r',
      );
    }
  });

  test('parse vcalendard with various line splits', () {
    final file = File('test/f1.ics');
    final input = file.readAsStringSync();
    final parsed = VComponent.parse(input);
    expect(parsed, isA<VCalendar>());
  });
}
