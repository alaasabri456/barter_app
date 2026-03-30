class AdminStats {
  final int totalUsers;
  final int totalProducts;
  final int totalTrades;
  final int activeTrades;
  final int completedTrades;
  final int pendingTrades;
  final Map<String, int> usersByRole;
  final int totalReports;
  final int pendingReports;
  final DateTime lastUpdated;

  AdminStats({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalTrades,
    required this.activeTrades,
    required this.completedTrades,
    required this.pendingTrades,
    required this.usersByRole,
    this.totalReports = 0,
    this.pendingReports = 0,
    required this.lastUpdated,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalTrades: json['totalTrades'] ?? 0,
      activeTrades: json['activeTrades'] ?? 0,
      completedTrades: json['completedTrades'] ?? 0,
      pendingTrades: json['pendingTrades'] ?? 0,
      usersByRole: Map<String, int>.from(json['usersByRole'] ?? {}),
      totalReports: json['totalReports'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'totalProducts': totalProducts,
    'totalTrades': totalTrades,
    'activeTrades': activeTrades,
    'completedTrades': completedTrades,
    'pendingTrades': pendingTrades,
    'usersByRole': usersByRole,
    'totalReports': totalReports,
    'pendingReports': pendingReports,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}
