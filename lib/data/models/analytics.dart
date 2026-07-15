/// Models for the dashboard analytics endpoints.
///   - GET /dashboard/activity-trend  → List<ActivityTrendPoint>
///   - GET /dashboard/room-occupancy  → List<RoomOccupancy>

/// One day of movement activity, split by action type.
class ActivityTrendPoint {
  final String date; // 'YYYY-MM-DD'
  final int assigned;
  final int returned;
  final int issued;
  final int moved;
  final int total;

  ActivityTrendPoint({
    required this.date,
    required this.assigned,
    required this.returned,
    required this.issued,
    required this.moved,
    required this.total,
  });

  factory ActivityTrendPoint.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return ActivityTrendPoint(
      date: json['date'] as String? ?? '',
      assigned: asInt(json['assigned']),
      returned: asInt(json['returned']),
      issued: asInt(json['issued']),
      moved: asInt(json['moved']),
      total: asInt(json['total']),
    );
  }

  /// Short weekday-ish label for the x-axis, derived from the date string.
  String get shortLabel {
    final parts = date.split('-');
    if (parts.length != 3) return '';
    final dt = DateTime.tryParse(date);
    if (dt == null) return parts.last;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
}

/// Capacity/occupancy roll-up for a single room.
class RoomOccupancy {
  final String roomId;
  final String roomName;
  final int boxes;
  final int capacity;
  final int occupied;
  final int vacant;
  final double occupancyRate; // 0..100

  RoomOccupancy({
    required this.roomId,
    required this.roomName,
    required this.boxes,
    required this.capacity,
    required this.occupied,
    required this.vacant,
    required this.occupancyRate,
  });

  factory RoomOccupancy.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0.0;
    return RoomOccupancy(
      roomId: json['roomId'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      boxes: asInt(json['boxes']),
      capacity: asInt(json['capacity']),
      occupied: asInt(json['occupied']),
      vacant: asInt(json['vacant']),
      occupancyRate: asDouble(json['occupancyRate']),
    );
  }

  /// Occupancy as a 0..1 fraction (safe when capacity is 0).
  double get fraction => capacity > 0 ? occupied / capacity : 0.0;
}
