import 'package:flutter/foundation.dart' show immutable;

@immutable
class MapApiResponse {
  final Map<String, dynamic>? requestInfo;
  final String shelterMapHtml;
  final String? error;

  const MapApiResponse({
    this.requestInfo,
    required this.shelterMapHtml,
    this.error,
  });

  factory MapApiResponse.fromJson(Map<String, dynamic> json) {
    return MapApiResponse(
      requestInfo: json['request_info'] as Map<String, dynamic>?,
      shelterMapHtml: json['shelter_map_html'] as String,
      error: json['error'] as String?,
    );
  }
}

@immutable
class EnvMapApiResponse {
  final Map<String, dynamic>? requestInfo;
  final String envMapHtml;
  final String envType;
  final String? lastUpdated;
  final String? error;

  const EnvMapApiResponse({
    this.requestInfo,
    required this.envMapHtml,
    required this.envType,
    this.lastUpdated,
    this.error,
  });

  factory EnvMapApiResponse.fromJson(Map<String, dynamic> json) {
    return EnvMapApiResponse(
      requestInfo: json['request_info'] as Map<String, dynamic>?,
      envMapHtml: json['env_map_html'] as String,
      envType: json['envType'] as String,
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}
