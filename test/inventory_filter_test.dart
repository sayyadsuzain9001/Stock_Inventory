import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/models/stock_item.dart';
import 'package:stock_inventory_lab/utils/inventory_filter.dart';

const items = [
  StockItem(
    id: '1',
    sku: 'STK-101',
    itemName: 'USB C Cable',
    category: 'Electronics',
    quantity: 4,
    unitPrice: 19.90,
    reorderLevel: 5,
  ),
  StockItem(
    id: '2',
    sku: 'STK-102',
    itemName: 'Notebook',
    category: 'Stationery',
    quantity: 25,
    unitPrice: 4.50,
    reorderLevel: 10,
  ),
  StockItem(
    id: '3',
    sku: 'STK-103',
    itemName: 'Wireless Mouse',
    category: 'Electronics',
    quantity: 1,
    unitPrice: 35.00,
    reorderLevel: 3,
  ),
];

List<String> skus(List<StockItem> l) => l.map((e) => e.sku).toList();

void main() {
  test('"mouse" + Electronics + Low stock -> only STK-103', () {
    expect(
      skus(
        applyInventoryFilters(
          items,
          keyword: 'mouse',
          category: 'Electronics',
          lowStockOnly: true,
        ),
      ),
      ['STK-103'],
    );
  });
  test(
    '"STK-102" with All / all stock -> Notebook (case-insensitive partial)',
    () {
      expect(skus(applyInventoryFilters(items, keyword: 'STK-102')), [
        'STK-102',
      ]);
      expect(skus(applyInventoryFilters(items, keyword: 'stk-10')).length, 3);
      expect(skus(applyInventoryFilters(items, keyword: 'NOTE')), ['STK-102']);
    },
  );
  test('sort by quantity ascending and descending', () {
    expect(skus(applyInventoryFilters(items, sort: QtySort.ascending)), [
      'STK-103',
      'STK-101',
      'STK-102',
    ]);
    expect(skus(applyInventoryFilters(items, sort: QtySort.descending)), [
      'STK-102',
      'STK-101',
      'STK-103',
    ]);
  });
  test('low stock uses quantity <= reorderLevel', () {
    expect(skus(applyInventoryFilters(items, lowStockOnly: true)), [
      'STK-101',
      'STK-103',
    ]);
    const edge = StockItem(
      sku: 'STK-200',
      itemName: 'Edge',
      category: 'Hardware',
      quantity: 5,
      unitPrice: 1,
      reorderLevel: 5,
    );
    expect(edge.isLowStock, isTrue);
  });
  test('category filter and no results', () {
    expect(skus(applyInventoryFilters(items, category: 'Stationery')), [
      'STK-102',
    ]);
    expect(applyInventoryFilters(items, category: 'Grocery'), isEmpty);
  });
  test('cleared filters return everything', () {
    expect(applyInventoryFilters(items).length, 3);
  });
}
