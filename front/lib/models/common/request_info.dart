// lib/models/common/request_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../request/location_input.dart';
import '../request/user_input.dart';
import 'json_helpers.dart'; // _parseDouble import

part 'request_info.freezed.dart';
part 'request_info.g.dart';

@freezed
class RequestInfo with _$RequestInfo {
  const factory RequestInfo({
    // 키 이름은 API 응답에 따라 다를 수 있으므로 주의!
    // health index API 응답 기준
    @JsonKey(name: 'latitude', fromJson: parseDouble) double? reqLatitude,
    @JsonKey(name: 'longitude', fromJson: parseDouble) double? reqLongitude,
    @JsonKey(name: 'age', fromJson: parseInt) int? reqAge,
    @JsonKey(name: 'disease') @Default([]) List<String> reqDisease,

    // map API 응답 기준
    LocationInput? requestLocation,
    UserInput? userInput,
    String? disasterType,
    String? envType, // env_map 응답에서도 사용됨
    @JsonKey(fromJson: parseDouble) double? radiusKm,
    bool? forceRefresh, // env_map 응답에서 사용됨
  }) = _RequestInfo;

  factory RequestInfo.fromJson(Map<String, dynamic> json) =>
      _$RequestInfoFromJson(json);
}
