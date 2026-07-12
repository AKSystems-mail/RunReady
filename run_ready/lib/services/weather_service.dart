import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/weather_info.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherInfo> fetchWeather({
    required double lat,
    required double lng,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'current': 'temperature_2m,precipitation,weather_code',
        'daily': 'precipitation_probability_max,sunrise,sunset',
        'timezone': 'auto',
        'temperature_unit': 'fahrenheit',
      });

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _fallbackWeather();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseWeatherResponse(data);
    } catch (e) {
      return _fallbackWeather();
    }
  }

  WeatherInfo _parseWeatherResponse(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;

    // Temperature
    String temp = '--°F';
    if (current != null && current['temperature_2m'] != null) {
      final t = (current['temperature_2m'] as num).round();
      temp = '$t°F';
    }

    // Precipitation
    String precip = '--%';
    if (daily != null &&
        daily['precipitation_probability_max'] != null) {
      final probs = daily['precipitation_probability_max'] as List;
      if (probs.isNotEmpty && probs[0] != null) {
        precip = '${(probs[0] as num).round()}%';
      }
    }

    // Sunrise / Sunset
    String sunrise = '--:--';
    String sunset = '--:--';
    if (daily != null) {
      if (daily['sunrise'] != null) {
        final sunrises = daily['sunrise'] as List;
        if (sunrises.isNotEmpty && sunrises[0] is String) {
          final raw = sunrises[0] as String;
          // Format: 2026-07-11T06:23:00 -> extract time
          sunrise = _formatTime(raw);
        }
      }
      if (daily['sunset'] != null) {
        final sunsets = daily['sunset'] as List;
        if (sunsets.isNotEmpty && sunsets[0] is String) {
          final raw = sunsets[0] as String;
          sunset = _formatTime(raw);
        }
      }
    }

    // Comfort check based on weather code and temperature
    bool isComfortable = true;
    final warnings = <String>[];

    // Check temperature
    if (current != null && current['temperature_2m'] != null) {
      final t = (current['temperature_2m'] as num).toDouble();
      if (t > 90) {
        isComfortable = false;
        warnings.add('High heat — consider running early or late');
      } else if (t < 20) {
        isComfortable = false;
        warnings.add('Very cold — dress in layers');
      } else if (t > 80) {
        warnings.add('Warm — stay hydrated');
      }
    }

    // Check weather code
    if (current != null && current['weather_code'] != null) {
      final code = (current['weather_code'] as num).toInt();
      final weatherAlert = _weatherCodeAlert(code);
      if (weatherAlert != null) {
        isComfortable = false;
        warnings.add(weatherAlert);
      }
    }

    return WeatherInfo(
      temperature: temp,
      condition: 'Check locally',
      precipitationChance: precip,
      sunrise: sunrise,
      sunset: sunset,
      isComfortable: isComfortable,
      warnings: warnings,
    );
  }

  String _formatTime(String isoTime) {
    try {
      // ISO format: 2026-07-11T06:23:00
      final parts = isoTime.split('T');
      if (parts.length == 2) {
        final timePart = parts[1];
        // Remove seconds
        final segments = timePart.split(':');
        if (segments.length >= 2) {
          final hour = int.parse(segments[0]);
          final minute = segments[1];
          final ampm = hour >= 12 ? 'PM' : 'AM';
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$hour12:$minute $ampm';
        }
      }
    } catch (_) {}
    return '--:--';
  }

  String? _weatherCodeAlert(int code) {
    // WMO Weather codes — only alert on significant conditions
    if (code >= 95) return 'Thunderstorms expected';
    if (code >= 82 && code <= 84) return 'Heavy rain expected';
    if (code >= 71 && code <= 77) return 'Snow expected';
    if (code == 45 || code == 48) return 'Fog — reduced visibility';
    if (code >= 51 && code <= 57) return 'Drizzle expected';
    if (code >= 61 && code <= 65) return 'Rain expected';
    return null;
  }

  WeatherInfo _fallbackWeather() {
    return WeatherInfo(
      temperature: '--°F',
      condition: 'Check locally',
      precipitationChance: '--%',
      sunrise: '--:--',
      sunset: '--:--',
      isComfortable: true,
      warnings: [],
    );
  }
}
