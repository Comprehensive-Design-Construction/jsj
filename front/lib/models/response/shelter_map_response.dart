// lib/models/response/shelter_map_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/request_info.dart';

part 'shelter_map_response.freezed.dart';
part 'shelter_map_response.g.dart';

@freezed
class ShelterMapResponse with _$ShelterMapResponse {
  const factory ShelterMapResponse({
    @JsonKey(name: 'request_info') required RequestInfo requestInfo,
    @JsonKey(name: 'shelter_map_html')
    String? shelterMapHtml, // 지도 HTML (nullable)
    @JsonKey(name: 'error') String? error,
  }) = _ShelterMapResponse;

  factory ShelterMapResponse.fromJson(Map<String, dynamic> json) =>
      _$ShelterMapResponseFromJson(json);
}
