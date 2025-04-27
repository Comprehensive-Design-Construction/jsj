// lib/models/response/health_indices_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/indexing_data.dart';
import '../common/region.dart';
import '../common/alert_info.dart'; // AlertInfo import
import '../common/weather_data.dart'; // WeatherData import
import '../common/request_info.dart'; // RequestInfo import (내부 request 필드용)

part 'health_indices_response.freezed.dart';
part 'health_indices_response.g.dart';

@freezed
class HealthIndicesResponse with _$HealthIndicesResponse {
  const factory HealthIndicesResponse({
    // RequestInfo 모델 사용 (json['request'] 부분을 RequestInfo.fromJson으로 처리)
    @JsonKey(name: 'request') required RequestInfo requestInfo,
    required Region region,
    required IndexingData indices,
    // WeatherData와 alerts 추가 (API 스키마 기반)
    WeatherData? weather, // Optional
    @Default([]) List<AlertInfo> alerts, // Default to empty list
    String? error, // Top-level error
  }) = _HealthIndicesResponse;

  factory HealthIndicesResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthIndicesResponseFromJson(json);
}
