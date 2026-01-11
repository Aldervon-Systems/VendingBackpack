class InventoryItem {
  final String sku;
  final String name;
  final int qty;
  final String barcode;

  InventoryItem({required this.sku, required this.name, required this.qty, required this.barcode});

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      qty: json['qty'] ?? 0,
      barcode: json['barcode'] ?? '',
    );
  }
}
