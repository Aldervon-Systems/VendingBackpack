import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_data.dart';

class WarehouseApi {
  static Future<List<Map<String, dynamic>>> getAllItems() async {
    final resp = await http.get(Uri.parse('$baseUrl/warehouse/items'));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  }
  // Use the common LocalData base URL so the app consistently uses LAN or localhost as configured
  static String baseUrl = localDataBaseUrl();

  static Future<Map<String, dynamic>?> getItem(String barcode) async {
    final resp = await http.get(Uri.parse('$baseUrl/warehouse/item/$barcode'));
    if (resp.statusCode == 200) {
      return json.decode(resp.body);
    }
    return null;
  }

  static Future<bool> addItem(Map<String, dynamic> item) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/warehouse/item'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(item),
    );
    return resp.statusCode == 200;
  }

  static Future<bool> checkIn(String barcode, int qty, String location) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/warehouse/checkin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'barcode': barcode, 'qty': qty, 'location': location}),
    );
    return resp.statusCode == 200;
  }

  static Future<bool> checkOut(String barcode, int qty, String location) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/warehouse/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'barcode': barcode, 'qty': qty, 'location': location}),
    );
    return resp.statusCode == 200;
  }

  static Future<bool> updateMachineInventory(String machineId, List<Map<String, dynamic>> skus) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/inventory/machine/$machineId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(skus),
    );
    return resp.statusCode == 200;
  }
}
