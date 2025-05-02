import 'common_models.dart'; // RegionInfo 사용

/// 자치구별 미세먼지 상세 정보 (RegionFineDustData)
class RegionFineDustData {
  final String? grade; // 등급 (예: "좋음") - 원본 키 'GRADE'
  final int? pm10; // PM10 농도
  final int? pm25; // PM2.5 농도
  final String? maxIndex; // 통합대기환경지수 등급 (문자열) - 원본 키 'MAXINDEX'

  RegionFineDustData({this.grade, this.pm10, this.pm25, this.maxIndex});

  factory RegionFineDustData.fromJson(Map<String, dynamic> json) {
    return RegionFineDustData(
      grade: json['GRADE'] as String?,
      pm10: json['PM10'] as int?,
      pm25: json['PM25'] as int?,
      maxIndex: json['MAXINDEX'] as String?,
    );
  }
}

/// 지역별 미세먼지 API 응답 모델 (/api/environment/fine_dust)
class SingleRegionFineDustResponse {
  final Map<String, double>? requestLocation; // 요청 좌표
  final RegionInfo? regionInfo; // 조회된 지역 정보 (null 가능성 고려?)
  final RegionFineDustData? fineDustData; // 해당 지역 미세먼지 데이터
  final String? lastUpdated; // 데이터 최종 업데이트 시간
  final String? error; // 오류 메시지

  SingleRegionFineDustResponse({
    this.requestLocation,
    this.regionInfo,
    this.fineDustData,
    this.lastUpdated,
    this.error,
  });

  factory SingleRegionFineDustResponse.fromJson(Map<String, dynamic> json) {
    return SingleRegionFineDustResponse(
      requestLocation: (json['request_location'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      // Pydantic 모델에서 RegionInfo가 필수였으므로, null 체크 제거 또는 확인 필요
      regionInfo:
          json['region_info'] != null
              ? RegionInfo.fromJson(json['region_info'])
              : null, // API 응답이 null일 가능성 대비
      fineDustData:
          json['fine_dust_data'] != null
              ? RegionFineDustData.fromJson(json['fine_dust_data'])
              : null,
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}
