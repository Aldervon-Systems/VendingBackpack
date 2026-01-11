import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';
import 'InventoryItem.dart';

class InventoryController extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  Map<String, List<InventoryItem>> _inventory = {};
  bool _isLoading = false;

  Map<String, List<InventoryItem>> get inventory => _inventory;
  bool get isLoading => _isLoading;

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/warehouse');
      if (data is Map) {
         _inventory = {};
         data.forEach((key, value) {
           if (value is List) {
             _inventory[key] = value.map((e) => InventoryItem.fromJson(e)).toList();
           }
         });
      }
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
