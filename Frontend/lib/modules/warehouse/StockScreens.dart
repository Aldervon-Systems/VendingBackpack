import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'InventoryController.dart';
import 'ScanScreen.dart';
import '../auth/SessionManager.dart';
import '../../core/styles/AppStyle.dart';

class StockScreens extends StatelessWidget {
  const StockScreens({super.key});

  Future<void> _processScan(BuildContext context, InventoryController controller, String code) async {
    final existingItem = await controller.checkBarcode(code);
    if (!context.mounted) return;

    final nameController = TextEditingController(text: existingItem?['name'] ?? '');
    final qtyController = TextEditingController(text: '1');
    final isNew = existingItem == null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          isNew ? 'REGISTER NEW SKU' : 'INCREMENT STOCK',
          style: AppStyle.label(fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BARCODE: $code', style: AppStyle.metric(fontSize: 10, color: AppColors.dataSecondary)),
            const SizedBox(height: 24),
            if (isNew)
              _DialogField(controller: nameController, label: 'ITEM NAME')
            else
              _DialogInfo(label: 'IDENTIFIED AS', value: existingItem['name']),
            const SizedBox(height: 16),
            _DialogField(controller: qtyController, label: 'QUANTITY TO ADD', isNumeric: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppStyle.label(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (name.isEmpty || qty <= 0) return;

              Navigator.pop(ctx);
              try {
                await controller.addBarcodeStock(code, name, qty);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('STOCK UPDATED', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ERROR: $e'), backgroundColor: AppColors.warning),
                  );
                }
              }
            },
            child: Text('COMMIT', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showShipmentMenu(BuildContext context, InventoryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.foundation,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LOGISTICS / SHIPMENTS', style: AppStyle.label(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dataPrimary, letterSpacing: 1.0)),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.actionAccent),
                    onPressed: () => _showAddShipmentDialog(context, controller),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.shipments.isEmpty) {
                    return Center(child: Text('NO SCHEDULED DATA', style: AppStyle.label()));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: controller.shipments.length,
                    itemBuilder: (context, index) {
                      final ship = controller.shipments[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: AppStyle.surfaceCard,
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: const BoxDecoration(color: AppColors.foundation, shape: BoxShape.circle),
                              child: const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.dataSecondary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ship.description.toUpperCase(), style: AppStyle.label(fontWeight: FontWeight.bold, color: AppColors.dataPrimary)),
                                  Text(ship.scheduledFor, style: AppStyle.metric(fontSize: 10, color: AppColors.dataSecondary)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${ship.amount}', style: AppStyle.metric(fontSize: 18, color: AppColors.actionAccent)),
                                Text('UNITS', style: AppStyle.label(fontSize: 8, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShipmentDialog(BuildContext context, InventoryController controller) {
    final descController = TextEditingController();
    final amtController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('SCHEDULE REFILL', style: AppStyle.label(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: descController, label: 'DESCRIPTION'),
            const SizedBox(height: 16),
            _DialogField(controller: amtController, label: 'UNIT COUNT', isNumeric: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppStyle.label())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dataPrimary, elevation: 0),
            onPressed: () async {
              final amt = int.tryParse(amtController.text) ?? 0;
              if (descController.text.isNotEmpty && amt > 0) {
                await controller.addShipment(descController.text, amt, DateTime.now());
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('SCHEDULE', style: AppStyle.label(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryController()..loadInventory(),
      child: Consumer<InventoryController>(
        builder: (context, controller, child) {
          Widget body;
          if (controller.isLoading) {
            body = const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border));
          } else if (controller.inventory.isEmpty) {
            body = Center(child: Text('NO INVENTORY DETECTED', style: AppStyle.label()));
          } else {
            body = ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              itemCount: controller.inventory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = controller.inventory[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: AppStyle.surfaceCard,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name.toUpperCase(), style: AppStyle.label(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.dataPrimary)),
                            const SizedBox(height: 4),
                            Text('SKU: ${item.sku}', style: AppStyle.metric(fontSize: 10, color: AppColors.dataSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${item.quantity}', style: AppStyle.metric(fontSize: 20, color: item.quantity < 20 ? AppColors.warning : AppColors.dataPrimary)),
                          Text('IN STOCK', style: AppStyle.label(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          final isManager = context.read<SessionManager>().isManager;

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('WAREHOUSE / STOCK', style: AppStyle.label(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              actions: [
                if (isManager)
                  IconButton(
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    onPressed: () => _showShipmentMenu(context, controller),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: body,
            floatingActionButton: isManager
                ? FloatingActionButton(
                    backgroundColor: AppColors.dataPrimary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () async {
                      final code = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanScreen()));
                      if (code != null && context.mounted) _processScan(context, controller, code);
                    },
                    child: const Icon(Icons.qr_code_scanner, size: 28),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumeric;
  const _DialogField({required this.controller, required this.label, this.isNumeric = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.label(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: AppStyle.label(color: AppColors.dataPrimary, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.foundation,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _DialogInfo extends StatelessWidget {
  final String label;
  final String value;
  const _DialogInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyle.label(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value.toUpperCase(), style: AppStyle.label(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.actionAccent)),
      ],
    );
  }
}
