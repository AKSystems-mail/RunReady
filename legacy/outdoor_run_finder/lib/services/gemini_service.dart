import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../config/env.dart';
import '../models/enums.dart';
import '../models/preferences.dart';
import '../models/route_data.dart';
import '../models/weather_info.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model:
          'gemini-2.0-flash', // Using 2.0 as it is the latest standard, or match 1.5-flash if preferred. React used 1.5-flash.
      apiKey: Env.geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  static const String _systemInstruction = '''
You are an expert running coach and route planner. Your goal is to find specific, real-world running routes for users based on their location and distance preferences using Google Maps data. 
You also provide safety and weather advice.
When generating a route:
1. Use the googleMaps tool to find actual landmarks, streets, and paths.
2. Use the googleSearch tool to check the current weather, sunrise, and sunset times for the location.
3. If the user wants a "Loop", the start and end point should be the same or very close.
4. If "Finish Line", the end point should be approximately the requested distance away.
5. Provide a text description of the turn-by-turn directions.
6. Assess if the weather is comfortable for running (Ideal: 5°C - 20°C / 40°F - 68°F). Warn if outside this range or if raining.
7. Crucial: You must identify specific street addresses or clear landmarks for the Start, End, and key intermediate Waypoints so a map can be plotted.
''';

  Future<RouteData> generateRunRoute(
    RoutePreferences prefs, {
    double? lat,
    double? lng,
  }) async {
    final locationString =
        prefs.customLocation ??
        (lat != null && lng != null ? '$lat, $lng' : "my current location");

    String modeInstruction;
    if (prefs.mode == RouteMode.local) {
      modeInstruction = '''
      MODE: LOCAL. 
      - Generate a compact route very close to the start location. 
      - Focus on circling safe neighborhood blocks, local parks, or a nearby track.
      - Keep it simple and safe. Avoid major highways.
      - The route should feel like a "home base" run.
      ''';
    } else {
      modeInstruction = '''
      MODE: EXPLORER.
      - Generate a scenic route that explores the area.
      - Look for interesting landmarks, trails, or popular running paths nearby.
      - Ideally, the route should offer some variety in scenery.
      ''';
    }

    final prompt =
        '''
    Plan a ${prefs.distance} ${distanceUnitToString(prefs.unit)} running route in $locationString.
    Route Type: ${routeTypeToString(prefs.routeType) == 'loop' ? 'Loop (start and end at same spot)' : 'Point-to-Point (Finish Line away from start)'}.
    $modeInstruction
    
    Tasks:
    1. Find a specific route using Google Maps.
    2. Check the current weather for this location right now. Include temp, conditions, and sunrise/sunset.
    3. Output the response in a structured text format (Markdown).
    
    Format the output exactly like this in Markdown:
    # Route Title (e.g., "Scenic Park Loop")
    
    ## Description
    [A very concise paragraph describing the route path, streets, and terrain. Maximum 3-5 sentences.]

    ## MapData
    Start: [Specific Start Address or Lat/Long]
    End: [Specific End Address or Lat/Long]
    Waypoints: [Waypoint 1 Address] | [Waypoint 2 Address] | [Waypoint 3 Address]

    ## Directions
    - [Step 1: Start at...]
    - [Step 2: Turn left on...]
    - [Step 3...]

    ## Weather
    Temp: [Value]
    Condition: [Value]
    Precipitation: [Value]
    Sunrise: [Time]
    Sunset: [Time]
    Comfortable: [Yes/No]
    Warnings: [List any heat/cold/rain warnings]
  ''';

    // Note: Tool config for location bias is not directly supported in the high-level Dart SDK in the same way as JS yet,
    // or requires specific construction. For now, we rely on the prompt location string.

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final text = response.text;
      if (text == null) {
        throw Exception("No text generated");
      }

      // Parse the markdown text
      return _parseRouteData(text, prefs);
    } catch (e) {
      print("Gemini API Error: $e");
      throw Exception("Failed to generate route. Please try again.");
    }
  }

  RouteData _parseRouteData(String text, RoutePreferences prefs) {
    // Regex helpers
    String? extract(String pattern) {
      final regExp = RegExp(pattern, multiLine: true, caseSensitive: false);
      final match = regExp.firstMatch(text);
      return match?.group(1)?.trim();
    }

    final title = extract(r'^# (.*$)$') ?? "Custom Run Route";

    final descriptionMatch = RegExp(
      r'## Description\s+([\s\S]*?)(?=##|$)',
      multiLine: true,
    ).firstMatch(text);
    final description =
        descriptionMatch?.group(1)?.trim() ?? "No description provided.";

    final directionsMatch = RegExp(
      r'## Directions\s+([\s\S]*?)(?=##|$)',
      multiLine: true,
    ).firstMatch(text);
    final directionsRaw = directionsMatch?.group(1)?.trim() ?? "";
    final directions = directionsRaw
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[-*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Parse Map Data
    RouteMapData? mapData;
    final mapDataMatch = RegExp(
      r'## MapData\s+([\s\S]*?)(?=##|$)',
      multiLine: true,
    ).firstMatch(text);
    if (mapDataMatch != null) {
      final mapText = mapDataMatch.group(1)!;
      final start = RegExp(
        r'Start: (.*)',
        caseSensitive: false,
      ).firstMatch(mapText)?.group(1)?.trim();
      final end = RegExp(
        r'End: (.*)',
        caseSensitive: false,
      ).firstMatch(mapText)?.group(1)?.trim();
      final waypointsStr = RegExp(
        r'Waypoints: (.*)',
        caseSensitive: false,
      ).firstMatch(mapText)?.group(1)?.trim();

      if (start != null && end != null) {
        final waypoints = waypointsStr != null
            ? waypointsStr
                  .split('|')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
            : <String>[];
        mapData = RouteMapData(start: start, end: end, waypoints: waypoints);
      }
    }

    // Parse Weather
    final weatherMatch = RegExp(
      r'## Weather\s+([\s\S]*?)(?=##|$)',
      multiLine: true,
    ).firstMatch(text);
    WeatherInfo? weather;
    if (weatherMatch != null) {
      final weatherText = weatherMatch.group(1)!;
      final temp =
          RegExp(
            r'Temp: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "Unknown";
      final cond =
          RegExp(
            r'Condition: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "Unknown";
      final precip =
          RegExp(
            r'Precipitation: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "None";
      final sunrise =
          RegExp(
            r'Sunrise: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "--:--";
      final sunset =
          RegExp(
            r'Sunset: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "--:--";
      final isComfortable =
          RegExp(
            r'Comfortable: (Yes|No)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.toLowerCase() ==
          'yes';
      final warningLine =
          RegExp(
            r'Warnings: (.*)',
            caseSensitive: false,
          ).firstMatch(weatherText)?.group(1)?.trim() ??
          "";
      final warnings =
          warningLine.isNotEmpty && warningLine.toLowerCase() != 'none'
          ? [warningLine]
          : <String>[];

      weather = WeatherInfo(
        temperature: temp,
        condition: cond,
        precipitationChance: precip,
        sunrise: sunrise,
        sunset: sunset,
        isComfortable: isComfortable,
        warnings: warnings,
      );
    }

    // Grounding waypoints (Not easily available in simple text response without specific grounding metadata access in Dart SDK yet, or requires different parsing. Skipping for now as it was fallback in React).
    final waypoints = <RouteWaypoint>[];

    return RouteData(
      id: const Uuid().v4(),
      title: title,
      description: description,
      directions: directions,
      mapData: mapData,
      waypoints: waypoints,
      weather: weather,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      preferences: prefs,
    );
  }
}
