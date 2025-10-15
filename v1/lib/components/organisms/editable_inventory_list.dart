// Organism: EditableInventoryList
// Single Functionality: Display and edit machine inventory with add/delete

import 'package:flutter/material.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class EditableInventoryList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index) onDelete;
  final VoidCallback onAdd;
  final VoidCallback? onItemsChanged;

  const EditableInventoryList({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onAdd,
    this.onItemsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppText.body('No items in inventory. Add some!'),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return _EditableInventoryItemCard(
              item: item,
              onDelete: () => onDelete(index),
              onChanged: onItemsChanged,
            );
          }).toList(),
        
        const SizedBox(height: 8),
        
        AppButton.secondary(
          label: 'Add SKU',
          icon: Icons.add,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// Internal widget for displaying an editable inventory item card
class _EditableInventoryItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  final VoidCallback? onChanged;

  const _EditableInventoryItemCard({
    required this.item,
    required this.onDelete,
    this.onChanged,
  });

  @override
  State<_EditableInventoryItemCard> createState() => _EditableInventoryItemCardState();
}

class _EditableInventoryItemCardState extends State<_EditableInventoryItemCard> {
  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _capController;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.item['sku']?.toString() ?? '');
    _nameController = TextEditingController(text: widget.item['name']?.toString() ?? '');
    _capController = TextEditingController(text: widget.item['cap']?.toString() ?? '1');

    _skuController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
    _capController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _capController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    widget.item['sku'] = _skuController.text.trim();
    widget.item['name'] = _nameController.text.trim().isEmpty ? _skuController.text.trim() : _nameController.text.trim();
    // Keep existing qty from backend, don't let user edit it
    widget.item['cap'] = int.tryParse(_capController.text) ?? 1;
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDelete,
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capController,
              decoration: const InputDecoration(labelText: 'Capacity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
