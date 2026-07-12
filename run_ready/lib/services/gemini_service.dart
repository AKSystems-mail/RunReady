import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import '../models/preferences.dart';
import '../models/route_data.dart';
import '../models/weather_info.dart';
import 'weather_service.dart';

class GeminiService {
  static const String _osrmBase = 'https://router.project-osrm.org';
  final WeatherService _weatherService = WeatherService();

  Future<RouteData> generateRunRoute(
    RoutePreferences prefs, {
    double? lat,
    double? lng,
  }) async {
    // Build a friendly location string
    final locationString = _friendlyLocation(prefs, lat, lng);

    // Always try to use the provided coords or default to a real center point
    double centerLat = lat ?? 33.7490;
    double centerLng = lng ?? -84.3880;

    // If customLocation is a raw "lat,lng" from GPS, extract the numbers
    if (prefs.customLocation != null && prefs.customLocation!.contains(',')) {
      final parts = prefs.customLocation!.split(',');
      if (parts.length >= 2) {
        final parsedLat = double.tryParse(parts[0].trim());
        final parsedLng = double.tryParse(parts[1].trim());
        if (parsedLat != null && parsedLng != null) {
          centerLat = parsedLat;
          centerLng = parsedLng;
        }
      }
    }

    double distanceKm = prefs.unit == DistanceUnit.miles
        ? prefs.distance * 1.60934
        : prefs.distance;

    final tightness = 1.0;
    // More waypoints = tighter OSRM resolution; multiple laps for longer distances
    final lapCount = (distanceKm / 2.0).ceil().clamp(1, 4);
    final numWaypoints = (lapCount * 4).clamp(4, 16);

    final waypoints = _generateTightWaypoints(
      centerLat: centerLat,
      centerLng: centerLng,
      tightness: tightness,
      numWaypoints: numWaypoints,
      isLoop: prefs.routeType == RouteType.loop,
    );

    // Try OSRM for road-following route and real turn-by-turn directions
    List<String> routeCoords;
    List<String> directions;
    try {
      // Use cycling profile as the default for better run routes
      final result = await _fetchOSRMRouteWithDirections(
          waypoints, prefs.routeType == RouteType.loop, 'cycling');
      routeCoords = result.coords;
      directions = result.directions;
    } catch (e) {
      routeCoords = waypoints
          .map((w) => '${w.lat.toStringAsFixed(6)},${w.lng.toStringAsFixed(6)}')
          .toList();
      directions = _generateDirections(prefs, locationString);
    }

    final title = _generateTitle(prefs, locationString);
    final description = _generateDescription(prefs, locationString, distanceKm);

    // Fetch real weather from Open-Meteo
    WeatherInfo weather;
    try {
      weather = await _weatherService.fetchWeather(
        lat: centerLat,
        lng: centerLng,
      );
    } catch (e) {
      weather = WeatherInfo(
        temperature: '--°F',
        condition: 'Check locally',
        precipitationChance: '--%',
        sunrise: '--:--',
        sunset: '--:--',
        isComfortable: true,
        warnings: [],
      );
    }

    return RouteData(
      id: const Uuid().v4(),
      title: title,
      description: description,
      directions: directions,
      mapData: RouteMapData(
        start: '${centerLat.toStringAsFixed(6)},${centerLng.toStringAsFixed(6)}',
        end: '${centerLat.toStringAsFixed(6)},${centerLng.toStringAsFixed(6)}',
        waypoints: waypoints
            .map((w) => '${w.lat.toStringAsFixed(6)},${w.lng.toStringAsFixed(6)}')
            .toList(),
        routeCoordinates: routeCoords,
      ),
      waypoints: waypoints.asMap().entries.map((e) {
        final i = e.key;
        final w = e.value;
        return RouteWaypoint(
          title: 'Point ${i + 1}',
          uri: 'geo:${w.lat},${w.lng}',
        );
      }).toList(),
      weather: weather,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      preferences: prefs,
    );
  }

  /// Returns a human-friendly location string instead of raw lat/lng
  String _friendlyLocation(RoutePreferences prefs, double? lat, double? lng) {
    // If user set a custom location name, use it
    if (prefs.customLocation != null && prefs.customLocation!.isNotEmpty) {
      final loc = prefs.customLocation!;
      // Check if it looks like raw coordinates
      if (RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$').hasMatch(loc.trim())) {
        // It's a raw "lat, lng" from GPS — use a nicer alternative
        return 'your area';
      }
      return loc;
    }
    // No custom location at all
    return 'your area';
  }

  List<({double lat, double lng})> _generateTightWaypoints({
    required double centerLat,
    required double centerLng,
    required double tightness,
    required int numWaypoints,
    required bool isLoop,
  }) {
    // Very tight base radius — approximately 250m walkable area
    final baseRadius = 0.0025 * tightness;
    final points = <({double lat, double lng})>[];

    if (isLoop) {
      // Multiple tight laps around the same small cluster
      for (int i = 0; i < numWaypoints; i++) {
        final angle = (2 * pi * i) / numWaypoints;
        final latOffset = baseRadius * 0.9 * sin(angle);
        final lngOffset = baseRadius * cos(angle);
        points.add((
          lat: centerLat + latOffset,
          lng: centerLng + lngOffset,
        ));
      }
    } else {
      points.add((lat: centerLat, lng: centerLng));
      for (int i = 1; i < numWaypoints; i++) {
        final t = i / numWaypoints;
        final spread = 0.005 * tightness;
        points.add((
          lat: centerLat + spread * 1.2 * (t - 0.5) * 2,
          lng: centerLng + spread * (t - 0.5) * 2 + spread * 0.3,
        ));
      }
    }

    return points;
  }

  /// Fetches both road-following coordinates and real turn-by-turn directions from OSRM
  Future<({List<String> coords, List<String> directions})> _fetchOSRMRouteWithDirections(
    List<({double lat, double lng})> waypoints,
    bool isLoop,
    String profile, // Added profile parameter
  ) async {
    final coords = waypoints.map((w) => '${w.lng},${w.lat}').join(';');
    final url = '$_osrmBase/route/v1/$profile/$coords'
        '?overview=full&geometries=geojson&steps=true&alternatives=false';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('OSRM returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes from OSRM');
    }

    final route = routes[0] as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final polylineCoords = geometry['coordinates'] as List;

    final routeCoords = polylineCoords.map((c) {
      final lng = (c as List)[0] as num;
      final lat = c[1] as num;
      return '${lat.toDouble()},${lng.toDouble()}';
    }).toList();

    // Parse turn-by-turn directions from OSRM steps
    final legs = route['legs'] as List?;
    final directionList = <String>[];
    if (legs != null && legs.isNotEmpty) {
      for (final leg in legs) {
        final steps = (leg as Map<String, dynamic>)['steps'] as List?;
        if (steps == null) continue;
        for (int i = 0; i < steps.length; i++) {
          final step = steps[i] as Map<String, dynamic>;
          final maneuver = step['maneuver'] as Map<String, dynamic>?;
          final instruction = _formatOSRMStep(
            maneuver: maneuver,
            name: step['name'] as String? ?? '',
            distance: (step['distance'] as num?)?.toDouble() ?? 0,
            isLast: i == steps.length - 1,
          );
          if (instruction != null) {
            directionList.add(instruction);
          }
        }
      }
    }
    return (coords: routeCoords, directions: directionList);
  }


  String? _formatOSRMStep({
    required Map<String, dynamic>? maneuver,
    required String name,
    required double distance,
    required bool isLast,
  }) {
    if (isLast) {
      final distStr = distance >= 100
          ? '${(distance / 1000).toStringAsFixed(1)} km'
          : '${distance.toStringAsFixed(0)} m';
      return 'Finish ($distStr)';
    }

    if (maneuver == null) return null;

    final type = maneuver['type'] as String? ?? '';
    final modifier = maneuver['modifier'] as String? ?? '';

    // Build a human-readable turn instruction
    String action;
    switch (type) {
      case 'depart':
        action = name.isNotEmpty ? 'Head $modifier on $name' : 'Head $modifier';
        break;
      case 'turn':
      case 'new name':
        final dir = _turnWord(modifier);
        action = name.isNotEmpty ? '$dir onto $name' : '$dir';
        break;
      case 'continue':
        action = name.isNotEmpty ? 'Continue on $name' : 'Continue straight';
        break;
      case 'roundabout':
      case 'rotary':
        action = name.isNotEmpty ? 'Enter roundabout, exit onto $name' : 'Enter roundabout';
        break;
      case 'fork':
        action = name.isNotEmpty ? 'Keep $modifier onto $name' : 'Keep $modifier';
        break;
      case 'end of road':
        action = name.isNotEmpty ? 'Turn $modifier onto $name' : 'Turn $modifier';
        break;
      case 'merge':
        action = name.isNotEmpty ? 'Merge $modifier onto $name' : 'Merge $modifier';
        break;
      case 'ramp':
        action = name.isNotEmpty ? 'Take the ramp to $name' : 'Take the ramp';
        break;
      case 'arrive':
        return null; // Skip arrival steps
      default:
        action = name.isNotEmpty ? 'Continue on $name' : 'Continue';
    }

    final distStr = distance >= 100
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.toStringAsFixed(0)} m';
    return '$action ($distStr)';
  }

  String _turnWord(String modifier) {
    switch (modifier) {
      case 'left':
        return 'Turn left';
      case 'right':
        return 'Turn right';
      case 'sharp left':
        return 'Sharp left';
      case 'sharp right':
        return 'Sharp right';
      case 'slight left':
        return 'Slight left';
      case 'slight right':
        return 'Slight right';
      case 'straight':
        return 'Continue straight';
      case 'uturn':
        return 'Make a U-turn';
      default:
        return 'Turn $modifier';
    }
  }

  String _generateTitle(RoutePreferences prefs, String location) {
    final type = prefs.routeType == RouteType.loop ? 'Loop' : 'Point-to-Point';
    final mode = prefs.mode == RouteMode.local ? 'Neighborhood' : 'Scenic';
    return '$mode ${prefs.distance}${distanceUnitToString(prefs.unit)} $type';
  }

  String _generateDescription(
      RoutePreferences prefs, String location, double km) {
    final dist = '${prefs.distance} ${distanceUnitToString(prefs.unit)}';
    if (prefs.mode == RouteMode.local) {
      if (location == 'your area') {
        return 'A compact $dist loop route near you. '
            'Perfect for a quick, efficient run close to home with minimal traffic. '
            'This tight loop keeps you in familiar territory.';
      }
      return 'A compact $dist route around $location. '
          'Perfect for a quick, efficient run close to home with minimal traffic. '
          'This tight loop keeps you in familiar territory.';
    } else {
      if (location == 'your area') {
        return 'An exploratory $dist route near you '
            'featuring varied scenery and interesting streets. '
            'A well-paced run for discovering new paths.';
      }
      return 'An exploratory $dist route through $location '
          'featuring varied scenery and interesting streets. '
          'A well-paced run for discovering new paths.';
    }
  }

  List<String> _generateDirections(RoutePreferences prefs, String location) {
    final unit = distanceUnitToString(prefs.unit);
    return [
      if (location == 'your area')
        'Start from your current location'
      else
        'Start from your location in $location',
      'Head out on the main route at a steady pace',
      'Follow the path through neighborhood streets',
      'Maintain your rhythm and enjoy the run',
      'Finish strong back at your starting point',
    ];
  }
}
