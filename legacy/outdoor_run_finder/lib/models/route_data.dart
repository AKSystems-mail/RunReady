import 'preferences.dart';
import 'weather_info.dart';

class RouteMapData {
  final String start;
  final String end;
  final List<String> waypoints;

  RouteMapData({
    required this.start,
    required this.end,
    required this.waypoints,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'waypoints': waypoints,
  };

  factory RouteMapData.fromJson(Map<String, dynamic> json) => RouteMapData(
    start: json['start'],
    end: json['end'],
    waypoints: List<String>.from(json['waypoints']),
  );
}

class RouteWaypoint {
  final String title;
  final String uri;

  RouteWaypoint({required this.title, required this.uri});

  Map<String, dynamic> toJson() => {'title': title, 'uri': uri};

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) =>
      RouteWaypoint(title: json['title'], uri: json['uri']);
}

class RouteData {
  final String id;
  final String title;
  final String description;
  final List<String>? directions;
  final RouteMapData? mapData;
  final List<RouteWaypoint> waypoints;
  final WeatherInfo? weather;
  final int createdAt;
  final RoutePreferences preferences;

  RouteData({
    required this.id,
    required this.title,
    required this.description,
    this.directions,
    this.mapData,
    required this.waypoints,
    this.weather,
    required this.createdAt,
    required this.preferences,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'directions': directions,
    'mapData': mapData?.toJson(),
    'waypoints': waypoints.map((w) => w.toJson()).toList(),
    'weather': weather?.toJson(),
    'createdAt': createdAt,
    'preferences': preferences.toJson(),
  };

  factory RouteData.fromJson(Map<String, dynamic> json) => RouteData(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    directions: json['directions'] != null
        ? List<String>.from(json['directions'])
        : null,
    mapData: json['mapData'] != null
        ? RouteMapData.fromJson(json['mapData'])
        : null,
    waypoints: (json['waypoints'] as List)
        .map((w) => RouteWaypoint.fromJson(w))
        .toList(),
    weather: json['weather'] != null
        ? WeatherInfo.fromJson(json['weather'])
        : null,
    createdAt: json['createdAt'],
    preferences: RoutePreferences.fromJson(json['preferences']),
  );
}
