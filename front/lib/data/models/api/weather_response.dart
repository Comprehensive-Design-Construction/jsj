/// 날씨 측정 정보 (WeatherMainInfo)
class WeatherMeasurements {
  final double? temp; // 현재 온도
  final double? feelsLike; // 체감 온도
  final double? tempMin; // 최저 온도
  final double? tempMax; // 최고 온도
  final double? pressure; // 기압
  final double? humidity; // 습도
  final double? windSpeed; // 풍속
  final int? windDeg; // 풍향 (각도)

  WeatherMeasurements({
    this.temp,
    this.feelsLike,
    this.tempMin,
    this.tempMax,
    this.pressure,
    this.humidity,
    this.windSpeed,
    this.windDeg,
  });

  factory WeatherMeasurements.fromJson(Map<String, dynamic> json) {
    // 숫자 타입 변환 시 as num? 사용 후 toDouble() 호출 (정수/실수 모두 처리)
    return WeatherMeasurements(
      temp: (json['temp'] as num?)?.toDouble(),
      feelsLike: (json['feels_like'] as num?)?.toDouble(),
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      tempMax: (json['temp_max'] as num?)?.toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      windDeg: json['wind_deg'] as int?, // 풍향은 정수형
    );
  }
}

/// 날씨 상태 정보 (WeatherCondition)
class WeatherCondition {
  final String? main; // 주 상태 (예: Clouds, Rain)
  final String? description; // 상세 설명 (예: broken clouds)
  final String? icon; // 날씨 아이콘 코드 (예: 04d) - 현재 앱에서는 사용 안 함

  WeatherCondition({this.main, this.description, this.icon});

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      main: json['main'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

/// 상세 날씨 API 응답 모델 (/api/weather)
class WeatherDetailResponse {
  // 요청 좌표 (키: 'latitude', 'longitude', 값: double)
  final Map<String, double>? requestLocation;
  final WeatherCondition? weatherCondition; // 날씨 상태
  final WeatherMeasurements? measurements; // 측정값
  final int? timestamp; // 데이터 시간 (Unix timestamp)
  final int? timezone; // 타임존 오프셋 (초)
  final String? error; // 오류 메시지

  WeatherDetailResponse({
    this.requestLocation,
    this.weatherCondition,
    this.measurements,
    this.timestamp,
    this.timezone,
    this.error,
  });

  factory WeatherDetailResponse.fromJson(Map<String, dynamic> json) {
    return WeatherDetailResponse(
      // Map<String, dynamic>을 Map<String, double>로 변환
      requestLocation: (json['request_location'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      // 중첩된 객체는 해당 객체의 fromJson 생성자 호출
      weatherCondition:
          json['weather_condition'] != null
              ? WeatherCondition.fromJson(json['weather_condition'])
              : null,
      measurements:
          json['measurements'] != null
              ? WeatherMeasurements.fromJson(json['measurements'])
              : null,
      timestamp: json['timestamp'] as int?,
      timezone: json['timezone'] as int?,
      error: json['error'] as String?,
    );
  }
}
