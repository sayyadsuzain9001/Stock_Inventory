/// Validation rules for the stock entry form. Pure functions so they can be
/// unit tested. Each returns `null` when valid or a field-level message.
library;

const List<String> kCategories = [
  'Electronics',
  'Stationery',
  'Hardware',
  'Grocery',
];

final RegExp _skuPattern = RegExp(r'^STK-\d{3}$');
final RegExp _wholeNumber = RegExp(r'^-?\d+$');
final RegExp _decimalNumber = RegExp(r'^-?\d+(\.\d+)?$');

/// SKU: "STK-" followed by exactly three digits, e.g. STK-101.
String? validateSku(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'SKU is required';
  if (!_skuPattern.hasMatch(v)) {
    return 'SKU must be STK- followed by 3 digits, e.g. STK-101';
  }
  return null;
}

/// Item name: trimmed, at least 3 characters.
String? validateItemName(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Item name is required';
  if (v.length < 3) return 'Item name must be at least 3 characters';
  return null;
}

/// Category: must be one of the four permitted categories.
String? validateCategory(String? value) {
  if (value == null || value.isEmpty) return 'Please select a category';
  if (!kCategories.contains(value)) return 'Please select a valid category';
  return null;
}

/// Quantity / reorder level: whole number, 0 or above.
String? validateWholeNumber(String? value, String label) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '$label is required';
  if (!_wholeNumber.hasMatch(v)) {
    if (_decimalNumber.hasMatch(v)) {
      return '$label must be a whole number (no decimals)';
    }
    return '$label must be a whole number, e.g. 10';
  }
  final n = int.tryParse(v);
  if (n == null) return '$label is too large';
  if (n < 0) return '$label cannot be negative (0 or more)';
  return null;
}

String? validateQuantity(String? value) =>
    validateWholeNumber(value, 'Quantity');

String? validateReorderLevel(String? value) =>
    validateWholeNumber(value, 'Reorder level');

/// Unit price: RM amount greater than 0 with at most 2 decimal places.
String? validateUnitPrice(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Unit price is required';
  if (!_decimalNumber.hasMatch(v)) {
    return 'Enter a valid RM amount, e.g. 19.90';
  }
  final p = double.parse(v);
  if (p <= 0) return 'Unit price must be greater than RM 0';
  final dot = v.indexOf('.');
  if (dot != -1 && v.length - dot - 1 > 2) {
    return 'Use at most 2 decimal places, e.g. 19.90';
  }
  return null;
}
