import 'package:flutter_test/flutter_test.dart';

// Helper validator function for testing
String? validateAmount(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter amount';
  }
  
  final amount = double.tryParse(value);
  if (amount == null) {
    return 'Enter a valid number';
  }
  
  if (amount <= 0) {
    return 'Amount must be greater than 0';
  }
  
  if (amount > 1000000) {
    return 'Amount too large';
  }
  
  return null;
}

void main() {
  group('Amount Validator Tests', () {
    test('returns error for null input', () {
      expect(validateAmount(null), 'Enter amount');
    });

    test('returns error for empty string', () {
      expect(validateAmount(''), 'Enter amount');
    });

    test('returns error for invalid number', () {
      expect(validateAmount('abc'), 'Enter a valid number');
      expect(validateAmount('12.34.56'), 'Enter a valid number');
    });

    test('returns error for zero amount', () {
      expect(validateAmount('0'), 'Amount must be greater than 0');
      expect(validateAmount('-100'), 'Amount must be greater than 0');
    });

    test('returns error for amount too large', () {
      expect(validateAmount('1000001'), 'Amount too large');
    });

    test('returns null for valid amounts', () {
      expect(validateAmount('100'), null);
      expect(validateAmount('1000.50'), null);
      expect(validateAmount('999999'), null);
    });
  });
}

