import 'package:flutter/material.dart';
import 'package:front/data/models/added_person.dart'; // Gender 상수 사용

// API 응답 모델 import
import '../../data/models/api/health_index_response.dart';
import '../../data/models/api/weather_response.dart';
import '../../data/models/api/region_fine_dust_response.dart';
import '../../data/models/api/region_uv_response.dart';
import '../../data/models/api/common_models.dart';

// UI용 데이터 모델 import
import '../../data/models/ui/current_weather.dart';
import '../../data/models/ui/feels_like_data.dart';
import '../../data/models/ui/health_index.dart';

// 통합 상태 및 색상 정의
class UnifiedStatus {
  static const String low = '낮음';
  static const String moderate = '보통';
  static const String high = '높음';
  static const String veryHigh = '매우 높음';
  static const String extreme = '위험';
  static const String unknown = '정보 없음';

  static final Map<String, Color> colors = {
    low: Colors.green,
    moderate: Colors.blue,
    high: Colors.yellow.shade700,
    veryHigh: Colors.red,
    extreme: Colors.purple,
    unknown: Colors.grey,
  };
}

class DataMapper {
  // --- 날씨 아이콘 매핑 정보 (상수 Map) ---
  static const Map<String, ({IconData icon, Color color})> _weatherIconMap = {
    'clear': (icon: Icons.wb_sunny_rounded, color: Colors.orangeAccent),
    'clouds': (icon: Icons.cloud_outlined, color: Colors.grey), // 기본 구름
    'few clouds': (
      icon: Icons.cloud_queue_rounded,
      color: Colors.grey,
    ), // 구름 조금
    'scattered clouds': (icon: Icons.cloud_outlined, color: Colors.grey),
    'broken clouds': (icon: Icons.cloud_rounded, color: Colors.grey), // 짙은 구름
    'overcast clouds': (
      icon: Icons.cloud_off_outlined,
      color: Colors.blueGrey,
    ), // 흐림
    'rain': (icon: Icons.water_drop_outlined, color: Colors.blue), // 기본 비
    'light rain': (icon: Icons.grain_rounded, color: Colors.lightBlue), // 약한 비
    'moderate rain': (icon: Icons.water_drop_rounded, color: Colors.blue),
    'heavy intensity rain': (
      icon: Icons.waves_rounded,
      color: Colors.blue,
    ), // 강한 비
    'shower rain': (icon: Icons.shower_rounded, color: Colors.blue), // 소나기
    'drizzle': (
      icon: Icons.grain_rounded,
      color: Colors.lightBlueAccent,
    ), // 이슬비
    'snow': (icon: Icons.ac_unit_rounded, color: Colors.lightBlue), // 눈
    'light snow': (icon: Icons.ac_unit, color: Colors.lightBlue),
    'thunderstorm': (
      icon: Icons.thunderstorm_rounded,
      color: Colors.deepPurpleAccent,
    ), // 뇌우
    'mist': (icon: Icons.dehaze_rounded, color: Colors.grey), // 안개/박무
    'fog': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'haze': (icon: Icons.dehaze_rounded, color: Colors.grey),
    // 기타 (바람, 토네이도 등은 필요시 추가)
    'default': (icon: Icons.thermostat, color: Colors.grey), // 기본값
  };
  // --------------------------------------

  // --- 날씨 정보 매핑 ---
  static CurrentWeather mapWeatherResponseToUI(
    WeatherDetailResponse apiData,
    RegionInfo? regionInfo,
    String? gender,
  ) {
    // 옷차림 및 아바타 결정 (기존 로직 유지)
    String recommendation = "날씨를 확인하고 옷차림을 준비하세요.";
    String avatarImageAsset =
        'assets/images/avatar/man/man_default.png'; // 기본 아바타 경로 수정
    double currentTemp = apiData.measurements?.temp ?? 0.0;
    String cGender =
        (gender == Gender.female) ? "women" : "man"; // Gender 상수 사용

    if (apiData.measurements?.temp != null) {
      currentTemp = apiData.measurements!.temp!;
      if (currentTemp >= 28) {
        recommendation = "매우 더워요! 반팔, 반바지가 좋겠어요.";
        avatarImageAsset = 'assets/images/avatar/$cGender/${cGender}_short.png';
      } else if (currentTemp >= 23) {
        recommendation = "따뜻한 날씨네요. 가벼운 옷차림이 좋아요.";
        avatarImageAsset =
            'assets/images/avatar/$cGender/${cGender}_sshirt.png';
      } else if (currentTemp >= 20) {
        recommendation = "선선한 날씨에요. 긴팔 티가 적당해요.";
        avatarImageAsset =
            'assets/images/avatar/$cGender/${cGender}_longsl.png';
      } else if (currentTemp >= 17) {
        recommendation = "조금 쌀쌀해졌어요. 얇은 외투를 챙기세요.";
        avatarImageAsset = 'assets/images/avatar/$cGender/${cGender}_gadi.png';
      } else if (currentTemp >= 12) {
        recommendation = "제법 쌀쌀해요. 바람막이를 챙기세요.";
        avatarImageAsset = 'assets/images/avatar/$cGender/${cGender}_hood.png';
      } else if (currentTemp >= 9) {
        recommendation = "쌀쌀한 날씨에요. 점퍼나 기모 옷을 입는게 좋아요.";
        avatarImageAsset =
            'assets/images/avatar/$cGender/${cGender}_jumpper.png';
      } else if (currentTemp >= 5) {
        recommendation = "추운 날씨에요. 두꺼운 옷을 입으세요.";
        avatarImageAsset = 'assets/images/avatar/$cGender/${cGender}_knit.png';
      } else {
        recommendation = "추워요! 따뜻하게 입으세요.";
        avatarImageAsset =
            'assets/images/avatar/$cGender/${cGender}_padding.png';
      }
    }

    // 날씨 아이콘 및 색상 결정 (Map 사용)
    String description =
        apiData.weatherCondition?.description?.toLowerCase() ?? "정보 없음";
    var iconInfo = _weatherIconMap[description] ?? _weatherIconMap['default']!;

    // 키워드 포함 여부로 재확인 (더 넓은 범위 커버)
    if (iconInfo == _weatherIconMap['default']!) {
      if (description.contains('cloud'))
        iconInfo = _weatherIconMap['clouds']!;
      else if (description.contains('rain'))
        iconInfo = _weatherIconMap['rain']!;
      else if (description.contains('snow'))
        iconInfo = _weatherIconMap['snow']!;
      else if (description.contains('clear'))
        iconInfo = _weatherIconMap['clear']!;
      else if (description.contains('mist') ||
          description.contains('fog') ||
          description.contains('haze'))
        iconInfo = _weatherIconMap['mist']!;
      else if (description.contains('drizzle'))
        iconInfo = _weatherIconMap['drizzle']!;
      else if (description.contains('thunderstorm'))
        iconInfo = _weatherIconMap['thunderstorm']!;
    }

    return CurrentWeather(
      location:
          '${regionInfo?.gu ?? ""} ${regionInfo?.region ?? "위치 정보 없음"}', // 기본값 수정
      description: apiData.weatherCondition?.description ?? "정보 없음",
      recommendation: recommendation,
      weatherIcon: iconInfo.icon, // Map에서 가져온 아이콘
      weatherIconColor: iconInfo.color, // Map에서 가져온 색상
      currentTemp: apiData.measurements?.temp,
      maxTemp: apiData.measurements?.tempMax,
      minTemp: apiData.measurements?.tempMin,
      avatarImageAsset: avatarImageAsset,
    );
  }

  // --- 체감 온도 정보 매핑 ---
  static FeelsLikeData mapFeelsLikeResponseToUI(
    HealthIndexResponse apiResponse,
  ) {
    // 이 함수는 UnifiedStatus 사용 등 이미 잘 되어 있음 (기존 로직 유지)
    IndexCalculationResult? apiIndexData = apiResponse.indices;
    double temperature = apiIndexData?.apparentTemperature ?? 0.0;
    String status = UnifiedStatus.unknown;
    Color statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
    String message1 = "체감 온도 정보를 확인하세요.";
    String message2 = "";
    String buttonText = "관련 정보 보기";

    // API 응답 상태 문자열을 UnifiedStatus로 매핑
    switch (apiIndexData?.apparentTempRiskStatus?.toLowerCase()) {
      case "위험": // "위험" -> 매우 높음
        status = UnifiedStatus.veryHigh;
        statusColor = UnifiedStatus.colors[UnifiedStatus.veryHigh]!;
        message1 = "매우 높은 체감 온도! 건강에 유의하세요.";
        message2 = "야외 활동을 자제하고 수분을 충분히 섭취하세요.";
        break;
      case "경고": // "경고" -> 높음
        status = UnifiedStatus.high;
        statusColor = UnifiedStatus.colors[UnifiedStatus.high]!;
        message1 = "높은 체감 온도! 주의가 필요합니다.";
        message2 = "물을 자주 마시고, 더위에 지치지 않도록 주의하세요.";
        break;
      case "주의": // "주의" -> 보통
      case "일반인": // "일반인" -> 보통
        status = UnifiedStatus.moderate;
        statusColor = UnifiedStatus.colors[UnifiedStatus.moderate]!;
        message1 = "체감 온도가 다소 높거나 보통입니다.";
        message2 = "상황에 맞게 활동 및 옷차림을 조절하세요.";
        break;
      case "관심": // "관심" -> 낮음
      // --- "안전" 케이스 추가 ---
      case "안전": // "안전" -> 낮음
        status = UnifiedStatus.low;
        statusColor = UnifiedStatus.colors[UnifiedStatus.low]!;
        message1 = "쾌적한 체감 온도입니다."; // 메시지 수정
        message2 = "활동하기 좋은 날씨입니다."; // 메시지 수정
        break;
      // -----------------------
      default: // 그 외 또는 null
        // 알 수 없는 상태값 로그 출력
        if (apiIndexData?.apparentTempRiskStatus != null) {
          print(
            "[WARNING] Unknown apparentTempRiskStatus from API: ''. Mapping to '정보 없음'.",
          );
        }
        status = UnifiedStatus.unknown; // 알 수 없는 값은 '정보 없음'으로 매핑
        statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
        message1 = "체감 온도 정보를 가져올 수 없습니다.";
        break;
    }

    return FeelsLikeData(
      temperature: temperature,
      status: status,
      statusColor: statusColor,
      message1: message1,
      message2: message2,
      buttonText: buttonText,
    );
  }

  // --- 건강 지수 리스트 매핑 ---
  static List<HealthIndex> mapHealthIndicesResponseToUI(
    HealthIndexResponse? apiIndexResponse,
    SingleRegionUvResponse? uvData,
    SingleRegionFineDustResponse? fineDustData,
  ) {
    final List<HealthIndex> indices = [];
    // API 응답이 null이면 빈 리스트 반환
    if (apiIndexResponse == null) return indices;

    final apiIndexData = apiIndexResponse.indices;

    // --- 매핑 로직 (null 안전성 강화 및 명확성 개선) ---

    // 1. 천식/폐질환 (ALI)
    if (apiIndexData.aliLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.aliLevel!);
      indices.add(
        HealthIndex(
          name: '천식질환 지수',
          // score가 null이면 level을 double로 사용, 둘 다 null이면 0.0
          value:
              (apiIndexData.aliScore ?? apiIndexData.aliLevel?.toDouble()) ??
              0.0,
          status: mapped.status,
          icon: Icons.masks,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 2. 뇌졸중 (Stroke)
    if (apiIndexData.strokeIndexLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.strokeIndexLevel!);
      indices.add(
        HealthIndex(
          name: '심뇌혈관질환 지수',
          value:
              (apiIndexData.strokeIndexScore ??
                  apiIndexData.strokeIndexLevel?.toDouble()) ??
              0.0,
          status: mapped.status,
          icon: Icons.monitor_heart_outlined,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 3. 감기 (Cold)
    if (apiIndexData.coldIndexLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.coldIndexLevel!);
      indices.add(
        HealthIndex(
          name: '감기가능 지수',
          value:
              (apiIndexData.coldIndexScore ??
                  apiIndexData.coldIndexLevel?.toDouble()) ??
              0.0,
          status: mapped.status,
          icon: Icons.sick,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 4. 식중독 (Food Poisoning)
    if (apiIndexData.foodPoisoningRisk != null) {
      var mapped = _mapFoodPoisoningRiskToUnifiedStatusInfo(
        apiIndexData.foodPoisoningRisk!,
      );
      // 문자열 값을 double로 파싱, 실패 시 0.0 사용
      double parsedValue =
          double.tryParse(apiIndexData.foodPoisoningIndex ?? '') ?? 0.0;
      indices.add(
        HealthIndex(
          name: '식중독 지수',
          value: parsedValue,
          status: mapped.status,
          icon: Icons.fastfood,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 5. UV 지수
    if (uvData?.uvData?.uvIndex != null) {
      int uvValue = uvData!.uvData!.uvIndex!;
      var mapped = _mapUvIndexToUnifiedStatusInfo(uvValue);
      indices.add(
        HealthIndex(
          name: '자외선 지수',
          value: uvValue.toDouble(), // 정수를 double로 변환
          status: mapped.status,
          icon: Icons.wb_sunny_outlined,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 6. 미세먼지 지수 (PM10 우선, 없으면 PM2.5 사용)
    if (fineDustData?.fineDustData != null) {
      // PM10 또는 PM2.5 값 중 유효한 값 선택
      int? pmValue =
          fineDustData!.fineDustData!.pm10 ?? fineDustData!.fineDustData!.pm25;
      String? grade = fineDustData!.fineDustData!.grade;

      if (pmValue != null) {
        var mapped = _mapAirQualityToUnifiedStatusInfo(pmValue, grade);
        indices.add(
          HealthIndex(
            name: '미세먼지 지수', // 필요시 PM10/PM2.5 구분 표시
            value: pmValue.toDouble(),
            status: mapped.status,
            icon: Icons.blur_linear_rounded,
            iconColor: _calculateIconBgColor(mapped.color),
            statusColor: mapped.color,
          ),
        );
      }
    }

    // 7. 꽃가루 지수 (소나무) - 더미 데이터 유지
    var pollenMapped = _mapDummyStatusToUnified('나쁨');
    indices.add(
      HealthIndex(
        name: '꽃가루농도 지수(소나무)',
        value: 66,
        status: pollenMapped.status,
        icon: Icons.local_florist,
        iconColor: _calculateIconBgColor(pollenMapped.color),
        statusColor: pollenMapped.color,
      ),
    );

    // 8. 대기 정체 지수 - 더미 데이터 유지
    var stagnationMapped = _mapDummyStatusToUnified('보통');
    indices.add(
      HealthIndex(
        name: '대기정체 지수',
        value: 27,
        status: stagnationMapped.status,
        icon: Icons.landscape_outlined,
        iconColor: _calculateIconBgColor(stagnationMapped.color),
        statusColor: stagnationMapped.color,
      ),
    );

    return indices;
  }

  // --- Helper 함수들 (통합 상태/색상 반환) ---

  // 아이콘 배경색 계산 (기존과 동일)
  static Color _calculateIconBgColor(Color statusColor) {
    // Color.lerp(statusColor, Colors.white, 0) 는 statusColor와 동일. 투명도 조절로 변경.
    return statusColor.withOpacity(0.8); // 약간 투명하게 하여 부드러운 느낌
  }

  // 숫자 레벨(1:매우높음 ~ 4:낮음) -> 통합 상태/색상
  static ({String status, Color color}) _mapLevelToUnifiedStatusInfo(
    int? level,
  ) {
    // null 입력 처리 추가
    if (level == null) {
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
    }
    switch (level) {
      case 1:
        return (
          status: UnifiedStatus.veryHigh,
          color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
        );
      case 2:
        return (
          status: UnifiedStatus.high,
          color: UnifiedStatus.colors[UnifiedStatus.high]!,
        );
      case 3:
        return (
          status: UnifiedStatus.moderate,
          color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
        );
      case 4:
        return (
          status: UnifiedStatus.low,
          color: UnifiedStatus.colors[UnifiedStatus.low]!,
        );
      default:
        return (
          status: UnifiedStatus.unknown,
          color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
        ); // 예상 외 레벨 처리
    }
  }

  // 식중독 위험도 문자열 -> 통합 상태/색상
  static ({String status, Color color})
  _mapFoodPoisoningRiskToUnifiedStatusInfo(String? risk) {
    // null 입력 처리 추가
    if (risk == null) {
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
    }
    switch (risk.toLowerCase()) {
      // 소문자로 비교하여 일관성 확보
      case '위험':
        return (
          status: UnifiedStatus.veryHigh,
          color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
        );
      case '경고':
        return (
          status: UnifiedStatus.high,
          color: UnifiedStatus.colors[UnifiedStatus.high]!,
        );
      case '주의':
        return (
          status: UnifiedStatus.moderate,
          color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
        );
      case '관심':
        return (
          status: UnifiedStatus.low,
          color: UnifiedStatus.colors[UnifiedStatus.low]!,
        );
      default:
        return (
          status: UnifiedStatus.unknown,
          color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
        ); // 예상 외 문자열 처리
    }
  }

  // UV 지수 값 -> 통합 상태/색상 (5단계)
  static ({String status, Color color}) _mapUvIndexToUnifiedStatusInfo(
    int? uvIndex,
  ) {
    // null 입력 처리 추가
    if (uvIndex == null) {
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
    }
    if (uvIndex <= 2)
      return (
        status: UnifiedStatus.low,
        color: UnifiedStatus.colors[UnifiedStatus.low]!,
      );
    else if (uvIndex <= 5)
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      );
    else if (uvIndex <= 7)
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      );
    else if (uvIndex <= 10)
      return (
        status: UnifiedStatus.veryHigh,
        color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
      );
    else
      return (
        status: UnifiedStatus.extreme,
        color: UnifiedStatus.colors[UnifiedStatus.extreme]!,
      ); // 11 이상
  }

  // 미세먼지(PM) 값과 등급(GRADE) -> 통합 상태/색상
  static ({String status, Color color}) _mapAirQualityToUnifiedStatusInfo(
    int pmValue,
    String? grade,
  ) {
    // 등급 정보가 있으면 우선 사용
    if (grade != null) {
      switch (grade) {
        case "좋음":
          return (
            status: UnifiedStatus.low,
            color: UnifiedStatus.colors[UnifiedStatus.low]!,
          );
        case "보통":
          return (
            status: UnifiedStatus.moderate,
            color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
          );
        case "나쁨":
          return (
            status: UnifiedStatus.high,
            color: UnifiedStatus.colors[UnifiedStatus.high]!,
          );
        case "매우나쁨":
          return (
            status: UnifiedStatus.veryHigh,
            color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
          );
        // 예상치 못한 등급 문자열은 아래 값 기준으로 판단
      }
    }
    // 등급 정보가 없거나 매핑되지 않으면 PM 값 기준으로 판단 (WHO 기준 참고, PM10 기준)
    if (pmValue <= 50)
      return (
        status: UnifiedStatus.low,
        color: UnifiedStatus.colors[UnifiedStatus.low]!,
      ); // 좋음
    else if (pmValue <= 100)
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      ); // 보통
    else if (pmValue <= 250)
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      ); // 나쁨
    else
      return (
        status: UnifiedStatus.veryHigh,
        color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
      ); // 매우 나쁨 (PM2.5 기준과 다름 주의)
  }

  // (더미 데이터용) 임시 상태 문자열 -> 통합 상태/색상
  static ({String status, Color color}) _mapDummyStatusToUnified(
    String dummyStatus,
  ) {
    // 기존 로직 유지 (예시용)
    if (dummyStatus == '나쁨')
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      );
    else if (dummyStatus == '보통')
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      );
    else
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
  }
}
