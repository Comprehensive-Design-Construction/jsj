// lib/presentation/widgets/main_screen/hourly_weather_card.dart
import 'package:flutter/material.dart';
import '../../../data/models/ui/hourly_weather_ui.dart';

class HourlyWeatherCard extends StatelessWidget {
  final HourlyWeatherUI hourlyWeather;

  const HourlyWeatherCard({Key? key, required this.hourlyWeather})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      width: 65, // 너비를 약간 늘려 텍스트 공간 확보
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hourlyWeather.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6), // 간격 조절
          // Text(
          //   // <<< 날씨 상태 텍스트 추가
          //   // hourlyWeather.statusText,
          //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //     fontSize: 12, // 시간 텍스트보다 약간 작게
          //     color: Colors.grey[600],
          //   ),
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis, // 길 경우 ... 처리
          // ),
          const SizedBox(height: 6), // 간격 조절
          Icon(
            hourlyWeather.weatherIcon,
            color: hourlyWeather.weatherIconColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          if (hourlyWeather.precipitationProbability != null)
            Text(
              hourlyWeather.precipitationProbability!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            hourlyWeather.temperature,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
