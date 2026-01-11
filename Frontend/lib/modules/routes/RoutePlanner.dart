import 'package:flutter/foundation.dart';
import '../../core/services/ApiClient.dart';

class RoutePlanner extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<dynamic> _locations = [];
  bool _isLoading = false;

  List<dynamic> get locations => _locations;
  bool get isLoading => _isLoading;

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/routes');
      if (data is Map && data['locations'] is List) {
        _locations = data['locations'];
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
