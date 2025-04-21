// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indexing_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IndexingDataImpl _$$IndexingDataImplFromJson(Map<String, dynamic> json) =>
    _$IndexingDataImpl(
      apparentTemperature: parseDouble(json['apparent_temperature']),
      apparentTempRiskStatus: json['risk_status'] as String?,
      aliScore: parseDouble(json['aliScore']),
      aliLevel: parseInt(json['aliLevel']),
      strokeIndexScore: parseDouble(json['strokeIndexScore']),
      strokeIndexLevel: parseInt(json['strokeIndexLevel']),
      coldIndexScore: parseDouble(json['coldIndexScore']),
      coldIndexLevel: parseInt(json['coldIndexLevel']),
      foodPoisoningIndex: parseDouble(json['food_poisoning_index']),
      foodPoisoningRisk: json['foodPoisoningRisk'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$IndexingDataImplToJson(_$IndexingDataImpl instance) =>
    <String, dynamic>{
      'apparent_temperature': instance.apparentTemperature,
      'risk_status': instance.apparentTempRiskStatus,
      'aliScore': instance.aliScore,
      'aliLevel': instance.aliLevel,
      'strokeIndexScore': instance.strokeIndexScore,
      'strokeIndexLevel': instance.strokeIndexLevel,
      'coldIndexScore': instance.coldIndexScore,
      'coldIndexLevel': instance.coldIndexLevel,
      'food_poisoning_index': instance.foodPoisoningIndex,
      'foodPoisoningRisk': instance.foodPoisoningRisk,
      'error': instance.error,
    };
