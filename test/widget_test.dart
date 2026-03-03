import 'package:flutter_test/flutter_test.dart';
import 'package:rumi_ishi_expense_tracker/models/expense_model.dart';
import 'package:rumi_ishi_expense_tracker/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validatePhone accepts valid E.164 numbers', () {
      expect(Validators.validatePhone('+1234567890'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
    });

    test('validateAmount accepts positive numbers', () {
      expect(Validators.validateAmount('100'), isNull);
      expect(Validators.validateAmount('0'), isNotNull);
      expect(Validators.validateAmount('abc'), isNotNull);
    });

    test('validateOtp accepts 6-digit codes', () {
      expect(Validators.validateOtp('123456'), isNull);
      expect(Validators.validateOtp('12345'), isNotNull);
    });
  });

  group('ExpenseModel', () {
    test('categories list is not empty', () {
      expect(ExpenseModel.categories.isNotEmpty, isTrue);
    });

    test('categoryIcons contains known categories', () {
      expect(ExpenseModel.categoryIcons.containsKey('Food'), isTrue);
    });
  });
}
