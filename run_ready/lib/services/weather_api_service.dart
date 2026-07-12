import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_info.dart';

/// WMO Weather Interpretation Codes
/// https://open-meteo.com/en/docs#weathervariables
const Map<int, String> _wmoConditions = {
  0: 'Clear',
  1: 'Mainly Clear',
  2: 'Partly Cloudy',
  3: 'Overcast',
  45: 'Foggy',
  48: 'Depositing Rime Fog',
  51: 'Light Drizzle',
  53: 'Moderate Drizzle',
  55: 'Dense Drizzle',
  56: 'Freezing Light Drizzle',
  57: 'Freezing Dense Drizzle',
  61: 'Slight Rain',
  63: 'Moderate Rain',
  65: 'Heavy Rain',
  66: 'Freezing Light Rain',
  67: 'Freezing Heavy Rain',
  71: 'Slight Snow',
  73: 'Moderate Snow',
  75: 'Heavy Snow',
  77: 'Snow Grains',
  80: 'Slight Rain Showers',
  81: 'Moderate Rain Showers',
  82: 'Violent Rain Showers',
  85: 'Slight Snow Showers',
  86: 'Heavy Snow Showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with Slight Hail',
  99: 'Thunderstorm with Heavy Hail',
};

/// Open-Meteo weather code categories for generating running-specific warnings.
enum _WmoCategory {
  clear,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunderstorm,
}

_WmoCategory _categorizeCode(int code) {
  if (code == 0 || code == 1) return _WmoCategory.clear;
  if (code <= 3) return _WmoCategory.cloudy;
  if (code == 45 || code == 48) return _WmoCategory.fog;
  if (code <= 57) return _WmoCategory.drizzle;
  if (code <= 67) return _WmoCategory.rain;
  if (code <= 77) return _WmoCategory.snow;
  if (code <= 86) return _WmoCategory.rain; // showers as rain
  return _WmoCategory.thunderstorm;
}

class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetches real current-conditions weather from Open-Meteo.
  ///
  /// Returns a [WeatherInfo] for the given lat/lng.
  /// Uses Fahrenheit for US-based users.
  Future<WeatherInfo> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max',
      'temperature_unit': 'fahrenheit',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather API failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseResponse(data);
  }

  WeatherInfo _parseResponse(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;

    // --- Current conditions ---
    final temp = (current?['temperature_2m'] as num?)?.toDouble() ?? 72.0;
    final weatherCode = (current?['weather_code'] as num?)?.toInt() ?? 0;
    final precipitation = (current?['precipitation'] as num?)?.toDouble() ?? 0.0;
    final humidity = (current?['relative_humidity_2m'] as num?)?.toInt() ?? 50;

    // --- Daily forecast ---
    final sunriseRaw = (daily?['sunrise'] as List?)?.firstOrNull as String?;
    final sunsetRaw = (daily?['sunset'] as List?)?.firstOrNull as String?;
    final precipProbMax = (daily?['precipitation_probability_max'] as List?)?.firstOrNull as int?;

    // Format sunrise/sunset to HH:MM
    final sunrise = _formatTime(sunriseRaw);
    final sunset = _formatTime(sunsetRaw);

    // Precipitation as display string
    final precipChance = precipProbMax != null ? '$precipProbMax%' : (precipitation > 0 ? '${precipitation.toStringAsFixed(1)}"' : '0%');

    // Human-readable condition
    final condition = _wmoConditions[weatherCode] ?? 'Unknown';
    final category = _categorizeCode(weatherCode);

    // Comfortable check (Ideal: 5°C - 20°C / 40°F - 68°F)
    final isComfortable = temp >= 40 && temp <= 68 && category != _WmoCategory.rain &&
        category != _WmoCategory.thunderstorm && category != _WmoCategory.snow;

    // Build warnings
    final warnings = <String>[];
    if (temp > 85) {
      warnings.add('Heat warning: ${temp.toStringAsFixed(0)}°F — consider running early or late');
    } else if (temp < 32) {
      warnings.add('Freezing temps: ${temp.toStringAsFixed(0)}°F — icy conditions possible');
    } else if (temp > 68) {
      warnings.add('Warm: ${temp.toStringAsFixed(0)}°F — stay hydrated');
    } else if (temp < 40) {
      warnings.add('Cold: ${temp.toStringAsFixed(0)}°F — layer up');
    }

    if (category == _WmoCategory.rain || category == _WmoCategory.thunderstorm) {
      warnings.add('Rain expected — roads may be slippery');
    } else if (category == _WmoCategory.snow) {
      warnings.add('Snow — traction may be compromised');
    } else if (category == _WmoCategory.fog) {
      warnings.add('Fog — reduced visibility, wear bright colors');
    }

    return WeatherInfo(
      temperature: '${temp.toStringAsFixed(0)}°F',
      condition: condition,
      precipitationChance: precipChance,
      humidity: '$humidity%',
      windSpeed: '--', // Open-Meteo offers it but let's keep minimal
      sunrise: sunrise,
      sunset: sunset,
      isComfortable: isComfortable,
      warnings: warnings,
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    // ISO format: 2026-07-11T06:32:00
    try {
      final parts = iso.split('T');
      if (parts.length < 2) return '--:--';
      final timePart = parts[1];
      return timePart.substring(0, 5); // "06:32"
    } catch (_) {
      return '--:--';
    }
  }
}
