import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/app.dart';

Future<void> pump(WidgetTester tester, FakeFirebaseFirestore db) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    StockInventoryApp(firestore: db, useGoogleFonts: false),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app opens on the admin pages with no login', (tester) async {
    await pump(tester, FakeFirebaseFirestore());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Records'), findsOneWidget);
    expect(find.byKey(const Key('adminLoginButton')), findsNothing);
    expect(find.byKey(const Key('accountMenu')), findsNothing);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('submission is saved without createdBy', (tester) async {
    final db = FakeFirebaseFirestore();
    await pump(tester, db);
    await tester.tap(find.text('Add Item').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('skuField')), 'STK-301');
    await tester.enterText(find.byKey(const Key('nameField')), 'Sugar 1kg');
    await tester.enterText(find.byKey(const Key('qtyField')), '8');
    await tester.enterText(find.byKey(const Key('reorderField')), '3');
    await tester.enterText(find.byKey(const Key('priceField')), '3.20');
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key as ValueKey).value}'.startsWith('categoryField'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grocery').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('saveButton')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();
    final docs = (await db.collection('stockItems').get()).docs;
    expect(docs.length, 1);
    expect(docs.first.data().containsKey('createdBy'), isFalse);
  });
}
