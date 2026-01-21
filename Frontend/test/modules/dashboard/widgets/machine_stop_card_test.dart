
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1/modules/dashboard/widgets/MachineStopCard.dart';

void main() {
  testWidgets('MachineStopCard expands to show items', (WidgetTester tester) async {
    const machineId = 'M-101';
    const machineName = 'Test Machine';
    final items = [
      {'sku': 'SKU1', 'name': 'Item 1', 'qty': 10},
      {'sku': 'SKU2', 'name': 'Item 2', 'qty': 5},
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MachineStopCard(
            machineId: machineId,
            machineName: machineName,
            items: items,
          ),
        ),
      ),
    );

    // Initial state: Title and Subtitle visible
    expect(find.text('Test Machine'), findsOneWidget);
    expect(find.text('ID: M-101 | Items: 2'), findsOneWidget);
    
    // Items should be hidden initially
    expect(find.text('Item 1'), findsNothing);

    // Tap to expand
    await tester.tap(find.text('Test Machine'));
    await tester.pumpAndSettle();

    // Items should be visible now
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('SKU: SKU1'), findsOneWidget);
    expect(find.text('Qty: 10'), findsOneWidget);
    
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('SKU: SKU2'), findsOneWidget);
    expect(find.text('Qty: 5'), findsOneWidget);
  });

  testWidgets('MachineStopCard shows no items message when empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MachineStopCard(
            machineId: 'M-102',
            machineName: 'Empty Machine',
            items: [],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Empty Machine'));
    await tester.pumpAndSettle();

    expect(find.text('No items loaded'), findsOneWidget);
  });
}
