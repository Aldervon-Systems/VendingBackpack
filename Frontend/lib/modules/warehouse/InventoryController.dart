import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';
import 'InventoryItem.dart';
import 'Shipment.dart';

class InventoryController extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<InventoryItem> _inventory = [];
  List<Shipment> _shipments = [];
  bool _isLoading = false;

  List<InventoryItem> get inventory => _inventory;
  List<Shipment> get shipments => _shipments;
  bool get isLoading => _isLoading;

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/warehouse');
      if (data is List) {
        _inventory = data.map((e) => InventoryItem.fromJson(e)).toList();
      }
      
      final shipmentData = await _api.get('/warehouse/shipments');
      if (shipmentData is List) {
        _shipments = shipmentData.map((e) => Shipment.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> checkBarcode(String barcode) async {
    try {
      final data = await _api.get('/items/$barcode');
      if (data != null && data['sku'] != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error checking barcode: $e');
    }
    return null;
  }

  Future<void> addBarcodeStock(String barcode, String name, int qty) async {
    try {
      await _api.post('/warehouse/add_stock', {
        'barcode': barcode,
        'name': name,
        'quantity': qty,
      });
      await loadInventory();
    } catch (e) {
      debugPrint('Error adding barcode stock: $e');
      rethrow;
    }
  }

  Future<void> addShipment(String description, int amount, DateTime date) async {
    try {
      await _api.post('/warehouse/shipments', {
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'status': 'scheduled',
      });
      await loadInventory();
    } catch (e) {
      debugPrint('Error adding shipment: $e');
      rethrow;
    }
  }
}
