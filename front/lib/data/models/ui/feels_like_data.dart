import 'package:flutter/material.dart';

class FeelsLikeData {
  final double temperature;
  final String status;
  final Color statusColor;
  final String message1;
  final String message2;
  final String buttonText; // TODO: 버튼 기능 확정 후 역할 재정의 필요

  FeelsLikeData({
    required this.temperature,
    required this.status,
    required this.statusColor,
    required this.message1,
    required this.message2,
    required this.buttonText,
  });
}
