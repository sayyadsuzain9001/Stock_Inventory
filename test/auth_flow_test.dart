import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/app.dart';
import 'package:stock_inventory_lab/services/auth_service.dart';

Future<FakeAuthService> pump(
  WidgetTester tester,
  FakeFirebaseFirestore db,
) async {
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
  return auth;
}

Future<void> login(WidgetTester tester, String email, String pw) async {
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), pw);
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'signed-out users see the login screen; wrong password shows an error',
    (tester) async {
      await pump(tester, FakeFirebaseFirestore());
      expect(find.text('Welcome back'), findsOneWidget);
      await login(tester, 'admin@stockinventory.com', 'wrongpass');
      expect(find.text('Wrong email or password.'), findsOneWidget);
    },
  );

  testWidgets('normal user can submit but has no Records/Dashboard tabs', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await pump(tester, db);
    await login(tester, 'user@stockinventory.com', 'User@4207');
    expect(find.text('Add Stock Item'), findsOneWidget);
    expect(find.text('Records'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('User'), findsOneWidget);
  });

  testWidgets(
    'admin sees Dashboard, Add Item and Records; sign out returns to login',
    (tester) async {
      await pump(tester, FakeFirebaseFirestore());
      await login(tester, 'admin@stockinventory.com', 'Admin@4207');
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accountMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  testWidgets('register creates a normal user account', (tester) async {
    await pump(tester, FakeFirebaseFirestore());
    await tester.tap(find.byKey(const Key('toggleRegister')));
    await tester.pumpAndSettle();
    await login(tester, 'new@student.my', 'secret12');
    expect(find.text('Add Stock Item'), findsOneWidget);
    expect(find.text('Records'), findsNothing);
  });
}
