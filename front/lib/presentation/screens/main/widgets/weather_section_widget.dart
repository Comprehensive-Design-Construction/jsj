import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/main_screen/weather_info_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
import '../main_screen.dart'; // _buildDataErrorPlaceholder 사용 위해 import

class WeatherSectionWidget extends ConsumerWidget {
  const WeatherSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeatherUI =
        ref.watch(mainScreenNotifierProvider).weatherDataUI;

    // _buildDataErrorPlaceholder를 사용하기 위해 MainScreen 인스턴스 생성 (비효율적일 수 있음)
    // 또는 해당 함수를 static으로 만들거나 별도 유틸리티로 분리하는 것이 더 좋음
    // 여기서는 임시로 MainScreen의 함수를 호출 가능한 방식으로 접근
    // final mainScreenInstance = const MainScreen(); // 이렇게 하면 안됨. 함수를 옮기거나 static으로.

    // 임시 해결: 에러 플레이스홀더 위젯 직접 정의
    Widget buildErrorPlaceholder(String message) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        if (currentWeatherUI != null)
          WeatherInfoCard(weatherData: currentWeatherUI)
        else
          buildErrorPlaceholder('날씨 정보를 불러올 수 없습니다.'),
        const SizedBox(height: 24),
      ],
    );
  }
}
