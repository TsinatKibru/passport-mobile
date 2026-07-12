class DashboardStats {
  final int totalPassports;
  final int inBox;
  final int issued;
  final int totalBoxes;
  final int occupiedBoxes;
  final int activeBoxes;
  final int fullBoxes;
  final int inactiveBoxes;
  final int vacantBoxes;
  final int totalCapacity;
  final int totalOccupied;
  final int totalVacant;

  DashboardStats({
    required this.totalPassports,
    required this.inBox,
    required this.issued,
    required this.totalBoxes,
    required this.occupiedBoxes,
    required this.activeBoxes,
    required this.fullBoxes,
    required this.inactiveBoxes,
    required this.vacantBoxes,
    required this.totalCapacity,
    required this.totalOccupied,
    required this.totalVacant,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPassports: json['totalPassports'] as int,
      inBox: json['inBox'] as int,
      issued: json['issued'] as int,
      totalBoxes: json['totalBoxes'] as int,
      occupiedBoxes: json['occupiedBoxes'] as int,
      activeBoxes: json['activeBoxes'] as int,
      fullBoxes: json['fullBoxes'] as int,
      inactiveBoxes: json['inactiveBoxes'] as int,
      vacantBoxes: json['vacantBoxes'] as int,
      totalCapacity: json['totalCapacity'] as int,
      totalOccupied: json['totalOccupied'] as int,
      totalVacant: json['totalVacant'] as int,
    );
  }

  // Calculate trends (placeholder - would need historical data)
  String get passportTrend => '+5.2%';
  String get inBoxTrend => '+2.1%';
  String get issuedTrend => '+12.3%';
  String get boxesTrend => '+1.8%';
}
