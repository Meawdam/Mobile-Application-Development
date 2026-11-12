import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/user/shared/item_validators.dart';

void main() {
  test('name requires a non-empty value', () {
    expect(ItemValidators.name(''), isNotNull);
    expect(ItemValidators.name('Camera'), isNull);
  });

  test('price must be a non-negative whole number', () {
    expect(ItemValidators.price('12.5'), isNotNull);
    expect(ItemValidators.price('-1'), isNotNull);
    expect(ItemValidators.price('120'), isNull);
  });

  test('deposit may be empty and otherwise must be non-negative', () {
    expect(ItemValidators.deposit(''), isNull);
    expect(ItemValidators.deposit('-5'), isNotNull);
    expect(ItemValidators.parseDeposit(''), 0);
    expect(ItemValidators.parseDeposit('12.5'), 12.5);
  });

  test('returnBefore must be today or later', () {
    final now = DateTime(2026, 11, 12);
    expect(ItemValidators.returnBefore(DateTime(2026, 11, 11), now), isNotNull);
    expect(ItemValidators.returnBefore(DateTime(2026, 11, 12), now), isNull);
  });
}
