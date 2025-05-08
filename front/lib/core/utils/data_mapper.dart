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
import '../../data/models/ui/hourly_weather_ui.dart'; // <<< 추가
import 'package:intl/intl.dart'; // <<< 날짜/시간 포매팅 위해 추가

// 통합 상태 및 색상 정의 (기존과 동일)
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
  // --- 수정된 날씨 아이콘 매핑 정보 ---
  // API 응답의 'main' 필드 (첫 글자 대문자)를 키로 사용
  static const Map<String, ({IconData icon, Color color})> _weatherIconMap = {
    'Clear': (icon: Icons.wb_sunny_rounded, color: Colors.orangeAccent),
    'Clouds': (icon: Icons.cloud_outlined, color: Colors.grey), // 기본 구름
    'Rain': (icon: Icons.water_drop_outlined, color: Colors.blue), // 기본 비
    'Drizzle': (
      icon: Icons.grain_rounded,
      color: Colors.lightBlueAccent,
    ), // 이슬비
    'Snow': (icon: Icons.ac_unit_rounded, color: Colors.lightBlue), // 눈
    'Thunderstorm': (
      icon: Icons.thunderstorm_rounded,
      color: Colors.deepPurpleAccent,
    ), // 뇌우
    'Mist': (icon: Icons.dehaze_rounded, color: Colors.grey), // 안개/박무
    'Smoke': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Haze': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Dust': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Fog': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Sand': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Ash': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Squall': (icon: Icons.dehaze_rounded, color: Colors.grey),
    'Tornado': (icon: Icons.dehaze_rounded, color: Colors.grey),
    // 기본값 추가 (매핑되지 않은 경우 대비)
    'Default': (icon: Icons.thermostat, color: Colors.grey),
  };
  // --------------------------------------

  static const Map<String, String> _weatherDescriptionMap = {
    'Clear': '맑음',
    'Clouds': '흐림', // 또는 '구름'
    'Rain': '비',
    'Drizzle': '이슬비',
    'Snow': '눈',
    'Thunderstorm': '뇌우',
    'Mist': '옅은 안개',
    'Smoke': '연기',
    'Haze': '실안개',
    'Dust': '먼지',
    'Fog': '안개',
    'Sand': '황사', // 모래바람
    'Ash': '화산재',
    'Squall': '돌풍', // 스콜
    'Tornado': '토네이도',
  };

  // --- 날씨 정보 매핑 (아이콘 매핑 로직 수정) ---
  static CurrentWeather mapWeatherResponseToUI(
    WeatherDetailResponse apiData,
    RegionInfo? regionInfo,
    String? gender,
  ) {
    // 옷차림 및 아바타 결정 (기존 로직 유지)
    String recommendation = "날씨를 확인하고 옷차림을 준비하세요.";
    String avatarImageAsset = 'assets/images/avatar/man/man_default.png';
    double currentTemp = apiData.measurements?.temp ?? 0.0;
    String cGender = (gender == Gender.female) ? "women" : "man";

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

    // --- 날씨 아이콘 및 색상 결정 (수정된 로직) ---
    String mainWeather =
        apiData.weatherCondition?.main ?? ""; // API 응답의 'main' 값 가져오기
    String lookupKey = "Default"; // 기본 키

    if (mainWeather.isNotEmpty) {
      // 첫 글자를 대문자로 변환 (Map의 키와 일치시키기 위해)
      String capitalizedMainWeather =
          mainWeather[0].toUpperCase() + mainWeather.substring(1).toLowerCase();
      // Map에 해당 키가 있는지 확인 후 사용, 없으면 'Default' 사용
      if (_weatherIconMap.containsKey(capitalizedMainWeather)) {
        lookupKey = capitalizedMainWeather;
      }
    }

    // Map에서 아이콘 정보 조회 (없으면 'Default' 사용)
    final iconInfo = _weatherIconMap[lookupKey] ?? _weatherIconMap['Default']!;
    // ------------------------------------------

    String mainWeatherKey = apiData.weatherCondition?.main ?? "";
    if (mainWeatherKey.isNotEmpty) {
      // _weatherDescriptionMap의 키와 일치시키기 위해 첫 글자 대문자로
      mainWeatherKey =
          mainWeatherKey[0].toUpperCase() +
          mainWeatherKey.substring(1).toLowerCase();
    }

    String displayDescription =
        _weatherDescriptionMap[mainWeatherKey] ?? // 매핑된 한글 설명
        apiData.weatherCondition?.description ?? // 기존 상세 설명 (fallback 1)
        mainWeatherKey; // 영어 main 값 (fallback 2)

    if (displayDescription.isEmpty ||
        displayDescription == mainWeatherKey &&
            !_weatherDescriptionMap.containsValue(mainWeatherKey)) {
      displayDescription =
          _weatherDescriptionMap[mainWeatherKey] ?? "날씨 정보"; // 가장 기본적인 fallback
    }

    return CurrentWeather(
      location: '${regionInfo?.gu ?? ""} ${regionInfo?.region ?? "위치 정보 없음"}',
      // '맑음' 대신 API에서 제공하는 상세 설명을 그대로 사용하거나, main 값을 사용할 수 있음
      // 여기서는 API의 상세 설명을 우선 사용
      description: displayDescription, // description이 없으면 main 값 표시
      recommendation: recommendation,
      weatherIcon: iconInfo.icon, // Map에서 가져온 아이콘
      weatherIconColor: iconInfo.color, // Map에서 가져온 색상
      currentTemp: apiData.measurements?.temp,
      maxTemp: apiData.measurements?.tempMax,
      minTemp: apiData.measurements?.tempMin,
      avatarImageAsset: avatarImageAsset,
    );
  }

  // --- 체감 온도 정보 매핑 (기존과 동일) ---
  static FeelsLikeData mapFeelsLikeResponseToUI(
    HealthIndexResponse apiResponse,
  ) {
    IndexCalculationResult? apiIndexData = apiResponse.indices;
    double temperature = apiIndexData?.apparentTemperature ?? 0.0;
    String status = UnifiedStatus.unknown;
    Color statusColor = UnifiedStatus.colors[UnifiedStatus.unknown]!;
    String message1 = "체감 온도 정보를 확인하세요.";
    String message2 = "";
    String buttonText = "관련 정보 보기";

    switch (apiIndexData?.apparentTempRiskStatus?.toLowerCase()) {
      case "위험":
        status = UnifiedStatus.veryHigh;
        statusColor = UnifiedStatus.colors[UnifiedStatus.veryHigh]!;
        message1 = "매우 높은 체감 온도! 건강에 유의하세요.";
        message2 = "야외 활동을 자제하고 수분을 충분히 섭취하세요.";
        break;
      case "경고":
        status = UnifiedStatus.high;
        statusColor = UnifiedStatus.colors[UnifiedStatus.high]!;
        message1 = "높은 체감 온도! 주의가 필요합니다.";
        message2 = "물을 자주 마시고, 더위에 지치지 않도록 주의하세요.";
        break;
      case "주의":
      case "일반인":
        status = UnifiedStatus.moderate;
        statusColor = UnifiedStatus.colors[UnifiedStatus.moderate]!;
        message1 = "체감 온도가 다소 높거나 보통입니다.";
        message2 = "상황에 맞게 활동 및 옷차림을 조절하세요.";
        break;
      case "관심":
      case "안전":
        status = UnifiedStatus.low;
        statusColor = UnifiedStatus.colors[UnifiedStatus.low]!;
        message1 = "쾌적한 체감 온도입니다.";
        message2 = "활동하기 좋은 날씨입니다.";
        break;
      default:
        if (apiIndexData?.apparentTempRiskStatus != null) {
          print(
            "[WARNING] Unknown apparentTempRiskStatus from API: '${apiIndexData?.apparentTempRiskStatus}'. Mapping to '정보 없음'.",
          );
        }
        status = UnifiedStatus.unknown;
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

  // --- 건강 지수 리스트 매핑 (기존과 동일) ---
  static List<HealthIndex> mapHealthIndicesResponseToUI(
    HealthIndexResponse? apiIndexResponse,
    SingleRegionUvResponse? uvData,
    SingleRegionFineDustResponse? fineDustData,
  ) {
    final List<HealthIndex> indices = [];
    if (apiIndexResponse == null) return indices;

    final apiIndexData = apiIndexResponse.indices;

    // 1. 천식/폐질환 (ALI)
    if (apiIndexData.aliLevel != null) {
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.aliLevel);
      indices.add(
        HealthIndex(
          name: '천식질환 지수',
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
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.strokeIndexLevel);
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
      var mapped = _mapLevelToUnifiedStatusInfo(apiIndexData.coldIndexLevel);
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
        apiIndexData.foodPoisoningRisk,
      );
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
          value: uvValue.toDouble(),
          status: mapped.status,
          icon: Icons.wb_sunny_outlined,
          iconColor: _calculateIconBgColor(mapped.color),
          statusColor: mapped.color,
        ),
      );
    }

    // 6. 미세먼지 지수 (PM10 우선)
    if (fineDustData?.fineDustData != null) {
      int? pmValue =
          fineDustData!.fineDustData!.pm10 ?? fineDustData!.fineDustData!.pm25;
      String? grade = fineDustData!.fineDustData!.grade;
      if (pmValue != null) {
        var mapped = _mapAirQualityToUnifiedStatusInfo(pmValue, grade);
        indices.add(
          HealthIndex(
            name: '미세먼지 지수',
            value: pmValue.toDouble(),
            status: mapped.status,
            icon: Icons.blur_linear_rounded,
            iconColor: _calculateIconBgColor(mapped.color),
            statusColor: mapped.color,
          ),
        );
      }
    }

    // 7. 꽃가루 지수 (소나무) - 더미
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

    // 8. 대기 정체 지수 - 더미
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

  // --- Helper 함수들 (기존과 동일) ---

  static Color _calculateIconBgColor(Color statusColor) {
    return statusColor.withOpacity(0.8);
  }

  static ({String status, Color color}) _mapLevelToUnifiedStatusInfo(
    int? level,
  ) {
    if (level == null)
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
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
        );
    }
  }

  static ({String status, Color color})
  _mapFoodPoisoningRiskToUnifiedStatusInfo(String? risk) {
    if (risk == null)
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
    switch (risk.toLowerCase()) {
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
        );
    }
  }

  static ({String status, Color color}) _mapUvIndexToUnifiedStatusInfo(
    int? uvIndex,
  ) {
    if (uvIndex == null)
      return (
        status: UnifiedStatus.unknown,
        color: UnifiedStatus.colors[UnifiedStatus.unknown]!,
      );
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
      );
  }

  static ({String status, Color color}) _mapAirQualityToUnifiedStatusInfo(
    int pmValue,
    String? grade,
  ) {
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
      }
    }
    if (pmValue <= 50)
      return (
        status: UnifiedStatus.low,
        color: UnifiedStatus.colors[UnifiedStatus.low]!,
      );
    else if (pmValue <= 100)
      return (
        status: UnifiedStatus.moderate,
        color: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      );
    else if (pmValue <= 250)
      return (
        status: UnifiedStatus.high,
        color: UnifiedStatus.colors[UnifiedStatus.high]!,
      );
    else
      return (
        status: UnifiedStatus.veryHigh,
        color: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
      );
  }

  static ({String status, Color color}) _mapDummyStatusToUnified(
    String dummyStatus,
  ) {
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

  static List<HourlyWeatherUI> mapHourlyWeatherToUI(
    WeatherDetailResponse? apiData,
  ) {
    if (apiData?.weatherHourList?.hourly == null ||
        apiData!.weatherHourList!.hourly.isEmpty) {
      return [];
    }

    final List<HourlyWeatherUI> hourlyWeatherList = [];
    // API 응답에서 최대 12개 항목만 사용
    final itemsToProcess = apiData.weatherHourList!.hourly.take(12).toList();

    for (var item in itemsToProcess) {
      String displayTime;
      try {
        final dateTime = DateFormat('yyyyMMddHH').parse(item.date);
        displayTime = DateFormat('HH시').format(dateTime);
        if (dateTime.hour == 0) {
          displayTime = '자정';
        } else if (dateTime.hour == 12) {
          displayTime = '정오';
        }
      } catch (e) {
        displayTime = item.date.substring(8) + '시';
        print("Error parsing date from hourly weather: ${item.date} - $e");
      }

      String mainWeatherApi = item.main; // API에서 받은 main 값 (예: "Clouds")
      String lookupKey = "Default";
      String statusText = "정보 없음"; // 기본 상태 텍스트

      if (mainWeatherApi.isNotEmpty) {
        // 아이콘 및 색상 매핑용 키 (첫 글자 대문자)
        String capitalizedMainWeather =
            mainWeatherApi[0].toUpperCase() +
            mainWeatherApi.substring(1).toLowerCase();
        if (_weatherIconMap.containsKey(capitalizedMainWeather)) {
          lookupKey = capitalizedMainWeather;
        }
        // 상태 텍스트 매핑 (이미 첫 글자 대문자로 되어 있는 _weatherDescriptionMap 키 사용)
        statusText =
            _weatherDescriptionMap[capitalizedMainWeather] ??
            capitalizedMainWeather;
      }
      final iconInfo =
          _weatherIconMap[lookupKey] ?? _weatherIconMap['Default']!;

      String? precipitationProbability;
      if (item.main.toLowerCase() == 'rain' && item.pop > 0) {
        precipitationProbability = '${(item.pop * 100).toStringAsFixed(0)}%';
      }

      hourlyWeatherList.add(
        HourlyWeatherUI(
          time: displayTime,
          // statusText: statusText, // <<< 한글 상태 텍스트 전달
          weatherIcon: iconInfo.icon,
          weatherIconColor: iconInfo.color,
          temperature: '${item.temp.toStringAsFixed(0)}°',
          precipitationProbability: precipitationProbability,
        ),
      );
    }
    return hourlyWeatherList;
  }
}
