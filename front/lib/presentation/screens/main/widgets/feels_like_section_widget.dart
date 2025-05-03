import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/main_screen/feels_like_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
// import '../main_screen.dart'; // _buildSectionTitle, _buildDataErrorPlaceholder 사용 위해

class FeelsLikeSectionWidget extends ConsumerWidget {
  const FeelsLikeSectionWidget({
    super.key,
    required this.buildSectionTitle, // MainScreen의 함수를 전달받음
    required this.buildDataErrorPlaceholder, // MainScreen의 함수를 전달받음
  });

  // MainScreen에서 정의된 함수들을 전달받기 위한 final 변수
  final Widget Function(BuildContext, String, {bool showInfoIcon})
  buildSectionTitle;
  final Widget Function(String) buildDataErrorPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelsLikeDataUI =
        ref.watch(mainScreenNotifierProvider).feelsLikeDataUI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(context, '체감온도'), // 전달받은 함수 사용
        const SizedBox(height: 10),
        if (feelsLikeDataUI != null)
          FeelsLikeCard(feelsLikeData: feelsLikeDataUI)
        else
          buildDataErrorPlaceholder('체감온도 정보를 불러올 수 없습니다.'), // 전달받은 함수 사용
        const SizedBox(height: 24),
      ],
    );
  }
}
