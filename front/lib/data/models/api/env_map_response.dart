/// 환경 지도 API 응답 모델 (/api/env_map)
class EnvMapApiResponse {
  // 요청 정보
  final Map<String, dynamic> requestInfo;
  final String? envMapHtml; // 환경 지도 HTML 문자열
  final String envType; // 환경 유형 (예: 'fine_dust', 'uv')
  final String? lastUpdated; // 데이터 최종 업데이트 시간 (ISO 형식 문자열)
  final String? error; // 오류 메시지

  EnvMapApiResponse({
    required this.requestInfo,
    this.envMapHtml,
    required this.envType,
    this.lastUpdated,
    this.error,
  });

  factory EnvMapApiResponse.fromJson(Map<String, dynamic> json) {
    return EnvMapApiResponse(
      requestInfo: json['request_info'] as Map<String, dynamic>,
      envMapHtml: json['env_map_html'] as String?,
      envType: json['env_type'] as String, // 필수 값이므로 non-nullable
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}
