import 'common_models.dart'; // RegionInfo 사용

/// 건강 지수 계산 결과 상세 (IndexCalculationResult)
class IndexCalculationResult {
  final double? apparentTemperature; // 체감 온도 값
  final String? apparentTempRiskStatus; // 체감 온도 위험도 상태 (문자열)
  final double? aliScore; // 천식/폐질환 지수 점수
  final int? aliLevel; // 천식/폐질환 지수 등급 (1~4)
  final double? strokeIndexScore; // 뇌졸증 지수 점수 (response_models.py 오타 수정)
  final int? strokeIndexLevel; // 뇌졸증 지수 등급 (1~4) (response_models.py 오타 수정)
  final double? coldIndexScore; // 감기 지수 점수
  final int? coldIndexLevel; // 감기 지수 등급 (1~4)
  final String? foodPoisoningIndex; // 식중독 지수 (문자열 값, 예: '53.6')
  final String? foodPoisoningRisk; // 식중독 위험도 (문자열, 예: '관심')
  final String? foodPoisoningError; // 식중독 정보 조회 오류 메시지

  IndexCalculationResult({
    this.apparentTemperature,
    this.apparentTempRiskStatus,
    this.aliScore,
    this.aliLevel,
    this.strokeIndexScore,
    this.strokeIndexLevel,
    this.coldIndexScore,
    this.coldIndexLevel,
    this.foodPoisoningIndex,
    this.foodPoisoningRisk,
    this.foodPoisoningError,
  });

  factory IndexCalculationResult.fromJson(Map<String, dynamic> json) {
    return IndexCalculationResult(
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(),
      apparentTempRiskStatus: json['apparent_temp_risk_status'] as String?,
      aliScore: (json['ali_score'] as num?)?.toDouble(),
      aliLevel: json['ali_level'] as int?,
      strokeIndexScore: (json['stroke_index_score'] as num?)?.toDouble(),
      strokeIndexLevel: json['stroke_index_level'] as int?,
      coldIndexScore: (json['cold_index_score'] as num?)?.toDouble(),
      coldIndexLevel: json['cold_index_level'] as int?,
      foodPoisoningIndex: json['food_poisoning_index'] as String?,
      foodPoisoningRisk: json['food_poisoning_risk'] as String?,
      foodPoisoningError: json['food_poisoning_error'] as String?,
    );
  }
}

/// 건강 지수 API 최종 응답 모델 (/api/index)
class HealthIndexResponse {
  // 요청 파라미터 정보 (다양한 타입을 포함할 수 있으므로 Map<String, dynamic> 유지)
  final Map<String, dynamic> request;
  final RegionInfo region; // 지역 정보
  final IndexCalculationResult indices; // 계산된 지수 결과
  final List<String>? errors; // 처리 중 발생한 오류 목록

  HealthIndexResponse({
    required this.request,
    required this.region,
    required this.indices,
    this.errors,
  });

  factory HealthIndexResponse.fromJson(Map<String, dynamic> json) {
    return HealthIndexResponse(
      request: json['request'] as Map<String, dynamic>, // 그대로 받음
      region: RegionInfo.fromJson(json['region']),
      indices: IndexCalculationResult.fromJson(json['indices']),
      // 리스트 파싱 (List<dynamic> -> List<String>)
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}
