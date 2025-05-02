import 'common_models.dart'; // RegionInfo 사용

/// 자치구별 UV 지수 정보 (RegionUvData)
class RegionUvData {
  final int? uvIndex; // UV 지수 값 (h0 값)

  RegionUvData({this.uvIndex});

  factory RegionUvData.fromJson(Map<String, dynamic> json) {
    return RegionUvData(uvIndex: json['uv_index'] as int?);
  }
}

/// 지역별 UV 지수 API 응답 모델 (/api/environment/uv)
class SingleRegionUvResponse {
  final Map<String, double>? requestLocation; // 요청 좌표
  final RegionInfo? regionInfo; // 조회된 지역 정보
  final RegionUvData? uvData; // 해당 지역 UV 데이터
  final String? lastUpdated; // 데이터 최종 업데이트 시간
  final String? error; // 오류 메시지

  SingleRegionUvResponse({
    this.requestLocation,
    this.regionInfo,
    this.uvData,
    this.lastUpdated,
    this.error,
  });

  factory SingleRegionUvResponse.fromJson(Map<String, dynamic> json) {
    return SingleRegionUvResponse(
      requestLocation: (json['request_location'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      regionInfo:
          json['region_info'] != null
              ? RegionInfo.fromJson(json['region_info'])
              : null, // null 가능성 대비
      uvData:
          json['uv_data'] != null
              ? RegionUvData.fromJson(json['uv_data'])
              : null,
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}
