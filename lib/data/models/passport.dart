class Passport {
  final String id;
  final String qrCode;
  final String holderName;
  final String holderIdNo;
  final String status;
  final DateTime? dateReturned;
  final DateTime? dateIssued;
  final BoxSummary? box;
  final String? location; // full path: "Room / Shelf / Row / Slot" — from API root field
  final DateTime createdAt;
  final DateTime updatedAt;

  Passport({
    required this.id,
    required this.qrCode,
    required this.holderName,
    required this.holderIdNo,
    required this.status,
    this.dateReturned,
    this.dateIssued,
    this.box,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Passport.fromJson(Map<String, dynamic> json) {
    return Passport(
      id: json['id'] as String,
      qrCode: json['qrCode'] as String,
      holderName: json['holderName'] as String,
      holderIdNo: json['holderIdNo'] as String,
      status: json['status'] as String,
      dateReturned: json['dateReturned'] != null
          ? DateTime.parse(json['dateReturned'] as String)
          : null,
      dateIssued: json['dateIssued'] != null
          ? DateTime.parse(json['dateIssued'] as String)
          : null,
      box: json['box'] != null ? BoxSummary.fromJson(json['box']) : null,
      // API sets location at the passport root, not inside box
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  bool get isInBox => status == 'IN_BOX';
  bool get isIssued => status == 'ISSUED';
}

class BoxSummary {
  final String id;
  final String qrCode;
  final String label;
  final String? location;

  BoxSummary({
    required this.id,
    required this.qrCode,
    required this.label,
    this.location,
  });

  factory BoxSummary.fromJson(Map<String, dynamic> json) {
    return BoxSummary(
      id: json['id'] as String,
      qrCode: json['qrCode'] as String,
      label: json['label'] as String,
      location: json['location'] as String?,
    );
  }
}
