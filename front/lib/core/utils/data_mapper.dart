import 'package:flutter/material.dart';
import 'package:front/data/models/added_person.dart';

// API 응답 모델 import (경로 수정)
import '../../data/models/api/health_index_response.dart';
import '../../data/models/api/weather_response.dart';
import '../../data/models/api/region_fine_dust_response.dart';
import '../../data/models/api/region_uv_response.dart';
import '../../data/models/api/common_models.dart';

// UI용 데이터 모델 import (경로 수정)
import '../../data/models/ui/current_weather.dart';
import '../../data/models/ui/feels_like_data.dart';
import '../../data/models/ui/health_index.dart';
// import '../../data/models/ui/user_profile.dart'; // 필요시 사용

// --- 통합 상태 및 색상 정의 (가독성을 위해 추가) ---
class UnifiedStatus {
  static const String low = '낮음';
  static const String moderate = '보통';
  static const String high = '높음';
  static const String veryHigh = '매우 높음';
  static const String extreme = '위험'; // 5단계
  static const String unknown = '정보 없음';

  static final Map<String, Color> colors = {
    low: Colors.green, // Level 1
    moderate: Colors.blue, // Level 2
    high: Colors.yellow.shade700, // Level 3
    veryHigh: Colors.red, // Level 4
    extreme: Colors.purple, // Level 5
    unknown: Colors.grey, // Level 0
  };
}
// ---------------------------------------------

class DataMapper {
  // --- 날씨 정보 매핑 ---
  static CurrentWeather mapWeatherResponseToUI(
    WeatherDetailResponse apiData,
    RegionInfo? regionInfo,
    String? gender,
  ) {
    // 옷차림 및 아바타 결정 로직 (임시)
    // TODO: 날씨 상태(description), 온도 등을 고려한 실제 로직 구현 필요
    String recommendation = "날씨 확인 중...";
    String avatarImageAsset = 'assets/images/man_1.png'; // 기본 아바타 (경로 수정)
    double currentTemp = apiData.measurements?.temp ?? 0.0;
    String currentGender = gender ?? Gender.male;
    String cGender = currentGender == "male" ? "man" : "women";

    // --- 온도 기반 추천 및 아바타 (개선) ---
    print(apiData.measurements?.temp);
    if (apiData.measurements?.temp != null) {
      currentTemp = apiData.measurements!.temp!;
      if (currentTemp >= 28) {
        recommendation = "매우 더워요! 반팔, 반바지가 좋겠어요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_short.png';
      } else if (currentTemp >= 23) {
        recommendation = "따뜻한 날씨네요. 가벼운 옷차림이 좋아요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_sshirt.png';
      } else if (currentTemp >= 20) {
        recommendation = "선선한 날씨에요. 긴팔 티가 적당해요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_longsl.png';
      } else if (currentTemp >= 17) {
        recommendation = "조금 쌀쌀해졌어요. 얇은 외투를 챙기세요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_gadi.png';
      } else if (currentTemp >= 12) {
        recommendation = "제법 쌀쌀해요. 바람막이를 챙기세요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_hood.png';
      } else if (currentTemp >= 9) {
        recommendation = "쌀쌀한 날씨에요. 점퍼나 기모 옷을 입는게 좋아요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_jumpper.png';
      } else if (currentTemp >= 5) {
        recommendation = "추운 날씨에요. 두꺼운 옷을 입으세요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_knit.png';
      } else {
        recommendation = "추워요! 따뜻하게 입으세요.";
        avatarImageAsset =
            'assets/images/avatar/${cGender}/${cGender}_padding.png';
      }
    }
    // TODO: 날씨 상태(맑음, 비, 눈 등)에 따른 추천 및 아바타 추가

    // 날씨 아이콘 및 색상 결정 로직
    IconData weatherIcon = Icons.wb_sunny_rounded; // 기본: 맑음
    Color weatherIconColor = Colors.orangeAccent;
    String description =
        apiData.weatherCondition?.description?.toLowerCase() ??
        "정보 없음"; // 소문자로 비교

    // 예시: 간단한 매핑
    if (description.contains('cloud')) {
      weatherIcon = Icons.cloud_outlined;
      weatherIconColor = Colors.grey.shade500;
    } else if (description.contains('rain') ||
        description.contains('drizzle')) {
      weatherIcon = Icons.water_drop_outlined; // 좀 더 비 관련 아이콘
      weatherIconColor = Colors.blue.shade400;
    } else if (description.contains('snow')) {
      weatherIcon = Icons.ac_unit_rounded;
      weatherIconColor = Colors.lightBlueAccent.shade100;
    } else if (description.contains('clear')) {
      weatherIcon = Icons.wb_sunny_rounded;
      weatherIconColor = Colors.orangeAccent;
    } else if (description.contains('mist') ||
        description.contains('fog') ||
        description.contains('haze')) {
      weatherIcon = Icons.dehaze_rounded;
      weatherIconColor = Colors.grey.shade400;
    }
    // ... 다른 날씨 상태 추가 ...

    return CurrentWeather(
      location:
          '${regionInfo?.gu ?? ""} ${regionInfo?.region ?? "위치 정보"}', // 기본값 수정
      description: apiData.weatherCondition?.description ?? "정보 없음",
      recommendation: recommendation,
      weatherIcon: weatherIcon,
      weatherIconColor: weatherIconColor,
      currentTemp: apiData.measurements?.temp, // double? 그대로 전달
      maxTemp: apiData.measurements?.tempMax, // double? 그대로 전달
      minTemp: apiData.measurements?.tempMin, // double? 그대로 전달
      avatarImageAsset: avatarImageAsset, // 결정된 아바타 경로
    );
  }

  // --- 체감 온도 정보 매핑 (통합 상태/색상 사용) ---
  static FeelsLikeData mapFeelsLikeResponseToUI(
    HealthIndexResponse apiResponse,
  ) {
    IndexCalculationResult? apiIndexData = apiResponse.indices;

    double temperature = apiIndexData?.apparentTemperature ?? 0.0;
    String status = UnifiedStatus.unknown; // 기본값: 정보 없음
    Color statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
    String message1 = "체감 온도 정보를 확인하세요.";
    String message2 = "";
    String buttonText = "관련 정보 보기"; // 기본 버튼 텍스트

    switch (apiIndexData?.apparentTempRiskStatus) {
      case "위험":
        status = UnifiedStatus.veryHigh; // '위험' -> '매우 높음' 매핑
        statusColor = UnifiedStatus.colors[UnifiedStatus.veryHigh]!;
        message1 = "매우 높은 체감 온도! 건강에 유의하세요.";
        message2 = "야외 활동을 자제하고 수분을 충분히 섭취하세요.";
        break;
      case "경고":
        status = UnifiedStatus.high; // '경고' -> '높음' 매핑
        statusColor = UnifiedStatus.colors[UnifiedStatus.high]!;
        message1 = "높은 체감 온도! 주의가 필요합니다.";
        message2 = "물을 자주 마시고, 더위에 지치지 않도록 주의하세요.";
        break;
      case "주의":
      case "일반인": // '일반인'도 '보통'으로 취급
        status = UnifiedStatus.moderate; // '주의', '일반인' -> '보통' 매핑
        statusColor = UnifiedStatus.colors[UnifiedStatus.moderate]!;
        message1 = "체감 온도가 다소 높거나 보통입니다."; // 메시지 통합 또는 조정
        message2 = "상황에 맞게 활동 및 옷차림을 조절하세요.";
        break;
      case "관심":
        status = UnifiedStatus.low; // '관심' -> '낮음' 매핑
        statusColor = UnifiedStatus.colors[UnifiedStatus.low]!;
        message1 = "체감 온도를 주시할 필요가 있습니다.";
        message2 = "환절기 등 변화에 유의하세요.";
        break;
      default:
        // 상태 문자열이 있지만 위 case에 해당하지 않으면 그대로 사용 (색상은 grey)
        status = apiIndexData?.apparentTempRiskStatus ?? UnifiedStatus.unknown;
        statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
        break;
    }

    return FeelsLikeData(
      temperature: temperature,
      status: status, // 통합된 상태 문자열 사용
      statusColor: statusColor, // 통합된 색상 사용
      message1: message1,
      message2: message2,
      buttonText: buttonText,
    );
  }

  // --- 건강 지수 리스트 매핑 (통합 상태/색상 사용) ---
  static List<HealthIndex> mapHealthIndicesResponseToUI(
    HealthIndexResponse? apiIndexResponse,
    SingleRegionUvResponse? uvData,
    SingleRegionFineDustResponse? fineDustData,
  ) {
    final List<HealthIndex> indices = [];
    if (apiIndexResponse == null) return indices;

    final apiIndexData = apiIndexResponse.indices;

    // --- 헬퍼 함수들을 사용하여 통합 상태/색상 정보 가져오기 ---

    // 1. 천식/폐질환 (ALI)
    if (apiIndexData.aliLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.aliLevel!);
      Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
      indices.add(
        HealthIndex(
          name: '천식질환 지수',
          value: apiIndexData.aliScore ?? apiIndexData.aliLevel!.toDouble(),
          status: mapped.status, // 통합 상태
          icon: Icons.masks,
          iconColor: iconBackgroundColor,
          statusColor: mapped.color, // 통합 색상
        ),
      );
    }

    // 2. 뇌졸중 (Stroke)
    if (apiIndexData.strokeIndexLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.strokeIndexLevel!);
      Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
      indices.add(
        HealthIndex(
          name: '심뇌혈관질환 지수',
          value:
              apiIndexData.strokeIndexScore ??
              apiIndexData.strokeIndexLevel!.toDouble(),
          status: mapped.status, // 통합 상태
          icon: Icons.monitor_heart_outlined,
          iconColor: iconBackgroundColor,
          statusColor: mapped.color, // 통합 색상
        ),
      );
    }

    // 3. 감기 (Cold)
    if (apiIndexData.coldIndexLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.coldIndexLevel!);
      Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
      indices.add(
        HealthIndex(
          name: '감기가능 지수',
          value:
              apiIndexData.coldIndexScore ??
              apiIndexData.coldIndexLevel!.toDouble(),
          status: mapped.status, // 통합 상태
          icon: Icons.sick,
          iconColor: iconBackgroundColor,
          statusColor: mapped.color, // 통합 색상
        ),
      );
    }

    // 4. 식중독 (Food Poisoning)
    if (apiIndexData.foodPoisoningRisk != null) {
      var mapped = _mapFoodPoisoningRiskToUnifiedStatusInfo(
        apiIndexData.foodPoisoningRisk!,
      );
      Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
      double parsedValue =
          double.tryParse(apiIndexData.foodPoisoningIndex ?? '0.0') ?? 0.0;

      indices.add(
        HealthIndex(
          name: '식중독 지수',
          value: parsedValue,
          status: mapped.status, // 통합 상태
          icon: Icons.fastfood,
          iconColor: iconBackgroundColor,
          statusColor: mapped.color, // 통합 색상
        ),
      );
    }

    // 5. UV 지수
    if (uvData?.uvData?.uvIndex != null) {
      int uvValue = uvData!.uvData!.uvIndex!;
      var mapped = _mapUvIndexToUnifiedStatusInfo(uvValue);
      Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
      indices.add(
        HealthIndex(
          name: '자외선 지수',
          value: uvValue.toDouble(),
          status: mapped.status, // 통합 상태
          icon: Icons.wb_sunny_outlined,
          iconColor: iconBackgroundColor,
          statusColor: mapped.color, // 통합 색상
        ),
      );
    }

    // 6. 미세먼지 지수
    if (fineDustData?.fineDustData != null) {
      var pmValue =
          fineDustData!.fineDustData!.pm10 ?? fineDustData!.fineDustData!.pm25;
      var grade = fineDustData!.fineDustData!.grade;

      if (pmValue != null) {
        var mapped = _mapAirQualityToUnifiedStatusInfo(pmValue, grade);
        Color iconBackgroundColor = _calculateIconBgColor(mapped.color);
        indices.add(
          HealthIndex(
            name: '미세먼지 지수',
            value: pmValue.toDouble(),
            status: mapped.status, // 통합 상태
            icon: Icons.blur_linear_rounded,
            iconColor: iconBackgroundColor,
            statusColor: mapped.color, // 통합 색상
          ),
        );
      }
    }

    // 7. 꽃가루 지수 (소나무) - 더미 데이터 (통합 매핑 적용)
    var pollenMapped = _mapDummyStatusToUnified('나쁨'); // '나쁨' -> '높음'으로 간주
    indices.add(
      HealthIndex(
        name: '꽃가루농도 지수(소나무)',
        value: 66,
        status: pollenMapped.status, // 통합 상태
        icon: Icons.local_florist,
        iconColor: _calculateIconBgColor(pollenMapped.color),
        statusColor: pollenMapped.color, // 통합 색상
      ),
    );

    // 8. 대기 정체 지수 - 더미 데이터 (통합 매핑 적용)
    var stagnationMapped = _mapDummyStatusToUnified('보통'); // '보통' -> '보통'으로 간주
    indices.add(
      HealthIndex(
        name: '대기정체 지수',
        value: 27,
        status: stagnationMapped.status, // 통합 상태
        icon: Icons.landscape_outlined,
        iconColor: _calculateIconBgColor(stagnationMapped.color),
        statusColor: stagnationMapped.color, // 통합 색상
      ),
    );

    return indices;
  }

  // --- Helper 함수들 (통합 상태/색상 반환하도록 수정) ---

  // 아이콘 배경색 계산 (기존 로직 유지, 상태 색상 기반)
  static Color _calculateIconBgColor(Color statusColor) {
    return Color.lerp(statusColor, Colors.white, 0) ??
        statusColor.withOpacity(0.1);
  }

  // 숫자 레벨(1:매우높음 ~ 4:낮음) -> 통합 상태/색상
  static ({String status, Color color}) _mapLevelToUnifiedStatusInfo(
    int level,
  ) {
    switch (level) {
      case 1: // 매우높음
        return (
          status: UnifiedStatus.veryHigh,
          color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
        );
      case 2: // 높음
        return (
          status: UnifiedStatus.high,
          color: UnifiedStatus.colors[UnifiedStatus.high]!,
        );
      case 3: // 보통
        return (
          status: UnifiedStatus.moderate,
          color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
        );
      case 4: // 낮음
        return (
          status: UnifiedStatus.low,
          color: UnifiedStatus.colors[UnifiedStatus.low]!,
        );
      default:
        return (
          status: UnifiedStatus.unknown,
          color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
        );
    }
  }

  // 식중독 위험도 문자열 -> 통합 상태/색상
  static ({String status, Color color})
  _mapFoodPoisoningRiskToUnifiedStatusInfo(String risk) {
    switch (risk) {
      case '위험': // 매우 높음
        return (
          status: UnifiedStatus.veryHigh,
          color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
        );
      case '경고': // 높음
        return (
          status: UnifiedStatus.high,
          color: UnifiedStatus.colors[UnifiedStatus.high]!,
        );
      case '주의': // 보통
        return (
          status: UnifiedStatus.moderate,
          color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
        );
      case '관심': // 낮음
        return (
          status: UnifiedStatus.low,
          color: UnifiedStatus.colors[UnifiedStatus.low]!,
        );
      default:
        return (
          status: UnifiedStatus.unknown,
          color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
        );
    }
  }

  // UV 지수 값 -> 통합 상태/색상 (5단계)
  static ({String status, Color color}) _mapUvIndexToUnifiedStatusInfo(
    int uvIndex,
  ) {
    if (uvIndex <= 2) {
      // 낮음
      return (
        status: UnifiedStatus.low,
        color: UnifiedStatus.colors[UnifiedStatus.low]!,
      );
    } else if (uvIndex <= 5) {
      // 보통
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      );
    } else if (uvIndex <= 7) {
      // 높음
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      );
    } else if (uvIndex <= 10) {
      // 매우 높음
      return (
        status: UnifiedStatus.veryHigh,
        color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
      );
    } else {
      // 위험 (11 이상)
      return (
        status: UnifiedStatus.extreme,
        color: UnifiedStatus.colors[UnifiedStatus.extreme]!,
      );
    }
  }

  // 미세먼지(PM) 값과 등급(GRADE) -> 통합 상태/색상
  static ({String status, Color color}) _mapAirQualityToUnifiedStatusInfo(
    int pmValue,
    String? grade,
  ) {
    String statusText;
    Color statusColor;

    if (grade != null) {
      switch (grade) {
        case "좋음":
          statusText = UnifiedStatus.low;
          statusColor = UnifiedStatus.colors[UnifiedStatus.low]!;
          break;
        case "보통":
          statusText = UnifiedStatus.moderate;
          statusColor = UnifiedStatus.colors[UnifiedStatus.moderate]!;
          break;
        case "나쁨":
          statusText = UnifiedStatus.high;
          statusColor = UnifiedStatus.colors[UnifiedStatus.high]!;
          break;
        case "매우나쁨":
          statusText = UnifiedStatus.veryHigh;
          statusColor = UnifiedStatus.colors[UnifiedStatus.veryHigh]!;
          break;
        default:
          statusText = UnifiedStatus.unknown;
          statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
          break;
      }
    } else {
      // 등급 정보 없을 때 PM 값 기준으로 판단 (예시, 기준값 조정 필요)
      if (pmValue <= 30) {
        // 좋음 -> 낮음
        statusText = UnifiedStatus.low;
        statusColor = UnifiedStatus.colors[UnifiedStatus.low]!;
      } else if (pmValue <= 80) {
        // 보통 -> 보통
        statusText = UnifiedStatus.moderate;
        statusColor = UnifiedStatus.colors[UnifiedStatus.moderate]!;
      } else if (pmValue <= 150) {
        // 나쁨 -> 높음
        statusText = UnifiedStatus.high;
        statusColor = UnifiedStatus.colors[UnifiedStatus.high]!;
      } else {
        // 매우 나쁨 -> 매우 높음
        statusText = UnifiedStatus.veryHigh;
        statusColor = UnifiedStatus.colors[UnifiedStatus.veryHigh]!;
      }
    }
    return (status: statusText, color: statusColor);
  }

  // (더미 데이터용) 임시 상태 문자열 -> 통합 상태/색상
  // 예시: '나쁨' -> '높음', '보통' -> '보통'
  static ({String status, Color color}) _mapDummyStatusToUnified(
    String dummyStatus,
  ) {
    if (dummyStatus == '나쁨') {
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      );
    } else if (dummyStatus == '보통') {
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      );
    } // ... 다른 더미 상태에 대한 매핑 추가
    else {
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
    }
  }
} // End of DataMapper class
