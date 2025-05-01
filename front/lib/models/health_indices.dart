// lib/models/health_indices.dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class RegionInfo {
  final String? gu;
  final String? region; // '동'

  const RegionInfo({this.gu, this.region});

  factory RegionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegionInfo();
    return RegionInfo(
      gu: json['gu'] as String?,
      region: json['region'] as String?,
    );
  }
}

@immutable
class IndexCalculationResult {
  final double? apparentTemperature;
  final String? apparentTempRiskStatus;
  final double? aliScore;
  final int? aliLevel;
  final double? strokeIndexScore;
  final int? strokeIndexLevel;
  final double? coldIndexScore;
  final int? coldIndexLevel;
  final String? foodPoisoningIndex; // String ?
  final String? foodPoisoningRisk;
  final String? foodPoisoningError;

  const IndexCalculationResult({
    this.apparentTemperature,
    this.apparentTempRiskStatus,
    this.aliScore,
    this.aliLevel,
    this.strokeIndexScore,
    this.strokeIndexLevel,
    this.coldIndexScore,
    this.coldIndexLevel,
    this.foodPoisoningIndex,
    this.foodPoisoningRisk,
    this.foodPoisoningError,
  });

  factory IndexCalculationResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const IndexCalculationResult();
    return IndexCalculationResult(
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(),
      apparentTempRiskStatus: json['apparent_temp_risk_status'] as String?,
      aliScore: (json['ali_score'] as num?)?.toDouble(),
      aliLevel: json['ali_level'] as int?,
      strokeIndexScore: (json['stroke_index_score'] as num?)?.toDouble(),
      strokeIndexLevel: json['stroke_index_level'] as int?,
      coldIndexScore: (json['cold_index_score'] as num?)?.toDouble(),
      coldIndexLevel: json['cold_index_level'] as int?,
      foodPoisoningIndex:
          json['food_poisoning_index']?.toString(), // 타입 확인 후 조정
      foodPoisoningRisk: json['food_poisoning_risk'] as String?,
      foodPoisoningError: json['food_poisoning_error'] as String?,
    );
  }
}

@immutable
class HealthIndexResponse {
  final Map<String, dynamic>? request;
  final RegionInfo region;
  final IndexCalculationResult indices;
  final List<String>? errors;

  const HealthIndexResponse({
    this.request,
    required this.region,
    required this.indices,
    this.errors,
  });

  factory HealthIndexResponse.fromJson(Map<String, dynamic> json) {
    return HealthIndexResponse(
      request: json['request'] as Map<String, dynamic>?,
      region: RegionInfo.fromJson(json['region'] as Map<String, dynamic>?),
      indices: IndexCalculationResult.fromJson(
        json['indices'] as Map<String, dynamic>?,
      ),
      errors:
          (json['errors'] as List?)
              ?.map((e) => e.toString())
              .toList(), // 안전하게 변환
    );
  }
}
