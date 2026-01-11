// Organism: InventoryList
// Single Functionality: Display complete inventory for a machine with all items

import 'package:flutter/material.dart';
import '../molecules/inventory_item.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class InventoryList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(String sku)? onFillItem;
  final VoidCallback? onFillAll;
  final bool isLoading;
  final String? machineId;

  const InventoryList({
    super.key,
    required this.items,
    this.onFillItem,
    this.onFillAll,
    this.isLoading = false,
    this.machineId,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: AppText.body('No inventory available'),
        ),
      );
    }

    return Column(
      children: [
        ...items.map((item) => InventoryItem.fromMap(
              item,
              onFill: onFillItem != null
                  ? () => onFillItem!(item['sku']?.toString() ?? '')
                  : null,
            )),
        if (onFillAll != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AppButton.primary(
              label: 'Fill All',
              onPressed: onFillAll,
              isLoading: isLoading,
            ),
          ),
      ],
    );
  }
}
