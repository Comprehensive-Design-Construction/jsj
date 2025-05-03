import 'package:flutter/material.dart';

class HealthIndex {
  final String name;
  final String status;
  final double value; // API의 score 또는 level 값
  final IconData icon;
  final Color iconColor; // 아이콘 배경색 또는 아이콘 자체 색 (현재는 배경색 기준)
  final Color statusColor; // 상태 텍스트/태그 색상

  HealthIndex({
    required this.name,
    required this.status,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.statusColor,
  });
}
