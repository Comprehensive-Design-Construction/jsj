import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/main_screen/weather_info_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
// --- 공용 위젯 import ---
import '../../../widgets/common/data_error_placeholder_widget.dart';
// ---------------------

class WeatherSectionWidget extends ConsumerWidget {
  const WeatherSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeatherUI =
        ref.watch(mainScreenNotifierProvider).weatherDataUI;

    // --- 임시 에러 플레이스홀더 로직 제거 ---

    return Column(
      children: [
        if (currentWeatherUI != null)
          WeatherInfoCard(weatherData: currentWeatherUI)
        else
          // --- 공용 위젯 사용 ---
          const DataErrorPlaceholderWidget(message: '날씨 정보를 불러올 수 없습니다.'),
        const SizedBox(height: 24),
      ],
    );
  }
}
