// lib/data/models/ui/hourly_weather_ui.dart
import 'package:flutter/material.dart';

class HourlyWeatherUI {
  final String time;
  // final String statusText; // <<< 추가: "맑음", "흐림" 등
  final IconData weatherIcon;
  final Color weatherIconColor;
  final String temperature;
  final String? precipitationProbability;

  HourlyWeatherUI({
    required this.time,
    // required this.statusText, // <<< 추가
    required this.weatherIcon,
    required this.weatherIconColor,
    required this.temperature,
    this.precipitationProbability,
  });
}
