// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RequestInfoImpl _$$RequestInfoImplFromJson(Map<String, dynamic> json) =>
    _$RequestInfoImpl(
      reqLatitude: parseDouble(json['latitude']),
      reqLongitude: parseDouble(json['longitude']),
      reqAge: parseInt(json['age']),
      reqDisease:
          (json['disease'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requestLocation:
          json['requestLocation'] == null
              ? null
              : LocationInput.fromJson(
                json['requestLocation'] as Map<String, dynamic>,
              ),
      userInput:
          json['userInput'] == null
              ? null
              : UserInput.fromJson(json['userInput'] as Map<String, dynamic>),
      disasterType: json['disasterType'] as String?,
      envType: json['envType'] as String?,
      radiusKm: parseDouble(json['radiusKm']),
      forceRefresh: json['forceRefresh'] as bool?,
    );

Map<String, dynamic> _$$RequestInfoImplToJson(_$RequestInfoImpl instance) =>
    <String, dynamic>{
      'latitude': instance.reqLatitude,
      'longitude': instance.reqLongitude,
      'age': instance.reqAge,
      'disease': instance.reqDisease,
      'requestLocation': instance.requestLocation,
      'userInput': instance.userInput,
      'disasterType': instance.disasterType,
      'envType': instance.envType,
      'radiusKm': instance.radiusKm,
      'forceRefresh': instance.forceRefresh,
    };
