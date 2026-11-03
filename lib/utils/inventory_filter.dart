import '../models/stock_item.dart';

/// Sort options for the inventory list.
enum QtySort { newest, oldest, ascending, descending }

/// Quick date filters on the submission timestamp (`createdAt`).
enum DateFilter { all, today, last7Days, custom }

/// Applies the advanced search to a freshly retrieved Firestore snapshot.
///
/// Every active control is combined with AND:
///  * keyword  -> partial, case-insensitive match on itemName OR sku
///  * category -> 'All' or one of the four categories
///  * lowStock -> quantity <= reorderLevel
///  * from/to  -> createdAt between the two dates (inclusive, whole days)
/// Then results are sorted by submission time or by quantity.
List<StockItem> applyInventoryFilters(
  List<StockItem> items, {
  String keyword = '',
  String category = 'All',
  bool lowStockOnly = false,
  DateTime? from,
  DateTime? to,
  QtySort sort = QtySort.newest,
}) {
  final kw = keyword.trim().toLowerCase();
  final start = from == null ? null : DateTime(from.year, from.month, from.day);
  final endExclusive = to == null
      ? null
      : DateTime(to.year, to.month, to.day + 1);

  final result = items.where((item) {
    final matchesKeyword =
        kw.isEmpty ||
        item.itemName.toLowerCase().contains(kw) ||
        item.sku.toLowerCase().contains(kw);
    final matchesCategory = category == 'All' || item.category == category;
    final matchesLowStock = !lowStockOnly || item.isLowStock;
    // A write still waiting for its server timestamp counts as "now".
    final when = (item.createdAt ?? DateTime.now()).toLocal();
    final matchesDate =
        (start == null || !when.isBefore(start)) &&
        (endExclusive == null || when.isBefore(endExclusive));
    return matchesKeyword && matchesCategory && matchesLowStock && matchesDate;
  }).toList();

  int byTime(StockItem a, StockItem b) {
    final ta = a.createdAt ?? DateTime.now();
    final tb = b.createdAt ?? DateTime.now();
    return ta.compareTo(tb);
  }

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
      result.sort((a, b) => byTime(b, a));
    case QtySort.oldest:
      result.sort(byTime);
  }
  return result;
}

/// Returns the [from, to] dates for a quick date filter.
({DateTime? from, DateTime? to}) rangeFor(DateFilter f, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  switch (f) {
    case DateFilter.all:
    case DateFilter.custom:
      return (from: null, to: null);
    case DateFilter.today:
      return (from: today, to: today);
    case DateFilter.last7Days:
      return (from: today.subtract(const Duration(days: 6)), to: today);
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int v) => v.toString().padLeft(2, '0');

/// "3 Nov 2026, 08:40:15" in the device's local time.
String formatTimestamp(DateTime? t) {
  if (t == null) return 'Saving...';
  final l = t.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}, '
      '${_two(l.hour)}:${_two(l.minute)}:${_two(l.second)}';
}

/// "3 Nov 2026" for date chips.
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
