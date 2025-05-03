/// 지역 정보 (API 응답 내 공통 사용)
class RegionInfo {
  final String? gu; // 구
  final String? region; // 동

  RegionInfo({this.gu, this.region});

  // JSON 데이터를 RegionInfo 객체로 변환하는 팩토리 생성자
  factory RegionInfo.fromJson(Map<String, dynamic> json) {
    // JSON의 'gu', 'region' 키 값을 읽어와 객체 생성
    return RegionInfo(
      gu: json['gu'] as String?, // null일 수 있으므로 as String? 사용
      region: json['region'] as String?,
    );
  }

  // 객체를 JSON으로 변환하는 메소드 (필요시 사용)
  Map<String, dynamic> toJson() => {'gu': gu, 'region': region};
}

// 다른 공통 모델이 있다면 여기에 추가 (예: API 요청 파라미터 모델 등)
