// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelter_map_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShelterMapResponseImpl _$$ShelterMapResponseImplFromJson(
  Map<String, dynamic> json,
) => _$ShelterMapResponseImpl(
  requestInfo: RequestInfo.fromJson(
    json['request_info'] as Map<String, dynamic>,
  ),
  shelterMapHtml: json['shelterMapHtml'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$ShelterMapResponseImplToJson(
  _$ShelterMapResponseImpl instance,
) => <String, dynamic>{
  'request_info': instance.requestInfo,
  'shelterMapHtml': instance.shelterMapHtml,
  'error': instance.error,
};
