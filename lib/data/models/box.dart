class Box {
  final String id;
  final String qrCode;
  final String label;
  final int capacity;
  final int occupiedCount;
  final String status;
  final String? location;
  final Slot? slot;
  final List<PassportSummary>? passports;
  final DateTime createdAt;
  final DateTime updatedAt;

  Box({
    required this.id,
    required this.qrCode,
    required this.label,
    required this.capacity,
    required this.occupiedCount,
    required this.status,
    this.location,
    this.slot,
    this.passports,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Box.fromJson(Map<String, dynamic> json) {
    return Box(
      id: json['id'] as String,
      qrCode: json['qrCode'] as String,
      label: json['label'] as String,
      capacity: json['capacity'] as int,
      occupiedCount: json['occupiedCount'] as int,
      status: json['status'] as String,
      location: json['location'] as String?,
      slot: json['slot'] != null ? Slot.fromJson(json['slot']) : null,
      passports: json['passports'] != null
          ? (json['passports'] as List)
              .map((p) => PassportSummary.fromJson(p))
              .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  int get vacantCount => capacity - occupiedCount;
  double get utilization => capacity > 0 ? (occupiedCount / capacity) * 100 : 0;
}

class Slot {
  final String id;
  final String name;
  final String? qrCode;
  final Row? row;

  Slot({
    required this.id,
    required this.name,
    this.qrCode,
    this.row,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] as String,
      name: json['name'] as String,
      qrCode: json['qrCode'] as String?,
      row: json['row'] != null ? Row.fromJson(json['row']) : null,
    );
  }
}

class Row {
  final String name;
  final Shelf? shelf;

  Row({
    required this.name,
    this.shelf,
  });

  factory Row.fromJson(Map<String, dynamic> json) {
    return Row(
      name: json['name'] as String,
      shelf: json['shelf'] != null ? Shelf.fromJson(json['shelf']) : null,
    );
  }
}

class Shelf {
  final String name;
  final Room? room;

  Shelf({
    required this.name,
    this.room,
  });

  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      name: json['name'] as String,
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
    );
  }
}

class Room {
  final String name;

  Room({required this.name});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      name: json['name'] as String,
    );
  }
}

class PassportSummary {
  final String id;
  final String qrCode;
  final String holderName;
  final String holderIdNo;
  final String status;

  PassportSummary({
    required this.id,
    required this.qrCode,
    required this.holderName,
    required this.holderIdNo,
    required this.status,
  });

  factory PassportSummary.fromJson(Map<String, dynamic> json) {
    return PassportSummary(
      id: json['id'] as String,
      qrCode: json['qrCode'] as String,
      holderName: json['holderName'] as String,
      holderIdNo: json['holderIdNo'] as String,
      status: json['status'] as String,
    );
  }
}
