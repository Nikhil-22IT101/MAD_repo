import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_retails/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(GSTBillingApp());

    // Since GSTBillingApp doesn't have a counter, this test might fail unless you implement one.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
