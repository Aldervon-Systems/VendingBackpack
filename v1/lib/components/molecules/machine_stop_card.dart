// Molecule: MachineStopCard
// Single Functionality: Display a machine stop with expandable inventory

import 'package:flutter/material.dart';
import '../atoms/app_text.dart';
import '../organisms/inventory_list.dart';
import '../../api/inventory_cache.dart';

class MachineStopCard extends StatelessWidget {
  final String machineId;
  final String? machineName;
  final String? subtitle;
  final bool showFillButtons;
  final Function(String sku)? onFillItem;
  final VoidCallback? onFillAll;
  final Color? iconColor;

  const MachineStopCard({
  super.key,
  required this.machineId,
  this.machineName,
  this.subtitle,
  this.showFillButtons = true,
  this.onFillItem,
  this.onFillAll,
  this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedBuilder(
        animation: InventoryCache.instance,
        builder: (context, _) {
          final mid = machineId.toLowerCase();
          final inventory = InventoryCache.instance.inventory[mid] ?? [];

          return ExpansionTile(
            leading: Icon(Icons.devices, color: iconColor ?? Colors.grey),
            title: AppText.subtitle(machineName ?? machineId),
            subtitle: null,
            children: [
              if (inventory.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AppText.body('Inventory not available yet'),
                )
              else
                InventoryList(
                  items: inventory,
                  machineId: machineId,
                  onFillItem: showFillButtons ? onFillItem : null,
                  onFillAll: showFillButtons ? onFillAll : null,
                ),
            ],
          );
        },
      ),
    );
  }
}
