class UserStats {
  final int totalRuns;
  final double totalDistanceKm;
  final int totalTimeSeconds;
  final int? lastRunDate;

  UserStats({
    required this.totalRuns,
    required this.totalDistanceKm,
    this.totalTimeSeconds = 0,
    this.lastRunDate,
  });

  Map<String, dynamic> toJson() => {
    'totalRuns': totalRuns,
    'totalDistanceKm': totalDistanceKm,
    'totalTimeSeconds': totalTimeSeconds,
    'lastRunDate': lastRunDate,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalRuns: json['totalRuns'],
    totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
    totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
    lastRunDate: json['lastRunDate'],
  );
}
