import 'package:cloud_firestore/cloud_firestore.dart';

/// One document in the Firestore `stockItems` collection.
class StockItem {
  final String id;
  final String sku;
  final String itemName;
  final String category;
  final int quantity;
  final double unitPrice;
  final int reorderLevel;
  final DateTime? createdAt;

  /// Email of the account that submitted the item (optional extra field).
  final String? createdBy;

  const StockItem({
    this.id = '',
    required this.sku,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.reorderLevel,
    this.createdAt,
    this.createdBy,
  });

  /// Low stock rule from the brief: quantity <= reorderLevel.
  bool get isLowStock => quantity <= reorderLevel;

  double get stockValue => quantity * unitPrice;

  /// Builds an item from a Firestore document. Numbers are read as `num`
  /// so a price such as 35.00 (stored as an integer by Flutter Web) never
  /// causes a type error.
  factory StockItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'];
    return StockItem(
      id: doc.id,
      sku: (d['sku'] ?? '').toString(),
      itemName: (d['itemName'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (d['unitPrice'] as num?)?.toDouble() ?? 0,
      reorderLevel: (d['reorderLevel'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      createdBy: d['createdBy'] as String?,
    );
  }

  /// Typed map written to Firestore. `createdAt` is a server timestamp.
  Map<String, dynamic> toFirestore() => {
    'sku': sku,
    'itemName': itemName,
    'category': category,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'reorderLevel': reorderLevel,
    'createdAt': FieldValue.serverTimestamp(),
    if (createdBy != null) 'createdBy': createdBy,
  };
}
