import 'enums.dart';

class RunSession {
  final String routeId;
  final int startTime;
  final int endTime;
  final int durationSeconds;
  final double distance;
  final DistanceUnit unit;

  RunSession({
    required this.routeId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distance,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'startTime': startTime,
    'endTime': endTime,
    'durationSeconds': durationSeconds,
    'distance': distance,
    'unit': distanceUnitToString(unit),
  };

  factory RunSession.fromJson(Map<String, dynamic> json) => RunSession(
    routeId: json['routeId'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    durationSeconds: json['durationSeconds'],
    distance: (json['distance'] as num).toDouble(),
    unit: parseDistanceUnit(json['unit']),
  );
}
