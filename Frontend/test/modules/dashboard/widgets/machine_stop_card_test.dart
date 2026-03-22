
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vending_backpack_v2/modules/dashboard/widgets/MachineStopCard.dart';

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
    expect(find.text('TEST MACHINE'), findsOneWidget);
    expect(find.text('UNIT_ID: M-101 // PAYLOAD: 2 SKUS'), findsOneWidget);
    
    // Items should be hidden initially
    expect(find.text('Item 1'), findsNothing);

    // Tap to expand
    await tester.tap(find.text('TEST MACHINE'));
    await tester.pumpAndSettle();

    // Items should be visible now
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('SKU1'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('SKU2'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
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

    await tester.tap(find.text('EMPTY MACHINE'));
    await tester.pumpAndSettle();

    expect(find.text('NO DATA LOADED'), findsOneWidget);
  });
}
