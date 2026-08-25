/// How much precipitation the user tolerates.
enum PrecipitationTolerance {
  noRain,
  lightRainOk,
  any,
}

/// Time-of-day window for running.
enum TimeWindow {
  anytime,
  afterSunset,
  beforeSunrise,
  bothTwilights,
}

String precipitationToleranceToString(PrecipitationTolerance t) =>
    t.toString().split('.').last;
String timeWindowToString(TimeWindow w) =>
    w.toString().split('.').last;

PrecipitationTolerance parsePrecipitationTolerance(String s) =>
    PrecipitationTolerance.values.firstWhere(
      (e) => precipitationToleranceToString(e) == s,
      orElse: () => PrecipitationTolerance.noRain,
    );
TimeWindow parseTimeWindow(String s) =>
    TimeWindow.values.firstWhere(
      (e) => timeWindowToString(e) == s,
      orElse: () => TimeWindow.anytime,
    );

/// User-configurable ideal running conditions.
///
/// Defaults: 67°F – 73°F, no rain, no wind cap, [anytime].
class WeatherThreshold {
  final double minTempF;
  final double maxTempF;
  final PrecipitationTolerance precipitation;
  final TimeWindow timeWindow;
  final double? maxWindMph; // null = no cap

  const WeatherThreshold({
    this.minTempF = 67,
    this.maxTempF = 73,
    this.precipitation = PrecipitationTolerance.noRain,
    this.timeWindow = TimeWindow.anytime,
    this.maxWindMph,
  });

  Map<String, dynamic> toJson() => {
        'minTempF': minTempF,
        'maxTempF': maxTempF,
        'precipitation': precipitationToleranceToString(precipitation),
        'timeWindow': timeWindowToString(timeWindow),
        if (maxWindMph != null) 'maxWindMph': maxWindMph,
      };

  factory WeatherThreshold.fromJson(Map<String, dynamic> json) =>
      WeatherThreshold(
        minTempF: (json['minTempF'] as num?)?.toDouble() ?? 67,
        maxTempF: (json['maxTempF'] as num?)?.toDouble() ?? 73,
        precipitation: json['precipitation'] != null
            ? parsePrecipitationTolerance(json['precipitation'])
            : PrecipitationTolerance.noRain,
        timeWindow: json['timeWindow'] != null
            ? parseTimeWindow(json['timeWindow'])
            : TimeWindow.anytime,
        maxWindMph: (json['maxWindMph'] as num?)?.toDouble(),
      );

  WeatherThreshold copyWith({
    double? minTempF,
    double? maxTempF,
    PrecipitationTolerance? precipitation,
    TimeWindow? timeWindow,
    double? maxWindMph,
    bool clearWindCap = false,
  }) =>
      WeatherThreshold(
        minTempF: minTempF ?? this.minTempF,
        maxTempF: maxTempF ?? this.maxTempF,
        precipitation: precipitation ?? this.precipitation,
        timeWindow: timeWindow ?? this.timeWindow,
        maxWindMph: clearWindCap ? null : (maxWindMph ?? this.maxWindMph),
      );

  @override
  bool operator ==(Object other) =>
      other is WeatherThreshold &&
      minTempF == other.minTempF &&
      maxTempF == other.maxTempF &&
      precipitation == other.precipitation &&
      timeWindow == other.timeWindow &&
      maxWindMph == other.maxWindMph;

  @override
  int get hashCode => Object.hash(minTempF, maxTempF, precipitation, timeWindow,
      maxWindMph);
}
