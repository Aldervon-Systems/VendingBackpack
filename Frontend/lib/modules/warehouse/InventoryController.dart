import 'package:flutter/foundation.dart';
import '../../core/contracts/operations.dart';
import '../../core/repositories/warehouse_repository.dart';

class InventoryController extends ChangeNotifier {
  final WarehouseRepository _repository = WarehouseRepository();
  List<WarehouseInventoryRowDto> _inventory = [];
  List<ShipmentDto> _shipments = [];
  bool _isLoading = false;
  String? _error;

  List<WarehouseInventoryRowDto> get inventory => _inventory;
  List<ShipmentDto> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _inventory = await _repository.getWarehouse();
      _shipments = await _repository.getShipments();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> checkBarcode(String barcode) async {
    try {
      final item = await _repository.lookupBarcode(barcode.trim());
      if (item.sku.isNotEmpty) return {'sku': item.sku, 'name': item.name};
    } catch (e) {
      debugPrint('Error checking barcode: $e');
    }
    return null;
  }

  Future<void> addBarcodeStock(String barcode, String name, int qty) async {
    try {
      await _repository.addStock(barcode: barcode, name: name, quantity: qty);
      await loadInventory();
    } catch (e) {
      debugPrint('Error adding barcode stock: $e');
      rethrow;
    }
  }

  Future<void> addShipment(String description, int amount, DateTime date) async {
    try {
      await _repository.scheduleShipment(
        description: description,
        amount: amount,
        scheduledFor: date,
      );
      await loadInventory();
    } catch (e) {
      debugPrint('Error adding shipment: $e');
      rethrow;
    }
  }
}
