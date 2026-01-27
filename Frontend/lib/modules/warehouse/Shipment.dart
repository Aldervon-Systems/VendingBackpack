class Shipment {
  final String id;
  final String description;
  final int amount;
  final DateTime date;
  final String status;

  Shipment({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount'] ?? 0,
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'scheduled',
    );
  }
}
