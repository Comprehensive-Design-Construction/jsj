// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserInputImpl _$$UserInputImplFromJson(Map<String, dynamic> json) =>
    _$UserInputImpl(
      age: (json['age'] as num?)?.toInt(),
      disease:
          (json['disease'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserInputImplToJson(_$UserInputImpl instance) =>
    <String, dynamic>{'age': instance.age, 'disease': instance.disease};
