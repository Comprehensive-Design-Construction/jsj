// lib/models/request/location_input.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_input.freezed.dart';
part 'location_input.g.dart';

@freezed
class LocationInput with _$LocationInput {
  const factory LocationInput({
    required double latitude,
    required double longitude,
  }) = _LocationInput;

  factory LocationInput.fromJson(Map<String, dynamic> json) =>
      _$LocationInputFromJson(json);
}
