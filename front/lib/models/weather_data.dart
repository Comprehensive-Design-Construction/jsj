// lib/models/weather_data.dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class WeatherMainInfo {
  final double? temp;
  final double? feelsLike;
  final double? tempMin;
  final double? tempMax;
  final double? pressure;
  final double? humidity;
  final double? windSpeed;
  final int? windDeg;

  const WeatherMainInfo({
    this.temp,
    this.feelsLike,
    this.tempMin,
    this.tempMax,
    this.pressure,
    this.humidity,
    this.windSpeed,
    this.windDeg,
  });

  factory WeatherMainInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeatherMainInfo(); // Null 처리
    return WeatherMainInfo(
      // double.tryParse 등으로 안전하게 변환 고려
      temp: (json['temp'] as num?)?.toDouble(),
      feelsLike: (json['feels_like'] as num?)?.toDouble(),
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      tempMax: (json['temp_max'] as num?)?.toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      windDeg: json['wind_deg'] as int?,
    );
  }
}

@immutable
class WeatherCondition {
  final String? main;
  final String? description;
  final String? icon;

  const WeatherCondition({this.main, this.description, this.icon});

  factory WeatherCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeatherCondition();
    return WeatherCondition(
      main: json['main'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

@immutable
class WeatherDetailResponse {
  final Map<String, double>?
  requestLocation; // {'latitude': float, 'longitude': float}
  final WeatherCondition weatherCondition;
  final WeatherMainInfo measurements;
  final int? timestamp;
  final int? timezone;
  final String? error;

  const WeatherDetailResponse({
    this.requestLocation,
    required this.weatherCondition,
    required this.measurements,
    this.timestamp,
    this.timezone,
    this.error,
  });

  factory WeatherDetailResponse.fromJson(Map<String, dynamic> json) {
    return WeatherDetailResponse(
      requestLocation:
          (json['request_location'] as Map?)?.cast<String, double>(),
      weatherCondition: WeatherCondition.fromJson(
        json['weather_condition'] as Map<String, dynamic>?,
      ),
      measurements: WeatherMainInfo.fromJson(
        json['measurements'] as Map<String, dynamic>?,
      ),
      timestamp: json['timestamp'] as int?,
      timezone: json['timezone'] as int?,
      error: json['error'] as String?,
    );
  }
}
