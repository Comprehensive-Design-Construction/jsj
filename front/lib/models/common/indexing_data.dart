// lib/models/common/indexing_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_helpers.dart'; // Helper 함수 import

part 'indexing_data.freezed.dart';
part 'indexing_data.g.dart';

@freezed
class IndexingData with _$IndexingData {
  factory IndexingData({
    @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
    double? apparentTemperature,
    @JsonKey(name: 'risk_status') String? apparentTempRiskStatus,
    @JsonKey(name: 'ali_score', fromJson: parseDouble) double? aliScore,
    @JsonKey(name: 'ali_level', fromJson: parseInt) int? aliLevel,

    @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
    double? strokeIndexScore,
    @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
    int? strokeIndexLevel,

    @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
    double? coldIndexScore,
    @JsonKey(name: 'cold_index_level', fromJson: parseInt) int? coldIndexLevel,

    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    double? foodPoisoningIndex,
    @JsonKey(name: 'food_poisoning_risk') String? foodPoisoningRisk,
    String? error,
  }) = _IndexingData;

  factory IndexingData.fromJson(Map<String, dynamic> json) =>
      _$IndexingDataFromJson(json);
}
