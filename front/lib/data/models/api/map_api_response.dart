/// 대피소 지도 API 응답 모델 (/api/map)
class MapApiResponse {
  // 요청 정보 (다양한 타입을 포함할 수 있으므로 Map<String, dynamic> 유지)
  final Map<String, dynamic> requestInfo;
  final String? shelterMapHtml; // 지도 HTML 문자열
  final String? error; // 오류 메시지

  MapApiResponse({required this.requestInfo, this.shelterMapHtml, this.error});

  factory MapApiResponse.fromJson(Map<String, dynamic> json) {
    return MapApiResponse(
      requestInfo: json['request_info'] as Map<String, dynamic>,
      shelterMapHtml: json['shelter_map_html'] as String?,
      error: json['error'] as String?,
    );
  }
}
