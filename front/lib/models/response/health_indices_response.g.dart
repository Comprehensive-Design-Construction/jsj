// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_indices_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HealthIndicesResponseImpl _$$HealthIndicesResponseImplFromJson(
  Map<String, dynamic> json,
) => _$HealthIndicesResponseImpl(
  requestInfo: RequestInfo.fromJson(json['request'] as Map<String, dynamic>),
  region: Region.fromJson(json['region'] as Map<String, dynamic>),
  indices: IndexingData.fromJson(json['indices'] as Map<String, dynamic>),
  weather:
      json['weather'] == null
          ? null
          : WeatherData.fromJson(json['weather'] as Map<String, dynamic>),
  alerts:
      (json['alerts'] as List<dynamic>?)
          ?.map((e) => AlertInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  error: json['error'] as String?,
);

Map<String, dynamic> _$$HealthIndicesResponseImplToJson(
  _$HealthIndicesResponseImpl instance,
) => <String, dynamic>{
  'request': instance.requestInfo,
  'region': instance.region,
  'indices': instance.indices,
  'weather': instance.weather,
  'alerts': instance.alerts,
  'error': instance.error,
};
