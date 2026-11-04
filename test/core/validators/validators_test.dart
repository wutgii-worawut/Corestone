import 'package:corestone/core/validators/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email is required', () {
    expect(validateEmail(''), FieldError.required);
    expect(validateEmail('   '), FieldError.required);
  });

  test('email must look like an address', () {
    for (final bad in ['demo', 'demo@', 'demo@corestone', '@corestone.dev']) {
      expect(validateEmail(bad), FieldError.invalidEmail, reason: bad);
    }
  });

  test('a well-formed email passes, ignoring outer spaces', () {
    expect(validateEmail('demo@corestone.dev'), isNull);
    expect(validateEmail(' first.last+tag@mail.co.th '), isNull);
  });

  test('password is required and has no other sign-in rule', () {
    expect(validatePassword(''), FieldError.required);
    expect(validatePassword(' '), isNull);
    expect(validatePassword('x'), isNull);
  });
}
