import '../services/ApiClient.dart';

class CorporateRepository {
  final ApiClient _api;

  CorporateRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<Map<String, dynamic>> getSnapshot() async {
    return Map<String, dynamic>.from(await _api.get('/corporate') as Map);
  }

  Future<Map<String, dynamic>> getPreferences() async {
    return Map<String, dynamic>.from(
      await _api.get('/corporate/preferences') as Map,
    );
  }

  Future<Map<String, dynamic>> savePreferences(
    Map<String, dynamic> preferences,
  ) async {
    return Map<String, dynamic>.from(
      await _api.put('/corporate/preferences', preferences) as Map,
    );
  }
}
