import 'package:flutter/material.dart';

class MachineStopCard extends StatelessWidget {
  final String machineId;
  final String machineName;
  final bool isOnline;
  final List<dynamic> items;
  final Function(String sku, int newQty)? onUpdateQuantity;

  const MachineStopCard({
    super.key,
    required this.machineId,
    required this.machineName,
    this.isOnline = true,
    this.items = const [],
    this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(Icons.devices, color: isOnline ? Colors.green : Colors.grey, size: 32),
        title: Text(machineName),
        subtitle: Text('ID: $machineId | Items: ${items.length}'),
        children: [
          if (items.isEmpty)
            const ListTile(title: Text('No items loaded')),
          for (final item in items)
            ListTile(
              dense: true,
              leading: const Icon(Icons.inventory_2_outlined, size: 20),
              title: Text(item['name'] ?? 'Unknown Item'),
              subtitle: Text('SKU: ${item['sku']}'),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onUpdateQuantity != null)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                      onPressed: () {
                        final currentQty = (item['qty'] as num).toInt();
                        if (currentQty > 0) {
                          onUpdateQuantity!(item['sku'], currentQty - 1);
                        }
                      },
                    ),
                    Text(
                      '${item['qty']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (onUpdateQuantity != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                      onPressed: () {
                        final currentQty = (item['qty'] as num).toInt();
                        onUpdateQuantity!(item['sku'], currentQty + 1);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
