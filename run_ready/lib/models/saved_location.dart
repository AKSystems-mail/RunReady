import '../models/weather_threshold.dart';

/// A location the user wants to monitor for ideal running conditions.
class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final WeatherThreshold threshold;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.threshold = const WeatherThreshold(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'threshold': threshold.toJson(),
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: json['id'],
        name: json['name'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        threshold: json['threshold'] != null
            ? WeatherThreshold.fromJson(json['threshold'])
            : const WeatherThreshold(),
      );

  SavedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    WeatherThreshold? threshold,
  }) =>
      SavedLocation(
        id: id ?? this.id,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        threshold: threshold ?? this.threshold,
      );
}
