import 'package:flutter/material.dart';
import '../../../data/models/ui/current_weather.dart'; // 경로 수정

class WeatherInfoCard extends StatelessWidget {
  final CurrentWeather weatherData;
  const WeatherInfoCard({Key? key, required this.weatherData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // (CurrentWeather 모델 경로 수정)
    // currentTemp, maxTemp, minTemp 표시 시 double? 처리 및 포매팅 추가
    // 예: '${weatherData.currentTemp?.toStringAsFixed(0) ?? 'N/A'}°'
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // --- 왼쪽 영역 (아바타, 옷차림 추천) ---
            Expanded(
              /* ... (기존 코드와 동일) ... */
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 200, // 크기 조절
                    child: Image.asset(
                      weatherData.avatarImageAsset,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.person_outline_rounded,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      weatherData.recommendation,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.3),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            // --- 세로 구분선 ---
            Container(
              width: 1,
              color: Colors.grey[200],
              margin: EdgeInsets.symmetric(vertical: 12.0),
            ),
            // --- 오른쪽 영역 (날씨 아이콘, 설명, 온도) ---
            Expanded(
              /* ... (기존 코드와 동일, 온도 표시 부분 수정) ... */
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 8),
                  Row(
                    /* 날씨 아이콘 + 설명 */
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        weatherData.weatherIcon,
                        color: weatherData.weatherIconColor,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        weatherData.description,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // 현재 온도 (double? 표시 및 포매팅)
                  Text(
                    '${weatherData.currentTemp?.toStringAsFixed(0) ?? '--'}°', // 소수점 없이 표시
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 6),
                  // 최고/최저 온도 (double? 표시 및 포매팅)
                  Text(
                    '최고 ${weatherData.maxTemp?.toStringAsFixed(0) ?? '--'}° / 최저 ${weatherData.minTemp?.toStringAsFixed(0) ?? '--'}°',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
