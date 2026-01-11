import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'InventoryController.dart';
import 'ScanScreen.dart';

class StockScreens extends StatelessWidget {
  const StockScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryController()..loadInventory(),
      child: Scaffold(
        body: Consumer<InventoryController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.inventory.isEmpty) {
              return const Center(child: Text('No inventory data'));
            }

            return ListView.builder(
              itemCount: controller.inventory.length,
              itemBuilder: (context, index) {
                final machineId = controller.inventory.keys.elementAt(index);
                final items = controller.inventory[machineId]!;

                return ExpansionTile(
                  title: Text('Machine $machineId'),
                  children: items
                      .map(
                        (item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text('Qty: ${item.qty}'),
                          trailing: Text(item.sku),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final code = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanScreen()),
            );
            if (code != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scanned: $code')),
                );
                // In a real app, we'd fetch the item details here
              }
            }
          },
          child: const Icon(Icons.qr_code_scanner),
        ),
      ),
    );
  }
}
