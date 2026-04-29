import 'package:flutter_test/flutter_test.dart';
import 'package:studytrack/core/utils/validators.dart';

void main() {
  group('Validators.requiredField', () {
    test('returns null for a non-empty string', () {
      expect(Validators.requiredField('hello'), isNull);
    });

    test('returns null for a string with only non-space characters', () {
      expect(Validators.requiredField('a'), isNull);
    });

    test('returns error message for an empty string', () {
      expect(Validators.requiredField(''), isNotNull);
    });

    test('returns error message for a whitespace-only string', () {
      expect(Validators.requiredField('   '), isNotNull);
    });

    test('returns error message for null', () {
      expect(Validators.requiredField(null), isNotNull);
    });

    test('error message matches expected text', () {
      expect(Validators.requiredField(''), 'This field is required');
    });
  });
}
