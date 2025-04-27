// lib/models/common/weather_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_helpers.dart'; // _parseDouble import

part 'weather_data.freezed.dart';
part 'weather_data.g.dart';

@freezed
class WeatherData with _$WeatherData {
  const factory WeatherData({
    @JsonKey(fromJson: parseDouble) double? temperature, // 현재 온도
    @JsonKey(fromJson: parseDouble) double? pressure, // 기압
    @JsonKey(fromJson: parseDouble) double? humidity, // 습도
    @JsonKey(fromJson: parseDouble) double? windSpeed, // 풍속
    @JsonKey(fromJson: parseDouble) double? tempMin, // 최저 온도
    @JsonKey(fromJson: parseDouble) double? tempMax, // 최고 온도
    String?
    description, // 날씨 설명 (예: "Clear sky", "Rain") - !!! API 응답 키 확인 필요 !!!
    String?
    mainCondition, // 주 날씨 상태 (예: "Clear", "Rain", "Clouds") - !!! API 응답 키 확인 필요 !!!
    String? icon, // 날씨 아이콘 코드 (OpenWeatherMap 등) - !!! API 응답 키 확인 필요 !!!
    String? city, // 도시 이름
    String? error, // 날씨 API 오류 시 메시지
  }) = _WeatherData;

  factory WeatherData.fromJson(Map<String, dynamic> json) =>
      _$WeatherDataFromJson(json);
}
