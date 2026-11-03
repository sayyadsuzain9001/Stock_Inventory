import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/app.dart';
import 'package:stock_inventory_lab/services/auth_service.dart';

Future<void> pump(WidgetTester tester, FakeFirebaseFirestore db) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthService()
    ..accounts['admin@stockinventory.com'] = 'Admin@4207'
    ..accounts['user@stockinventory.com'] = 'User@4207';
  await tester.pumpWidget(
    StockInventoryApp(firestore: db, auth: auth, useGoogleFonts: false),
  );
  await tester.pumpAndSettle();
}

Future<void> openLogin(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('adminLoginButton')));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester, String email, String pw) async {
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), pw);
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form is public: no login needed and no records tabs', (
    tester,
  ) async {
    await pump(tester, FakeFirebaseFirestore());
    expect(find.text('Add Stock Item'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Records'), findsNothing);
    expect(find.byKey(const Key('adminLoginButton')), findsOneWidget);
  });

  testWidgets(
    'admin login rejects non-admin email and wrong password; back returns to form',
    (tester) async {
      await pump(tester, FakeFirebaseFirestore());
      await openLogin(tester);
      expect(find.text('Admin sign in'), findsOneWidget);
      await login(tester, 'user@stockinventory.com', 'User@4207');
      expect(
        find.text('Only the admin account can sign in here.'),
        findsOneWidget,
      );
      await login(tester, 'admin@stockinventory.com', 'wrongpass');
      expect(find.text('Wrong email or password.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('loginBack')));
      await tester.pumpAndSettle();
      expect(find.text('Add Stock Item'), findsOneWidget);
    },
  );

  testWidgets(
    'admin sees Dashboard and Records; sign out returns to public form',
    (tester) async {
      await pump(tester, FakeFirebaseFirestore());
      await openLogin(tester);
      await login(tester, 'admin@stockinventory.com', 'Admin@4207');
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accountMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adminLoginButton')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('anonymous submission is saved without createdBy', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await pump(tester, db);
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
    expect(find.text('Add another item'), findsOneWidget);
    final docs = (await db.collection('stockItems').get()).docs;
    expect(docs.length, 1);
    expect(docs.first.data().containsKey('createdBy'), isFalse);
  });
}
