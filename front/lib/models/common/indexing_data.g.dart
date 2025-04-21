// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indexing_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IndexingDataImpl _$$IndexingDataImplFromJson(Map<String, dynamic> json) =>
    _$IndexingDataImpl(
      apparentTemperature: parseDouble(json['apparent_temperature']),
      apparentTempRiskStatus: json['risk_status'] as String?,
      aliScore: parseDouble(json['ali_score']),
      aliLevel: parseInt(json['ali_level']),
      strokeIndexScore: parseDouble(json['stroke_index_score']),
      strokeIndexLevel: parseInt(json['stroke_index_level']),
      coldIndexScore: parseDouble(json['cold_index_score']),
      coldIndexLevel: parseInt(json['cold_index_level']),
      foodPoisoningIndex: parseDouble(json['food_poisoning_index']),
      foodPoisoningRisk: json['food_poisoning_risk'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$IndexingDataImplToJson(_$IndexingDataImpl instance) =>
    <String, dynamic>{
      'apparent_temperature': instance.apparentTemperature,
      'risk_status': instance.apparentTempRiskStatus,
      'ali_score': instance.aliScore,
      'ali_level': instance.aliLevel,
      'stroke_index_score': instance.strokeIndexScore,
      'stroke_index_level': instance.strokeIndexLevel,
      'cold_index_score': instance.coldIndexScore,
      'cold_index_level': instance.coldIndexLevel,
      'food_poisoning_index': instance.foodPoisoningIndex,
      'food_poisoning_risk': instance.foodPoisoningRisk,
      'error': instance.error,
    };
