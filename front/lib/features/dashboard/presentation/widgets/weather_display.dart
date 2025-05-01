// lib/features/dashboard/presentation/widgets/weather_display.dart
import 'package:flutter/material.dart';
import '../../../../models/weather_data.dart';
import 'weather_avatar.dart'; // 날씨 아바타 위젯 import

class WeatherDisplay extends StatelessWidget {
  final WeatherDetailResponse? weatherData;

  const WeatherDisplay({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    if (weatherData == null || weatherData?.error != null) {
      // 데이터가 없거나 오류가 있을 경우 표시
      return const Card(
        child: ListTile(
          leading: Icon(Icons.error_outline),
          title: Text('날씨 정보 오류'),
          subtitle: Text('날씨 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    final condition = weatherData!.weatherCondition;
    final measurements = weatherData!.measurements;

    return Card(
      // 정보를 카드 형태로 감싸기
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 날씨 아바타
            WeatherAvatar(condition: condition, size: 60),
            const SizedBox(width: 16),
            // 날씨 정보 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 온도 표시 (null 체크 및 소수점 처리)
                    '${measurements.temp?.toStringAsFixed(1) ?? '-'}°C',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // 날씨 설명 표시 (null 체크)
                    condition.description ?? '날씨 정보 없음',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  // 필요시 체감 온도 등 추가 정보 표시
                  // Text('체감 온도: ${measurements.feelsLike?.toStringAsFixed(1) ?? '-'}°C'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
