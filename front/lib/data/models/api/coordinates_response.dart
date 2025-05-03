// lib/data/models/api/coordinates_response.dart
import 'dart:convert';

class CoordinatesResponse {
  final double latitude;
  final double longitude;

  CoordinatesResponse({required this.latitude, required this.longitude});

  factory CoordinatesResponse.fromJson(Map<String, dynamic> json) {
    return CoordinatesResponse(
      latitude: (json['latitude'] as num).toDouble(), // 필수 값이므로 null 체크 제거
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
