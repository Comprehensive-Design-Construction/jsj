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
    @JsonKey(
      name: 'risk_status',
    ) // Note: This key was from the example response top level
    String?
    apparentTempRiskStatus, // Schema description: apparent_temp_risk_status
    @JsonKey(fromJson: parseDouble) double? aliScore,
    @JsonKey(fromJson: parseInt) int? aliLevel,
    @JsonKey(fromJson: parseDouble) double? strokeIndexScore,
    @JsonKey(fromJson: parseInt) int? strokeIndexLevel,
    @JsonKey(fromJson: parseDouble) double? coldIndexScore,
    @JsonKey(fromJson: parseInt) int? coldIndexLevel,
    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    double? foodPoisoningIndex,
    String? foodPoisoningRisk,
    String? error,
  }) = _IndexingData;

  factory IndexingData.fromJson(Map<String, dynamic> json) =>
      _$IndexingDataFromJson(json);
}
