// lib/models/response/env_map_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/request_info.dart';

part 'env_map_response.freezed.dart';
part 'env_map_response.g.dart';

@freezed
class EnvMapResponse with _$EnvMapResponse {
  const factory EnvMapResponse({
    @JsonKey(name: 'request_info') required RequestInfo requestInfo,

    @JsonKey(name: 'env_map_html') String? envMapHtml,
    @JsonKey(name: 'env_type') required String envType,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'error') String? error,
  }) = _EnvMapResponse;

  factory EnvMapResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvMapResponseFromJson(json);
}
