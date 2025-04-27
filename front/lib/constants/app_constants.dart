class AppConstants {
  // 위치 권한 거부 또는 실패 시 사용할 기본 위도/경도 (예: 강남역)
  static const double defaultLatitude = 37.498095;
  static const double defaultLongitude = 127.02761;

  // 대피소 검색 기본 반경 (km)
  static const double defaultRadiusKm = 2.0;

  // 사용 가능한 질병 목록 (Profile 화면에서 사용)
  static const List<String> availableDiseases = [
    "천식",
    "고혈압",
    "당뇨",
    "심장질환",
    "호흡기질환",
    "기타",
  ];

  // 사용 가능한 재난 유형 목록 (대피소 지도에서 사용) - API 스키마 기준
  static const List<String> availableDisasterTypes = [
    "COLD_WAVE",
    "HEAT_WAVE",
    "FINE_DUST",
    "FLOOD",
    "EARTHQUAKE",
  ];

  // SharedPreferences 키 (선택 사항)
  static const String userAgeKey = 'user_age';
  static const String userDiseasesKey = 'user_diseases';
}
