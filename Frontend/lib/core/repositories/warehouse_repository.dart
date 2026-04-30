import '../contracts/operations.dart';
import '../services/ApiClient.dart';

class WarehouseRepository {
  final ApiClient _api;

  WarehouseRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<WarehouseInventoryRowDto>> getWarehouse() async {
    final data = await _api.get('/warehouse');
    return (data as List)
        .whereType<Map>()
        .map((row) =>
            WarehouseInventoryRowDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ShipmentDto>> getShipments() async {
    final data = await _api.get('/warehouse/shipments');
    return (data as List)
        .whereType<Map>()
        .map((row) => ShipmentDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ItemDto> lookupBarcode(String barcode) async {
    final data = await _api.get('/items/barcode/$barcode');
    return ItemDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> addStock({
    required String barcode,
    required String name,
    required int quantity,
  }) async {
    await _api.post('/warehouse/add_stock', {
      'barcode': barcode,
      'name': name,
      'quantity': quantity,
    });
  }

  Future<void> scheduleShipment({
    required String description,
    required int amount,
    required DateTime scheduledFor,
  }) async {
    await _api.post('/warehouse/shipments', {
      'description': description,
      'amount': amount,
      'scheduledFor': scheduledFor.toIso8601String(),
      'status': 'scheduled',
    });
  }
}

