// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_map_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnvMapResponseImpl _$$EnvMapResponseImplFromJson(Map<String, dynamic> json) =>
    _$EnvMapResponseImpl(
      requestInfo: RequestInfo.fromJson(
        json['request_info'] as Map<String, dynamic>,
      ),
      envMapHtml: json['envMapHtml'] as String?,
      envType: json['envType'] as String,
      lastUpdated: json['lastUpdated'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$EnvMapResponseImplToJson(
  _$EnvMapResponseImpl instance,
) => <String, dynamic>{
  'request_info': instance.requestInfo,
  'envMapHtml': instance.envMapHtml,
  'envType': instance.envType,
  'lastUpdated': instance.lastUpdated,
  'error': instance.error,
};
