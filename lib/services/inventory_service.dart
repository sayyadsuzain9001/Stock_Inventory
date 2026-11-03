import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stock_item.dart';

/// Result of listening to the inventory: items plus where they came from.
class InventorySnapshot {
  final List<StockItem> items;
  final bool fromCache;
  const InventorySnapshot(this.items, this.fromCache);
}

/// All Firestore access for the `stockItems` collection.
class InventoryService {
  InventoryService(this.db);

  final FirebaseFirestore db;
  static const collectionName = 'stockItems';

  CollectionReference<Map<String, dynamic>> get _items =>
      db.collection(collectionName);

  /// Saves one item with an auto-generated document ID. The returned future
  /// completes only after Firestore acknowledges the write.
  Future<DocumentReference<Map<String, dynamic>>> addItem(StockItem item) {
    return _items
        .add(item.toFirestore())
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Firestore did not confirm the save. Check your connection.',
          ),
        );
  }

  /// Live, newest-first view of every saved item (survives reloads because
  /// it always reads from Firestore).
  Stream<InventorySnapshot> watchItems() {
    return _items
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => InventorySnapshot(
            snap.docs.map(StockItem.fromDoc).toList(),
            snap.metadata.isFromCache,
          ),
        );
  }
}
