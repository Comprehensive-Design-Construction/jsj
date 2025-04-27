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
      envMapHtml: json['env_map_html'] as String?,
      envType: json['env_type'] as String,
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$EnvMapResponseImplToJson(
  _$EnvMapResponseImpl instance,
) => <String, dynamic>{
  'request_info': instance.requestInfo,
  'env_map_html': instance.envMapHtml,
  'env_type': instance.envType,
  'last_updated': instance.lastUpdated,
  'error': instance.error,
};
