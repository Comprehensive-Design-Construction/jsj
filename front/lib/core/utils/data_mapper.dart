import 'package:flutter/material.dart';

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

class DataMapper {
  // --- 날씨 정보 매핑 ---
  static CurrentWeather mapWeatherResponseToUI(
    WeatherDetailResponse apiData,
    RegionInfo? regionInfo,
  ) {
    // 옷차림 및 아바타 결정 로직 (임시)
    // TODO: 날씨 상태(description), 온도 등을 고려한 실제 로직 구현 필요
    String recommendation = "날씨 확인 중...";
    String avatarImageAsset = 'assets/images/man_1.png'; // 기본 아바타 (경로 수정)
    double currentTemp = apiData.measurements?.temp ?? 0.0;

    // --- 온도 기반 추천 및 아바타 (개선) ---
    if (apiData.measurements?.temp != null) {
      currentTemp = apiData.measurements!.temp!;
      if (currentTemp >= 28) {
        recommendation = "매우 더워요! 반팔, 반바지가 좋겠어요.";
        avatarImageAsset = 'assets/images/man_halfT.png'; // 더울 때 아바타 (경로 수정)
      } else if (currentTemp >= 20) {
        recommendation = "따뜻한 날씨네요. 가벼운 옷차림이 좋아요.";
        avatarImageAsset =
            'assets/images/man_shirt.png'; // 따뜻할 때 아바타 (경로 수정, 에셋 필요)
      } else if (currentTemp >= 10) {
        recommendation = "쌀쌀해요. 겉옷을 챙기세요.";
        avatarImageAsset =
            'assets/images/man_jacket.png'; // 쌀쌀할 때 아바타 (경로 수정, 에셋 필요)
      } else {
        recommendation = "추워요! 따뜻하게 입으세요.";
        avatarImageAsset =
            'assets/images/man_padding.png'; // 추울 때 아바타 (경로 수정, 에셋 필요)
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

  // --- 체감 온도 정보 매핑 ---
  static FeelsLikeData mapFeelsLikeResponseToUI(
    HealthIndexResponse apiResponse,
  ) {
    // HealthIndexResponse 전체를 받는 것이 더 유연할 수 있음
    IndexCalculationResult? apiIndexData = apiResponse.indices;

    double temperature = apiIndexData?.apparentTemperature ?? 0.0;
    String status = "정보 없음";
    Color statusColor = Colors.grey;
    String message1 = "체감 온도 정보를 확인하세요.";
    String message2 = "";
    String buttonText = "관련 정보 보기"; // 기본 버튼 텍스트

    // 상태 및 색상 매핑
    // TODO: '일반인' 등급 처리 및 메시지 구체화 논의 필요
    switch (apiIndexData?.apparentTempRiskStatus) {
      case "위험":
        status = "위험";
        statusColor = Colors.red; // '매우 높음' 색상
        message1 = "매우 높은 체감 온도! 건강에 유의하세요.";
        message2 = "야외 활동을 자제하고 수분을 충분히 섭취하세요.";
        // buttonText = "폭염 대피소 찾기"; // TODO: 기능 확정 후 연결
        break;
      case "경고":
        status = "경고";
        statusColor =
            Colors.redAccent; // '높음' 색상 (사용자 정의 필요, 일단 RedAccent) -> 노랑으로 변경
        statusColor = Colors.yellow.shade700;
        message1 = "높은 체감 온도! 주의가 필요합니다.";
        message2 = "물을 자주 마시고, 더위에 지치지 않도록 주의하세요.";
        // buttonText = "더위 쉼터 정보";
        break;
      case "주의":
        status = "주의";
        statusColor = Colors.blue; // '보통' 색상
        message1 = "체감 온도가 다소 높습니다.";
        message2 = "수분 섭취에 신경 쓰고, 무리한 활동은 피하세요.";
        // buttonText = "오늘의 날씨 정보 더보기";
        break;
      case "관심":
        status = "관심";
        statusColor = Colors.green; // '낮음' 색상
        message1 = "체감 온도를 주시할 필요가 있습니다.";
        message2 = "상황에 맞게 옷차림을 조절하세요.";
        break;
      case "일반인": // TODO: '일반인' 등급 처리 논의 필요
        status = "보통"; // 임시로 '보통'으로 매핑
        statusColor = Colors.blue; // '보통' 색상
        message1 = "적절한 체감 온도입니다.";
        message2 = "활동하기 좋은 날씨입니다.";
        break;
      default:
        status = apiIndexData?.apparentTempRiskStatus ?? "정보 없음";
        statusColor = Colors.grey; // 기본 회색
        break;
    }

    return FeelsLikeData(
      temperature: temperature,
      status: status,
      statusColor: statusColor,
      message1: message1,
      message2: message2,
      buttonText: buttonText, // TODO: 버튼 기능 확정 필요
    );
  }

  // --- 건강 지수 리스트 매핑 ---
  static List<HealthIndex> mapHealthIndicesResponseToUI(
    HealthIndexResponse? apiIndexResponse, // 전체 응답 받기
    SingleRegionUvResponse? uvData,
    SingleRegionFineDustResponse? fineDustData,
  ) {
    final List<HealthIndex> indices = [];
    if (apiIndexResponse == null) return indices; // 기본 지수 데이터 없으면 빈 리스트 반환

    final apiIndexData = apiIndexResponse.indices; // 실제 지수 데이터 접근

    // --- API 응답 데이터를 UI용 HealthIndex 객체로 변환 ---

    // 1. 천식/폐질환 (ALI)
    if (apiIndexData.aliLevel != null) {
      var mapped = _mapLevelToStatusInfo(apiIndexData.aliLevel!);
      Color iconBackgroundColor =
          Color.lerp(mapped.color, Colors.white, 0.8) ??
          mapped.color.withOpacity(0.1);
      indices.add(
        HealthIndex(
          name: '천식질환 지수',
          value: apiIndexData.aliScore ?? apiIndexData.aliLevel!.toDouble(),
          status: mapped.status,
          icon: Icons.masks, // 아이콘 확인
          iconColor: iconBackgroundColor,
          statusColor: mapped.color,
        ),
      );
    }

    // 2. 뇌졸중 (Stroke) - API 모델명 확인: stroke_index_level
    if (apiIndexData.strokeIndexLevel != null) {
      var mapped = _mapLevelToStatusInfo(apiIndexData.strokeIndexLevel!);
      Color iconBackgroundColor =
          Color.lerp(mapped.color, Colors.white, 0.8) ??
          mapped.color.withOpacity(0.1);
      indices.add(
        HealthIndex(
          name: '심뇌혈관질환 지수', // UI 이름 확인
          value:
              apiIndexData.strokeIndexScore ??
              apiIndexData.strokeIndexLevel!.toDouble(),
          status: mapped.status,
          icon: Icons.monitor_heart_outlined, // 아이콘 확인
          iconColor: iconBackgroundColor,
          statusColor: mapped.color,
        ),
      );
    }

    // 3. 감기 (Cold) - API 모델명 확인: cold_index_level
    if (apiIndexData.coldIndexLevel != null) {
      var mapped = _mapLevelToStatusInfo(apiIndexData.coldIndexLevel!);
      Color iconBackgroundColor =
          Color.lerp(mapped.color, Colors.white, 0.8) ??
          mapped.color.withOpacity(0.1);
      indices.add(
        HealthIndex(
          name: '감기가능 지수',
          value:
              apiIndexData.coldIndexScore ??
              apiIndexData.coldIndexLevel!.toDouble(),
          status: mapped.status,
          icon: Icons.sick, // 아이콘 확인
          iconColor: iconBackgroundColor,
          statusColor: mapped.color,
        ),
      );
    }

    // 4. 식중독 (Food Poisoning)
    if (apiIndexData.foodPoisoningRisk != null) {
      var mapped = _mapFoodPoisoningRiskToStatusInfo(
        apiIndexData.foodPoisoningRisk!,
      );
      Color iconBackgroundColor =
          Color.lerp(mapped.color, Colors.white, 0.8) ??
          mapped.color.withOpacity(0.1);
      double parsedValue =
          double.tryParse(apiIndexData.foodPoisoningIndex ?? '0.0') ?? 0.0;

      indices.add(
        HealthIndex(
          name: '식중독 지수',
          value: parsedValue,
          status: mapped.status,
          icon: Icons.fastfood, // 아이콘 확인
          iconColor: iconBackgroundColor,
          statusColor: mapped.color,
        ),
      );
    }

    // 5. UV 지수 (별도 API 응답 사용)
    if (uvData?.uvData?.uvIndex != null) {
      int uvValue = uvData!.uvData!.uvIndex!;
      var mapped = _mapUvIndexToStatusInfo(uvValue);
      Color iconBackgroundColor =
          Color.lerp(mapped.color, Colors.white, 0.8) ??
          mapped.color.withOpacity(0.1);
      indices.add(
        HealthIndex(
          name: '자외선 지수',
          value: uvValue.toDouble(),
          status: mapped.status,
          icon: Icons.wb_sunny_outlined, // 아이콘 확인
          iconColor: iconBackgroundColor,
          statusColor: mapped.color,
        ),
      );
    }

    // 6. 미세먼지 지수 (별도 API 응답 사용)
    if (fineDustData?.fineDustData != null) {
      // PM10 값을 우선 사용하고, 없으면 PM2.5 값을 사용 (예시)
      // TODO: 기준값 논의 필요 (PM10? PM2.5? 통합지수? GRADE?)
      var pmValue =
          fineDustData!.fineDustData!.pm10 ?? fineDustData!.fineDustData!.pm25;
      var grade = fineDustData!.fineDustData!.grade; // API에서 제공하는 등급

      if (pmValue != null) {
        var mapped = _mapAirQualityToStatusInfo(pmValue, grade); // 값과 등급 모두 활용
        Color iconBackgroundColor =
            Color.lerp(mapped.color, Colors.white, 0.8) ??
            mapped.color.withOpacity(0.1);
        indices.add(
          HealthIndex(
            name: '미세먼지 지수', // TODO: 어떤 기준인지 명시?
            value: pmValue.toDouble(),
            status: mapped.status,
            icon: Icons.blur_linear_rounded, // 아이콘 확인
            iconColor: iconBackgroundColor,
            statusColor: mapped.color,
          ),
        );
      }
    }

    // 7. 꽃가루 지수 (소나무) - API 없음, 임시 더미 데이터
    // TODO: 실제 데이터 연동 또는 제거
    indices.add(
      HealthIndex(
        name: '꽃가루농도 지수(소나무)',
        value: 66,
        status: '나쁨', // '높음' 수준
        icon: Icons.local_florist,
        iconColor: Colors.yellow.shade100,
        statusColor: Colors.yellow.shade700,
      ),
    );

    // 8. 대기 정체 지수 - API 없음, 임시 더미 데이터
    // TODO: 실제 데이터 연동 또는 제거
    indices.add(
      HealthIndex(
        name: '대기정체 지수',
        value: 27,
        status: '보통', // '보통' 수준
        icon: Icons.landscape_outlined,
        iconColor: Colors.blue.shade100,
        statusColor: Colors.blue,
      ),
    );

    // TODO: 지수 순서 정렬 로직 추가 (예: 특정 순서대로 표시)
    // 예시: 원하는 순서 리스트 정의 후 정렬
    // final displayOrder = ['체감 온도', '미세먼지 지수', '자외선 지수', ...];
    // indices.sort((a, b) => displayOrder.indexOf(a.name).compareTo(displayOrder.indexOf(b.name)));

    return indices;
  }

  // --- Helper 함수들 ---

  // 숫자 레벨(1:매우높음 ~ 4:낮음)을 상태 문자열 및 색상으로 변환
  // 낮음(4)->초록, 보통(3)->파랑, 높음(2)->노랑, 매우높음(1)->빨강
  static ({String status, Color color}) _mapLevelToStatusInfo(int level) {
    switch (level) {
      case 1:
        return (status: '매우 높음', color: Colors.red);
      case 2:
        return (status: '높음', color: Colors.yellow.shade700);
      case 3:
        return (status: '보통', color: Colors.blue);
      case 4:
        return (status: '낮음', color: Colors.green);
      default:
        return (status: '정보 없음', color: Colors.grey);
    }
  }

  // 식중독 위험도 문자열을 상태 및 색상으로 변환
  // 위험->빨강, 경고->노랑, 주의->파랑, 관심->초록
  static ({String status, Color color}) _mapFoodPoisoningRiskToStatusInfo(
    String risk,
  ) {
    switch (risk) {
      case '위험':
        return (status: '위험', color: Colors.red);
      case '경고':
        return (status: '경고', color: Colors.yellow.shade700);
      case '주의':
        return (status: '주의', color: Colors.blue);
      case '관심':
        return (status: '관심', color: Colors.green);
      default:
        return (status: risk, color: Colors.grey);
    }
  }

  // UV 지수 값을 상태 및 색상으로 변환 (WHO 기준 + 사용자 색상 규칙 적용)
  // 낮음->초록, 보통->파랑, 높음->노랑, 매우높음->빨강, 위험->보라
  static ({String status, Color color}) _mapUvIndexToStatusInfo(int uvIndex) {
    if (uvIndex <= 2) return (status: '낮음', color: Colors.green);
    if (uvIndex <= 5) return (status: '보통', color: Colors.blue);
    if (uvIndex <= 7) return (status: '높음', color: Colors.yellow.shade700);
    if (uvIndex <= 10) return (status: '매우 높음', color: Colors.red);
    return (status: '위험', color: Colors.purple); // 11 이상
  }

  // 미세먼지(PM10) 값과 등급(GRADE)을 상태 및 색상으로 변환 (한국 기준 + 사용자 색상 규칙)
  // 좋음->초록, 보통->파랑, 나쁨->노랑, 매우나쁨->빨강
  // TODO: GRADE 문자열 활용 방안 검토 (예: 상태 문자열로 GRADE 직접 사용?)
  static ({String status, Color color}) _mapAirQualityToStatusInfo(
    int pmValue,
    String? grade,
  ) {
    // GRADE 문자열 우선 사용 (API 응답 신뢰)
    String statusText = grade ?? "정보 없음"; // 등급 없으면 값 기준으로 판단
    Color statusColor = Colors.grey;

    if (grade != null) {
      switch (grade) {
        case "좋음":
          statusColor = Colors.green;
          break; // 좋음 -> 초록 ('낮음' 색)
        case "보통":
          statusColor = Colors.blue;
          break; // 보통 -> 파랑 ('보통' 색)
        case "나쁨":
          statusColor = Colors.yellow.shade700;
          break; // 나쁨 -> 노랑 ('높음' 색)
        case "매우나쁨":
          statusColor = Colors.red;
          break; // 매우나쁨 -> 빨강 ('매우 높음' 색)
        default:
          statusColor = Colors.grey;
          break;
      }
    } else {
      // 등급 정보 없을 때 PM 값 기준으로 판단 (예시)
      if (pmValue <= 30) {
        statusText = '좋음';
        statusColor = Colors.green;
      } else if (pmValue <= 80) {
        statusText = '보통';
        statusColor = Colors.blue;
      } else if (pmValue <= 150) {
        statusText = '나쁨';
        statusColor = Colors.yellow.shade700;
      } else {
        statusText = '매우 나쁨';
        statusColor = Colors.red;
      }
    }
    return (status: statusText, color: statusColor);
  }
}
