import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/main_screen/feels_like_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
// --- 공용 위젯 import ---
import '../../../widgets/common/section_title_widget.dart';
import '../../../widgets/common/data_error_placeholder_widget.dart';
// ---------------------

class FeelsLikeSectionWidget extends ConsumerWidget {
  const FeelsLikeSectionWidget({super.key});

  // --- buildSectionTitle, buildDataErrorPlaceholder 파라미터 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelsLikeDataUI =
        ref.watch(mainScreenNotifierProvider).feelsLikeDataUI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 공용 위젯 사용 ---
        const SectionTitleWidget(title: '체감온도'),
        const SizedBox(height: 10),
        if (feelsLikeDataUI != null)
          FeelsLikeCard(feelsLikeData: feelsLikeDataUI)
        else
          // --- 공용 위젯 사용 ---
          const DataErrorPlaceholderWidget(message: '체감온도 정보를 불러올 수 없습니다.'),
        const SizedBox(height: 24),
      ],
    );
  }
}
