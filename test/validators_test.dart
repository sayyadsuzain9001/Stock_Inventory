import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/utils/validators.dart';

void main() {
  group('SKU', () {
    test('accepts STK- plus 3 digits', () {
      expect(validateSku('STK-101'), isNull);
      expect(validateSku('  STK-999 '), isNull);
    });
    test('rejects malformed SKUs', () {
      for (final bad in [
        '',
        'STK101',
        'STK-10',
        'STK-1011',
        'ABC-101',
        'STK-1A1',
      ]) {
        expect(validateSku(bad), isNotNull, reason: bad);
      }
    });
  });

  test('item name needs at least 3 trimmed characters', () {
    expect(validateItemName('  ab  '), contains('at least 3'));
    expect(validateItemName(''), contains('required'));
    expect(validateItemName('Pen'), isNull);
  });

  test('category must be one of the four', () {
    expect(validateCategory(null), isNotNull);
    expect(validateCategory('Toys'), isNotNull);
    for (final c in kCategories) {
      expect(validateCategory(c), isNull);
    }
  });

  test('quantity and reorder level are non-negative whole numbers', () {
    expect(validateQuantity('0'), isNull);
    expect(validateQuantity('25'), isNull);
    expect(validateQuantity('-1'), contains('negative'));
    expect(validateQuantity('4.5'), contains('whole number'));
    expect(validateQuantity('abc'), contains('whole number'));
    expect(validateQuantity(''), contains('required'));
    expect(validateReorderLevel('-3'), contains('Reorder level'));
  });

  test('unit price must be greater than 0', () {
    expect(validateUnitPrice('19.90'), isNull);
    expect(validateUnitPrice('35'), isNull);
    expect(validateUnitPrice(''), contains('required'));
    expect(validateUnitPrice('0'), contains('greater than'));
    expect(validateUnitPrice('-2'), contains('greater than'));
    expect(validateUnitPrice('abc'), contains('valid'));
    expect(validateUnitPrice('NaN'), contains('valid'));
    expect(validateUnitPrice('1.999'), contains('2 decimal'));
  });
}
