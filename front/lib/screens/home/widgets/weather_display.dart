// lib/screens/home/widgets/weather_display.dart
import 'package:flutter/material.dart';
import '../../../models/common/weather_data.dart'; // 실제 WeatherData 모델 import
import '../../../widgets/placeholder_image.dart';

class WeatherDisplayPlaceholder extends StatelessWidget {
  final String
  condition; // 날씨 상태 문자열 (예: "sunny", "rainy") - 실제 WeatherData에서 가져와야 함

  const WeatherDisplayPlaceholder({super.key, required this.condition});

  /// 날씨 상태에 따른 이미지 경로 반환
  String _getImagePathForCondition() {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return 'assets/images/placeholder_weather_sunny.png'; // TODO: 실제 이미지 파일 경로 확인
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return 'assets/images/placeholder_weather_rainy.png'; // TODO: 실제 이미지 파일 경로 확인
      case 'clouds':
      case 'cloudy':
        return 'assets/images/placeholder_weather_cloudy.png'; // TODO: 실제 이미지 파일 경로 확인
      // TODO: 다른 날씨 상태(눈, 안개 등)에 대한 이미지 경로 추가
      default:
        // 매칭되는 상태 없으면 기본 아이콘 경로 반환
        return 'assets/images/placeholder_icon_default.png'; // TODO: 실제 이미지 파일 경로 확인
    }
  }

  /// 날씨 상태에 따른 한글 설명 반환 (실제 WeatherData 설명 사용 권장)
  String _getWeatherDescription() {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '맑음';
      case 'rain':
      case 'drizzle':
        return '비';
      case 'thunderstorm':
        return '뇌우';
      case 'clouds':
      case 'cloudy':
        return '구름 많음';
      // TODO: 다른 날씨 상태 설명 추가
      default:
        return '날씨 정보';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 WeatherData 모델의 필드(온도, 습도 등)를 사용하여 UI 구성 필요
    // 현재는 상태 문자열 기반으로 아이콘과 설명만 표시
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        // color: Colors.grey.shade100, // 배경색 추가 (선택 사항)
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
        children: [
          // 날씨 상태 아이콘
          PlaceholderImage(imagePath: _getImagePathForCondition(), size: 48),
          const SizedBox(width: 16),
          // 날씨 설명 텍스트
          Text(
            _getWeatherDescription(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          // TODO: 여기에 온도, 습도 등 다른 날씨 정보 Text 위젯 추가
          // 예: Text('${weatherData.temperature}°C', style: ...),
        ],
      ),
    );
  }
}

/// 날씨 정보를 표시하는 위젯
class WeatherDisplay extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherDisplay({super.key, required this.weatherData});

  /// 날씨 상태 코드(mainCondition 또는 description)에 따른 아이콘 경로 반환
  String _getWeatherIconPath() {
    // OpenWeatherMap 아이콘 코드 사용 시 URL 생성 가능:
    // if (weatherData.icon != null) return 'https://openweathermap.org/img/wn/${weatherData.icon}@2x.png';

    // 여기서는 mainCondition 또는 description 기반으로 로컬 에셋 경로 반환
    final condition =
        weatherData.mainCondition?.toLowerCase() ??
        weatherData.description?.toLowerCase() ??
        "unknown";

    switch (condition) {
      case 'clear':
        return 'assets/images/placeholder_weather_sunny.png';
      case 'rain':
      case 'drizzle':
        return 'assets/images/placeholder_weather_rainy.png';
      case 'thunderstorm':
        return 'assets/images/placeholder_weather_rainy.png'; // 예시
      case 'clouds':
        return 'assets/images/placeholder_weather_cloudy.png';
      case 'snow':
        return 'assets/images/placeholder_weather_snowy.png'; // TODO: Add snowy image
      case 'mist':
      case 'fog':
      case 'haze':
        return 'assets/images/placeholder_weather_cloudy.png'; // 예시
      default:
        return 'assets/images/placeholder_icon_default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final temp = weatherData.temperature?.toStringAsFixed(1) ?? 'N/A';
    final description =
        weatherData.description ?? weatherData.mainCondition ?? '날씨 정보 없음';
    final minMaxTemp =
        (weatherData.tempMin != null && weatherData.tempMax != null)
            ? '${weatherData.tempMin?.toStringAsFixed(0)}° / ${weatherData.tempMax?.toStringAsFixed(0)}°'
            : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        // color: Colors.blueGrey.shade50, // 연한 배경색 (선택 사항)
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: Colors.grey.shade300) // 테두리 (선택 사항)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // 요소 간 간격 균등 분배
        children: [
          // 날씨 아이콘
          PlaceholderImage(imagePath: _getWeatherIconPath(), size: 56),
          const SizedBox(width: 16),
          // 현재 온도 및 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temp°C',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          // 최저/최고 온도 (있을 경우)
          if (minMaxTemp != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  minMaxTemp,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "최저/최고",
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          // TODO: 습도, 풍속 등 추가 정보 표시 영역 (선택 사항)
        ],
      ),
    );
  }
}
