import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_inventory_lab/app.dart';

void main() {
  for (final size in const [Size(360, 740), Size(412, 915), Size(1366, 768)]) {
    testWidgets('no layout overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = FakeFirebaseFirestore();
      for (final d in [
        ['STK-101', 'USB C Cable', 'Electronics', 4, 19.90, 5],
        ['STK-102', 'Notebook', 'Stationery', 25, 4.50, 10],
        [
          'STK-103',
          'Wireless Mouse With An Extremely Long Product Name',
          'Electronics',
          1,
          35.0,
          3,
        ],
        ['STK-104', 'Claw Hammer', 'Hardware', 120000, 1234567.89, 2],
      ]) {
        await db.collection('stockItems').add({
          'sku': d[0],
          'itemName': d[1],
          'category': d[2],
          'quantity': d[3],
          'unitPrice': d[4],
          'reorderLevel': d[5],
          'createdAt': Timestamp.now(),
        });
      }
      await tester.pumpWidget(
        StockInventoryApp(firestore: db, useGoogleFonts: false),
      );
      await tester.pumpAndSettle();
      for (final tab in ['Add Item', 'Records', 'Dashboard']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
