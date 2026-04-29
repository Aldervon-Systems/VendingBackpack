import 'package:flutter/material.dart';
import '../../../core/contracts/operations.dart';
import '../../../core/styles/AppStyle.dart';

class MachineStopCard extends StatelessWidget {
  final String machineId;
  final String machineName;
  final bool isOnline;
  final List<MachineInventoryItemDto> items;
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: AppStyle.surfaceCard,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: const Border(), // Remove default borders
        collapsedShape: const Border(),
        leading: _StatusIndicator(isActive: isOnline),
        title: Text(
          machineName.toUpperCase(),
          style: AppStyle.label(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.dataPrimary, letterSpacing: 0.5),
        ),
        subtitle: Text(
          'UNIT_ID: $machineId // PAYLOAD: ${items.length} SKUS',
          style: AppStyle.metric(fontSize: 10, color: AppColors.dataSecondary),
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('NO DATA LOADED', style: AppStyle.label(fontSize: 10)),
                  ),
                for (final item in items)
                  _ItemRow(
                    name: item.name.isNotEmpty ? item.name : 'Unknown Item',
                    sku: item.sku,
                    qty: item.quantity,
                    onUpdate: (newQty) => onUpdateQuantity?.call(item.sku, newQty),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  const _StatusIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.success : AppColors.dataSecondary,
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.success.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 2,
          )
        ] : [],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final String sku;
  final int qty;
  final ValueChanged<int> onUpdate;

  const _ItemRow({required this.name, required this.sku, required this.qty, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppStyle.label(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.dataPrimary)),
                Text(sku, style: AppStyle.metric(fontSize: 9, color: AppColors.dataSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              _QtyBtn(icon: Icons.remove, onTap: () => onUpdate(qty - 1)),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('$qty', style: AppStyle.metric(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              _QtyBtn(icon: Icons.add, onTap: () => onUpdate(qty + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.foundation,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppColors.dataSecondary),
      ),
    );
  }
}
