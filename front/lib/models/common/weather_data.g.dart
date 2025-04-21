// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeatherDataImpl _$$WeatherDataImplFromJson(Map<String, dynamic> json) =>
    _$WeatherDataImpl(
      temperature: parseDouble(json['temperature']),
      pressure: parseDouble(json['pressure']),
      humidity: parseDouble(json['humidity']),
      windSpeed: parseDouble(json['windSpeed']),
      tempMin: parseDouble(json['tempMin']),
      tempMax: parseDouble(json['tempMax']),
      description: json['description'] as String?,
      mainCondition: json['mainCondition'] as String?,
      icon: json['icon'] as String?,
      city: json['city'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$WeatherDataImplToJson(_$WeatherDataImpl instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'pressure': instance.pressure,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'tempMin': instance.tempMin,
      'tempMax': instance.tempMax,
      'description': instance.description,
      'mainCondition': instance.mainCondition,
      'icon': instance.icon,
      'city': instance.city,
      'error': instance.error,
    };
