import 'weather_threshold.dart';

/// Result of checking live weather against a [WeatherThreshold].
class WeatherEvaluation {
  /// Human-readable summary (e.g. "68°F, clear skies").
  final String summary;

  /// Current temperature in °F.
  final double tempF;

  /// Current precipitation in mm (0 if none).
  final double precipitationMm;

  /// WMO weather interpretation code.
  /// 0=clear, 1-3=cloudy, 45/48=fog, 51-67=drizzle/rain, 80-82=showers...
  final int weatherCode;

  /// Current wind speed in mph.
  final double windMph;

  /// Today's sunrise time as ISO string.
  final String sunrise;

  /// Today's sunset time as ISO string.
  final String sunset;

  /// Overall verdict.
  final bool isIdeal;

  /// Message explaining why not ideal (null when ideal).
  final String? reason;

  /// True if temperature alone exceeds [WeatherThreshold.maxTempF].
  final bool isTooHot;

  /// True if precipitation exceeds tolerance.
  final bool isTooWet;

  /// True if current time is outside the configured window.
  final bool isWrongTime;

  /// True if wind exceeds cap.
  final bool isTooWindy;

  /// Current local time as ISO string (used for time-window checks).
  final String currentTime;

  const WeatherEvaluation({
    required this.summary,
    required this.tempF,
    required this.precipitationMm,
    required this.weatherCode,
    required this.windMph,
    required this.sunrise,
    required this.sunset,
    required this.isIdeal,
    this.reason,
    this.isTooHot = false,
    this.isTooWet = false,
    this.isWrongTime = false,
    this.isTooWindy = false,
    required this.currentTime,
  });

  /// Short notification-ready string.
  String get notificationBody {
    if (isIdeal) return "Good to run — $summary ✅";
    final parts = <String>[];
    if (isTooHot) parts.add("too hot (${tempF.toStringAsFixed(0)}°F)");
    if (isTooWet) parts.add("rain expected");
    if (isTooWindy) parts.add("windy (${windMph.toStringAsFixed(0)} mph)");
    if (isWrongTime) parts.add("outside your time window");
    return parts.isNotEmpty
        ? "Not ideal — ${parts.join(", ")}"
        : "Check conditions — $summary";
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'tempF': tempF,
        'precipitationMm': precipitationMm,
        'weatherCode': weatherCode,
        'windMph': windMph,
        'sunrise': sunrise,
        'sunset': sunset,
        'isIdeal': isIdeal,
        'reason': reason,
        'isTooHot': isTooHot,
        'isTooWet': isTooWet,
        'isWrongTime': isWrongTime,
        'isTooWindy': isTooWindy,
        'currentTime': currentTime,
      };

  factory WeatherEvaluation.fromJson(Map<String, dynamic> json) =>
      WeatherEvaluation(
        summary: json['summary'],
        tempF: (json['tempF'] as num).toDouble(),
        precipitationMm: (json['precipitationMm'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        windMph: (json['windMph'] as num).toDouble(),
        sunrise: json['sunrise'],
        sunset: json['sunset'],
        isIdeal: json['isIdeal'] as bool,
        reason: json['reason'] as String?,
        isTooHot: json['isTooHot'] as bool? ?? false,
        isTooWet: json['isTooWet'] as bool? ?? false,
        isWrongTime: json['isWrongTime'] as bool? ?? false,
        isTooWindy: json['isTooWindy'] as bool? ?? false,
        currentTime: json['currentTime'],
      );
}
