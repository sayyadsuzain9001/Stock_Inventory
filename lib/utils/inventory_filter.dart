import '../models/stock_item.dart';

enum QtySort { newest, ascending, descending }

/// Applies the advanced search to a freshly retrieved Firestore snapshot.
///
/// Every active control is combined with AND:
///  * keyword  -> partial, case-insensitive match on itemName OR sku
///  * category -> 'All' or one of the four categories
///  * lowStock -> quantity <= reorderLevel
/// Then results are sorted by quantity (ascending/descending) or kept in
/// newest-first order.
List<StockItem> applyInventoryFilters(
  List<StockItem> items, {
  String keyword = '',
  String category = 'All',
  bool lowStockOnly = false,
  QtySort sort = QtySort.newest,
}) {
  final kw = keyword.trim().toLowerCase();

  final result = items.where((item) {
    final matchesKeyword =
        kw.isEmpty ||
        item.itemName.toLowerCase().contains(kw) ||
        item.sku.toLowerCase().contains(kw);
    final matchesCategory = category == 'All' || item.category == category;
    final matchesLowStock = !lowStockOnly || item.isLowStock;
    return matchesKeyword && matchesCategory && matchesLowStock;
  }).toList();

  switch (sort) {
    case QtySort.ascending:
      result.sort((a, b) {
        final c = a.quantity.compareTo(b.quantity);
        return c != 0 ? c : a.sku.compareTo(b.sku);
      });
    case QtySort.descending:
      result.sort((a, b) {
        final c = b.quantity.compareTo(a.quantity);
        return c != 0 ? c : a.sku.compareTo(b.sku);
      });
    case QtySort.newest:
      break; // Firestore already returns newest first.
  }
  return result;
}
