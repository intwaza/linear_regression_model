import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:order_cycle_app/main.dart';

void main() {
  testWidgets('the page has 12 text fields and a Predict button', (WidgetTester tester) async {
    await tester.pumpWidget(const OrderCycleApp());

    expect(find.byType(TextField), findsNWidgets(12));
    expect(find.text('Predict'), findsOneWidget);
  });
}
