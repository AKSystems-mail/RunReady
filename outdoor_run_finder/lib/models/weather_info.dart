class WeatherInfo {
  final String temperature;
  final String condition;
  final String precipitationChance;
  final String sunrise;
  final String sunset;
  final bool isComfortable;
  final List<String> warnings;

  WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.precipitationChance,
    required this.sunrise,
    required this.sunset,
    required this.isComfortable,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'condition': condition,
    'precipitationChance': precipitationChance,
    'sunrise': sunrise,
    'sunset': sunset,
    'isComfortable': isComfortable,
    'warnings': warnings,
  };

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
    temperature: json['temperature'],
    condition: json['condition'],
    precipitationChance: json['precipitationChance'],
    sunrise: json['sunrise'],
    sunset: json['sunset'],
    isComfortable: json['isComfortable'],
    warnings: List<String>.from(json['warnings']),
  );
}
