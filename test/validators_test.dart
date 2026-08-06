import 'package:flutter_test/flutter_test.dart';
import 'package:globelink_driver/core/utils/validators.dart';

void main() {
  group('Validators - Password Validation', () {
    test('should return error if password is empty or null', () {
      expect(Validators.validatePassword(null), 'Enter your password');
      expect(Validators.validatePassword(''), 'Enter your password');
    });

    test('should return error if password is less than 6 characters', () {
      expect(
        Validators.validatePassword('Ab1@'),
        'Password must be at least 6 characters',
      );
    });

    test('should return error if password has no capital letter', () {
      expect(
        Validators.validatePassword('shinchan_nohara2@'),
        'Password must contain at least one capital letter',
      );
    });

    test('should return error if password has no small letter', () {
      expect(
        Validators.validatePassword('SHINCHAN_NOHARA2@'),
        'Password must contain at least one small letter',
      );
    });

    test('should return error if password has no number', () {
      expect(
        Validators.validatePassword('Shinchan_nohara@'),
        'Password must contain at least one number',
      );
    });

    test('should return error if password has no special character', () {
      expect(
        Validators.validatePassword('ShinchanNohara2'),
        'Password must contain at least one special character',
      );
    });

    test('should return null for a valid password', () {
      expect(Validators.validatePassword('Shinchan_nohara2@yopmail.com'), null);
      expect(Validators.validatePassword('Shinchan_nohara2@'), null);
    });
  });

  group('Validators - Email Validation', () {
    test('should return error if email is empty or null', () {
      expect(Validators.validateEmail(null), 'Enter email address');
      expect(Validators.validateEmail(''), 'Enter email address');
    });

    test('should return error if email is invalid', () {
      expect(
        Validators.validateEmail('shinchan'),
        'Enter a valid email address',
      );
      expect(
        Validators.validateEmail('shinchan@yopmail'),
        'Enter a valid email address',
      );
    });

    test('should return null for a valid email', () {
      expect(Validators.validateEmail('shinchan_nohara@yopmail.com'), null);
    });
  });
}
