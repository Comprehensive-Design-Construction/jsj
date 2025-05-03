import 'package:flutter/material.dart';

class CurrentWeather {
  final String location;
  final String description;
  final String recommendation;
  // final String weatherIconAsset; // IconData 사용으로 주석 처리 또는 삭제
  final IconData weatherIcon;
  final Color weatherIconColor;
  final double? currentTemp; // <<< double? 로 변경 (API는 실수형)
  final double? maxTemp; // <<< double? 로 변경
  final double? minTemp; // <<< double? 로 변경
  final String avatarImageAsset;

  CurrentWeather({
    required this.location,
    required this.description,
    required this.recommendation,
    // required this.weatherIconAsset,
    required this.weatherIcon,
    required this.weatherIconColor,
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    required this.avatarImageAsset,
  });
}
