import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart'; // fixedLatitude 등 사용

class WeatherSummarySection extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final Position? position;

  const WeatherSummarySection({
    super.key,
    required this.weatherData,
    required this.position,
  });

  // 날씨 상태에 따른 아이콘 반환 (예시)
  IconData _getWeatherIcon(String? description) {
    // 실제 날씨 설명(description) 값에 따라 아이콘 매핑 필요
    // 예: '맑음', '구름 많음', '비', '눈' 등
    // 백엔드에서 날씨 코드(e.g., OpenWeatherMap code)를 주면 더 정확하게 매핑 가능
    if (description == null) return Icons.wb_sunny; // 기본값
    if (description.contains('비')) return Icons.umbrella;
    if (description.contains('눈')) return Icons.ac_unit;
    if (description.contains('구름') || description.contains('흐림'))
      return Icons.cloud;
    return Icons.wb_sunny; // 기본: 맑음
  }

  @override
  Widget build(BuildContext context) {
    // 데이터가 없을 경우 빈 컨테이너 반환
    if (weatherData == null || position == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "날씨 정보를 불러올 수 없습니다.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    String currentTemp =
        weatherData!['temperature']?.toStringAsFixed(1) ?? 'N/A';
    String tempMin = weatherData!['temp_min']?.toStringAsFixed(1) ?? 'N/A';
    String tempMax = weatherData!['temp_max']?.toStringAsFixed(1) ?? 'N/A';
    String city = weatherData!['city'] ?? '위치 확인 불가';
    // 날씨 설명 (API 응답에 따라 키 이름 변경 필요)
    String description = weatherData!['description'] ?? '맑음';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.9), // 배경색 지정 (시안 유사)
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위치 정보
          Row(
            children: [
              Icon(Icons.location_pin, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                // "$city (${position!.latitude.toStringAsFixed(2)}, ${position!.longitude.toStringAsFixed(2)})",
                "$city (고정 위치)", // 고정 위치 사용 알림
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 온도 및 날씨 아이콘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$currentTemp°",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0, // 글자 높이 조절
                ),
              ),
              Icon(_getWeatherIcon(description), size: 60, color: Colors.white),
            ],
          ),
          SizedBox(height: 8),
          // 날씨 설명 및 최고/최저 온도
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                description, // 날씨 설명 표시
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              ),
              Text(
                "최고 $tempMax° / 최저 $tempMin°",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
