class AdminStats {
  final int totalUsers;
  final int totalProducts;
  final int totalTrades;
  final int activeTrades;
  final int completedTrades;
  final int pendingTrades;
  final Map<String, int> usersByRole;
  final DateTime lastUpdated;

  AdminStats({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalTrades,
    required this.activeTrades,
    required this.completedTrades,
    required this.pendingTrades,
    required this.usersByRole,
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
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}
