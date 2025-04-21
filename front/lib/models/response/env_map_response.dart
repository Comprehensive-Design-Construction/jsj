// lib/models/response/env_map_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/request_info.dart';

part 'env_map_response.freezed.dart';
part 'env_map_response.g.dart';

@freezed
class EnvMapResponse with _$EnvMapResponse {
  const factory EnvMapResponse({
    @JsonKey(name: 'request_info') required RequestInfo requestInfo,
    String? envMapHtml, // 지도 HTML (nullable)
    required String envType, // 'fine_dust' or 'uv'
    String? lastUpdated, // ISO 8601 format DateTime string
    String? error,
  }) = _EnvMapResponse;

  factory EnvMapResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvMapResponseFromJson(json);
}
