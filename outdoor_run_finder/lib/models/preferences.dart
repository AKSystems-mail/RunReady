import 'enums.dart';

class RoutePreferences {
  final double distance;
  final DistanceUnit unit;
  final RouteType routeType;
  final RouteMode mode;
  final String? customLocation;

  RoutePreferences({
    required this.distance,
    required this.unit,
    required this.routeType,
    required this.mode,
    this.customLocation,
  });

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'unit': distanceUnitToString(unit),
    'routeType': routeTypeToString(routeType),
    'mode': routeModeToString(mode),
    'customLocation': customLocation,
  };

  factory RoutePreferences.fromJson(Map<String, dynamic> json) => RoutePreferences(
    distance: (json['distance'] as num).toDouble(),
    unit: parseDistanceUnit(json['unit']),
    routeType: parseRouteType(json['routeType']),
    mode: parseRouteMode(json['mode']),
    customLocation: json['customLocation'],
  );
}
