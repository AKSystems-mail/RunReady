import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import '../models/preferences.dart';
import '../models/route_data.dart';
import '../models/weather_info.dart';

/// Mock service for development/testing without Gemini API
class MockGeminiService {
  Future<RouteData> generateRunRoute(
    RoutePreferences prefs, {
    double? lat,
    double? lng,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    final location =
        prefs.customLocation ?? (lat != null ? 'Current Location' : 'Unknown');

    return RouteData(
      id: const Uuid().v4(),
      title: _generateTitle(prefs),
      description: _generateDescription(prefs, location),
      directions: _generateDirections(prefs),
      mapData: RouteMapData(
        start: location,
        end: prefs.routeType == RouteType.loop ? location : 'Finish Point',
        waypoints: ['Waypoint 1', 'Waypoint 2'],
      ),
      waypoints: [],
      weather: WeatherInfo(
        temperature: '18°C',
        condition: 'Partly Cloudy',
        precipitationChance: '10%',
        sunrise: '6:45 AM',
        sunset: '5:30 PM',
        isComfortable: true,
        warnings: [],
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      preferences: prefs,
    );
  }

  String _generateTitle(RoutePreferences prefs) {
    final mode = prefs.mode == RouteMode.local ? 'Neighborhood' : 'Scenic';
    final type = prefs.routeType == RouteType.loop ? 'Loop' : 'Run';
    return '$mode ${prefs.distance} ${distanceUnitToString(prefs.unit)} $type';
  }

  String _generateDescription(RoutePreferences prefs, String location) {
    if (prefs.mode == RouteMode.local) {
      return 'A safe, local route around $location. Perfect for a quick run close to home with minimal traffic.';
    } else {
      return 'An exploratory route through $location featuring scenic views and interesting landmarks along the way.';
    }
  }

  List<String> _generateDirections(RoutePreferences prefs) {
    return [
      'Start at your current location',
      'Head north on Main Street for 0.5 ${distanceUnitToString(prefs.unit)}',
      'Turn right onto Park Avenue',
      'Continue straight through the park',
      'Turn left onto Oak Street',
      if (prefs.routeType == RouteType.loop) 'Return to starting point',
      if (prefs.routeType == RouteType.finishLine) 'Finish at destination',
    ];
  }
}
