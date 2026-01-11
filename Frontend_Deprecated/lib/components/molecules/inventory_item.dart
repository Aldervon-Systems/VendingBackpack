// Molecule: InventoryItem
// Single Functionality: Display a single inventory SKU with quantity and fill action

import 'package:flutter/material.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class InventoryItem extends StatelessWidget {
  final String sku;
  final String name;
  final int quantity;
  final int capacity;
  final VoidCallback? onFill;
  final bool isLoading;

  const InventoryItem({
    super.key,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.capacity,
    this.onFill,
    this.isLoading = false,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> data, {VoidCallback? onFill}) {
    return InventoryItem(
      sku: data['sku']?.toString() ?? '',
      name: data['name']?.toString() ?? data['sku']?.toString() ?? '',
      quantity: (data['qty'] is num) ? (data['qty'] as num).toInt() : 0,
      capacity: (data['cap'] is num) ? (data['cap'] as num).toInt() : 0,
      onFill: onFill,
    );
  }

  bool get isFull => quantity >= capacity;
  double get fillPercentage => capacity > 0 ? (quantity / capacity) : 0.0;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (quantity == 0) {
      iconColor = Colors.red;
    } else if (quantity < 5) {
      iconColor = Colors.yellow[700]!;
    } else {
      iconColor = Colors.grey;
    }
    return ListTile(
      leading: Icon(Icons.inventory_2, color: iconColor),
      title: AppText.body(name),
      subtitle: AppText.caption(sku),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.body('$quantity/$capacity'),
          const SizedBox(width: 8),
          if (onFill != null)
            AppButton.primary(
              label: 'Fill',
              onPressed: isFull ? null : onFill,
              isLoading: isLoading,
            ),
        ],
      ),
    );
  }
}
