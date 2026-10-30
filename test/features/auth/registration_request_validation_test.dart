import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/auth/registration_request_validation.dart';

void main() {
  group('RegistrationRequestValidation', () {
    test('requires non-empty values', () {
      expect(RegistrationRequestValidation.required(null), isNotNull);
      expect(RegistrationRequestValidation.required('  '), isNotNull);
      expect(RegistrationRequestValidation.required('value'), isNull);
    });

    test('validates email format', () {
      expect(RegistrationRequestValidation.email(''), isNotNull);
      expect(RegistrationRequestValidation.email('not-an-email'), isNotNull);
      expect(RegistrationRequestValidation.email('person@example.com'), isNull);
    });

    test('requires matching password confirmation', () {
      expect(
        RegistrationRequestValidation.confirmation(
          password: 'secret',
          confirmation: '',
        ),
        isNotNull,
      );
      expect(
        RegistrationRequestValidation.confirmation(
          password: 'secret',
          confirmation: 'different',
        ),
        'Passwords do not match.',
      );
      expect(
        RegistrationRequestValidation.confirmation(
          password: 'secret',
          confirmation: 'secret',
        ),
        isNull,
      );
    });
  });
}
