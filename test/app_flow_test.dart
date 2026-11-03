import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/app.dart';
import 'package:stock_inventory_lab/models/stock_item.dart';
import 'package:stock_inventory_lab/services/inventory_service.dart';

class FailingService extends InventoryService {
  FailingService(super.db);
  @override
  Future<DocumentReference<Map<String, dynamic>>> addItem(
    StockItem item,
  ) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
  }
}

Future<void> pumpApp(
  WidgetTester tester,
  FakeFirebaseFirestore db, {
  InventoryService? service,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    StockInventoryApp(firestore: db, service: service, useGoogleFonts: false),
  );
  await tester.pumpAndSettle();
}

Future<void> fillForm(
  WidgetTester tester, {
  required String sku,
  required String name,
  String? category,
  required String qty,
  required String price,
  required String reorder,
}) async {
  await tester.enterText(find.byKey(const Key('skuField')), sku);
  await tester.enterText(find.byKey(const Key('nameField')), name);
  await tester.enterText(find.byKey(const Key('qtyField')), qty);
  await tester.enterText(find.byKey(const Key('reorderField')), reorder);
  await tester.enterText(find.byKey(const Key('priceField')), price);
  if (category != null) {
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key as ValueKey).value}'.startsWith('categoryField'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(category).last);
    await tester.pumpAndSettle();
  }
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('saveButton')));
  await tester.tap(find.byKey(const Key('saveButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid form shows inline errors and writes nothing', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, db);
    await tester.tap(find.text('Add Item').last);
    await tester.pumpAndSettle();

    await tapSave(tester); // blank form
    expect(find.text('SKU is required'), findsOneWidget);
    expect(find.text('Item name is required'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
    expect(find.text('Quantity is required'), findsOneWidget);
    expect(find.text('Unit price is required'), findsOneWidget);

    await fillForm(
      tester,
      sku: 'STK1',
      name: 'ab',
      qty: '-1',
      price: '0',
      reorder: '2.5',
    );
    await tapSave(tester);
    expect(
      find.text('SKU must be STK- followed by 3 digits, e.g. STK-101'),
      findsOneWidget,
    );
    expect(
      find.text('Item name must be at least 3 characters'),
      findsOneWidget,
    );
    expect(
      find.text('Quantity cannot be negative (0 or more)'),
      findsOneWidget,
    );
    expect(
      find.text('Reorder level must be a whole number (no decimals)'),
      findsOneWidget,
    );
    expect(find.text('Unit price must be greater than RM 0'), findsOneWidget);

    final docs = await db.collection('stockItems').get();
    expect(docs.docs, isEmpty);
  });

  testWidgets('valid save stores typed fields, then search/sort/clear work', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, db);

    final data = [
      ['STK-101', 'USB C Cable', 'Electronics', '4', '19.90', '5'],
      ['STK-102', 'Notebook', 'Stationery', '25', '4.50', '10'],
      ['STK-103', 'Wireless Mouse', 'Electronics', '1', '35.00', '3'],
    ];
    for (final d in data) {
      await tester.tap(find.text('Add Item').last);
      await tester.pumpAndSettle();
      await fillForm(
        tester,
        sku: d[0],
        name: d[1],
        category: d[2],
        qty: d[3],
        price: d[4],
        reorder: d[5],
      );
      await tapSave(tester);
      expect(find.text('Saved to Firestore'), findsOneWidget);
      await tester.tap(find.text('View inventory'));
      await tester.pumpAndSettle();
    }

    final snap = await db.collection('stockItems').get();
    expect(snap.docs.length, 3);
    final mouse = snap.docs.firstWhere((d) => d['sku'] == 'STK-103').data();
    expect(mouse['itemName'], 'Wireless Mouse');
    expect(mouse['category'], 'Electronics');
    expect(mouse['quantity'], isA<int>());
    expect(mouse['reorderLevel'], 3);
    expect(mouse['unitPrice'], isA<double>());
    expect(mouse['unitPrice'], 35.0);
    expect(mouse['createdAt'], isA<Timestamp>());

    // Now on the Inventory tab, all three visible, each with its timestamp.
    expect(find.text('Showing 3 of 3 items'), findsOneWidget);
    expect(find.byKey(const Key('submittedAt')), findsNWidgets(3));
    expect(find.textContaining('Submitted '), findsNWidgets(3));

    // Today filter keeps all three (just submitted).
    await tester.tap(find.byKey(const Key('date_today')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 3 of 3 items'), findsOneWidget);

    // Sort menu: quantity low to high.
    await tester.tap(find.byKey(const Key('sortControl')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quantity: low to high').last);
    await tester.pumpAndSettle();
    expect(find.text('Sort: Quantity: low to high'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clearFilters')));
    await tester.pumpAndSettle();

    // Combined: "mouse" + Electronics + low stock -> only STK-103.
    await tester.enterText(find.byKey(const Key('searchField')), 'mouse');
    await tester.tap(find.byKey(const Key('cat_Electronics')));
    await tester.tap(find.byKey(const Key('lowStockChip')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 of 3 items'), findsOneWidget);
    expect(find.text('Wireless Mouse'), findsWidgets);

    // Clear Filters restores the full list.
    await tester.tap(find.byKey(const Key('clearFilters')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 3 of 3 items'), findsOneWidget);

    // No results message.
    await tester.enterText(find.byKey(const Key('searchField')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No items match your filters'), findsOneWidget);
  });

  testWidgets('write error keeps the form filled', (tester) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, db, service: FailingService(db));
    await tester.tap(find.text('Add Item').last);
    await tester.pumpAndSettle();
    await fillForm(
      tester,
      sku: 'STK-104',
      name: 'Hammer',
      category: 'Hardware',
      qty: '7',
      price: '25',
      reorder: '2',
    );
    await tapSave(tester);
    expect(find.textContaining('Save failed'), findsOneWidget);
    expect(find.text('STK-104'), findsWidgets);
    expect(find.text('Hammer'), findsWidgets);
    expect((await db.collection('stockItems').get()).docs, isEmpty);
  });
}
