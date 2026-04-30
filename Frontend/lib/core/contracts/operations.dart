class EmployeeDto {
  final String id;
  final String name;
  final int? color;
  final String? department;
  final String? location;
  final String? floor;
  final String? building;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  EmployeeDto({
    required this.id,
    required this.name,
    required this.color,
    required this.department,
    required this.location,
    required this.floor,
    required this.building,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: json['color'] is num ? (json['color'] as num).toInt() : null,
      department: json['department']?.toString(),
      location: json['location']?.toString(),
      floor: json['floor']?.toString(),
      building: json['building']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class MachineDto {
  final String id;
  final String name;
  final String? vin;
  final String? organizationId;
  final String status;
  final int battery;
  final double? lat;
  final double? lng;
  final String? location;
  final String? createdAt;
  final String? updatedAt;

  MachineDto({
    required this.id,
    required this.name,
    required this.vin,
    required this.organizationId,
    required this.status,
    required this.battery,
    required this.lat,
    required this.lng,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MachineDto.fromJson(Map<String, dynamic> json) {
    return MachineDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      vin: json['vin']?.toString(),
      organizationId: json['organizationId']?.toString() ??
          json['organization_id']?.toString(),
      status: json['status']?.toString() ?? 'attention',
      battery: json['battery'] is num ? (json['battery'] as num).toInt() : 0,
      lat: json['lat'] is num ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] is num ? (json['lng'] as num).toDouble() : null,
      location: json['location']?.toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class ItemDto {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? slotNumber;
  final bool isAvailable;
  final String? imageUrl;
  final String? barcode;
  final String? createdAt;
  final String? updatedAt;

  ItemDto({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.slotNumber,
    required this.isAvailable,
    required this.imageUrl,
    required this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    return ItemDto(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0,
      quantity:
          json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
      slotNumber:
          json['slotNumber']?.toString() ?? json['slot_number']?.toString(),
      isAvailable:
          json['isAvailable'] == true || json['is_available'] == true,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      barcode: json['barcode']?.toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class WarehouseInventoryRowDto {
  final int itemId;
  final String sku;
  final String name;
  final int quantity;
  final String? barcode;

  WarehouseInventoryRowDto({
    required this.itemId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.barcode,
  });

  factory WarehouseInventoryRowDto.fromJson(Map<String, dynamic> json) {
    return WarehouseInventoryRowDto(
      itemId: json['itemId'] is num
          ? (json['itemId'] as num).toInt()
          : (json['item_id'] as num?)?.toInt() ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity:
          json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
      barcode: json['barcode']?.toString(),
    );
  }
}

class MachineInventoryItemDto {
  final int itemId;
  final String sku;
  final String name;
  final int quantity;
  final String? barcode;
  final String? slotNumber;

  MachineInventoryItemDto({
    required this.itemId,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.barcode,
    required this.slotNumber,
  });

  factory MachineInventoryItemDto.fromJson(Map<String, dynamic> json) {
    return MachineInventoryItemDto(
      itemId: json['itemId'] is num
          ? (json['itemId'] as num).toInt()
          : (json['item_id'] as num?)?.toInt() ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity:
          json['quantity'] is num ? (json['quantity'] as num).toInt() : 0,
      barcode: json['barcode']?.toString(),
      slotNumber:
          json['slotNumber']?.toString() ?? json['slot_number']?.toString(),
    );
  }
}

class MachineInventorySnapshotDto {
  final String machineId;
  final String machineName;
  final String status;
  final String? location;
  final List<MachineInventoryItemDto> items;

  MachineInventorySnapshotDto({
    required this.machineId,
    required this.machineName,
    required this.status,
    required this.location,
    required this.items,
  });

  factory MachineInventorySnapshotDto.fromJson(Map<String, dynamic> json) {
    return MachineInventorySnapshotDto(
      machineId:
          json['machineId']?.toString() ?? json['machine_id']?.toString() ?? '',
      machineName: json['machineName']?.toString() ??
          json['machine_name']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'attention',
      location: json['location']?.toString(),
      items: ((json['items'] as List?) ?? [])
          .whereType<Map>()
          .map((row) =>
              MachineInventoryItemDto.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
    );
  }
}

class RouteStopDto {
  final String machineId;
  final String name;
  final double lat;
  final double lng;
  final String? location;
  final int position;

  RouteStopDto({
    required this.machineId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.location,
    required this.position,
  });

  factory RouteStopDto.fromJson(Map<String, dynamic> json) {
    return RouteStopDto(
      machineId: json['machineId']?.toString() ??
          json['machine_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      lat: json['lat'] is num ? (json['lat'] as num).toDouble() : 0,
      lng: json['lng'] is num ? (json['lng'] as num).toDouble() : 0,
      location: json['location']?.toString(),
      position:
          json['position'] is num ? (json['position'] as num).toInt() : 0,
    );
  }
}

class RouteDto {
  final int? id;
  final String employeeId;
  final String employeeName;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStopDto> stops;
  final String? createdAt;
  final String? updatedAt;

  RouteDto({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.stops,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    return RouteDto(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      employeeId:
          json['employeeId']?.toString() ?? json['employee_id']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ??
          json['employee_name']?.toString() ??
          '',
      distanceMeters: json['distanceMeters'] is num
          ? (json['distanceMeters'] as num).toDouble()
          : (json['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: json['durationSeconds'] is num
          ? (json['durationSeconds'] as num).toDouble()
          : (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      stops: ((json['stops'] as List?) ?? [])
          .whereType<Map>()
          .map((row) => RouteStopDto.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class ShipmentDto {
  final int id;
  final String description;
  final int amount;
  final String scheduledFor;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  ShipmentDto({
    required this.id,
    required this.description,
    required this.amount,
    required this.scheduledFor,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShipmentDto.fromJson(Map<String, dynamic> json) {
    return ShipmentDto(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      description: json['description']?.toString() ?? '',
      amount: json['amount'] is num ? (json['amount'] as num).toInt() : 0,
      scheduledFor: json['scheduledFor']?.toString() ??
          json['scheduled_for']?.toString() ??
          json['date']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'scheduled',
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class DailyStatDto {
  final String date;
  final double amount;
  final int transactionCount;

  DailyStatDto({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });

  factory DailyStatDto.fromJson(Map<String, dynamic> json) {
    return DailyStatDto(
      date: json['date']?.toString() ?? '',
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : 0,
      transactionCount: json['transactionCount'] is num
          ? (json['transactionCount'] as num).toInt()
          : (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

