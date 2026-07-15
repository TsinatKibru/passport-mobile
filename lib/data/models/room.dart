/// Hierarchy: Room → Shelf → VaultRow → VaultSlot → SlotBox
///
/// IMPORTANT: The model classes are prefixed with 'Vault' to avoid name
/// conflicts with Flutter built-in widgets (Row, Column, etc.) and Dart
/// types. Always import this file and use VaultRow / VaultSlot explicitly.

class Room {
  final String id;
  final String name;
  final String? qrCode;
  final int? shelfCount;

  Room({required this.id, required this.name, this.qrCode, this.shelfCount});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      qrCode: json['qrCode'] as String?,
      shelfCount: json['_count']?['shelves'] as int?,
    );
  }
}

class Shelf {
  final String id;
  final String name;
  final String qrCode;
  final int position;
  final String roomId;
  final int? rowCount;

  Shelf({
    required this.id,
    required this.name,
    required this.qrCode,
    required this.position,
    required this.roomId,
    this.rowCount,
  });

  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      id: json['id'] as String,
      name: json['name'] as String,
      qrCode: json['qrCode'] as String,
      position: json['position'] as int,
      roomId: json['roomId'] as String,
      rowCount: json['_count']?['rows'] as int?,
    );
  }
}

/// A physical vault row (renamed from Row to avoid Flutter widget collision).
class VaultRow {
  final String id;
  final String name;
  final String qrCode;
  final int position;
  final String shelfId;
  final int? slotCount;

  VaultRow({
    required this.id,
    required this.name,
    required this.qrCode,
    required this.position,
    required this.shelfId,
    this.slotCount,
  });

  factory VaultRow.fromJson(Map<String, dynamic> json) {
    return VaultRow(
      id: json['id'] as String,
      name: json['name'] as String,
      qrCode: json['qrCode'] as String,
      position: json['position'] as int,
      shelfId: json['shelfId'] as String,
      slotCount: json['_count']?['slots'] as int?,
    );
  }
}

/// A physical vault slot (renamed from Slot to avoid future conflicts).
class VaultSlot {
  final String id;
  final String name;
  final String? qrCode; // slots no longer carry QR codes
  final int position;
  final String rowId;
  final List<SlotBox>? boxes;

  VaultSlot({
    required this.id,
    required this.name,
    this.qrCode,
    required this.position,
    required this.rowId,
    this.boxes,
  });

  factory VaultSlot.fromJson(Map<String, dynamic> json) {
    return VaultSlot(
      id: json['id'] as String,
      name: json['name'] as String,
      qrCode: json['qrCode'] as String?,
      position: json['position'] as int,
      rowId: json['rowId'] as String,
      boxes: json['boxes'] != null
          ? (json['boxes'] as List)
              .map((b) => SlotBox.fromJson(b as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class SlotBox {
  final String id;
  final String qrCode;
  final String label;
  final int occupiedCount;
  final int capacity;
  final String status;

  SlotBox({
    required this.id,
    required this.qrCode,
    required this.label,
    required this.occupiedCount,
    required this.capacity,
    required this.status,
  });

  factory SlotBox.fromJson(Map<String, dynamic> json) {
    return SlotBox(
      id: json['id'] as String,
      qrCode: json['qrCode'] as String,
      label: json['label'] as String,
      occupiedCount: json['occupiedCount'] as int,
      capacity: json['capacity'] as int,
      status: json['status'] as String,
    );
  }
}
