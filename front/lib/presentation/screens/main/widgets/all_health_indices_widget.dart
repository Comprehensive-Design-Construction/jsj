import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/ui/health_index.dart';
import '../../../widgets/main_screen/health_index_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
// --- 공용 위젯 import ---
import '../../../widgets/common/section_title_widget.dart';
import '../../../widgets/common/data_error_placeholder_widget.dart';
// ---------------------

class AllHealthIndicesWidget extends ConsumerWidget {
  const AllHealthIndicesWidget({super.key});

  // --- buildSectionTitle, buildDataErrorPlaceholder 파라미터 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final allMappedIndices = state.healthIndicesUI;
    final visibleNames = state.visibleIndices;

    // 보이는 지수 필터링
    final List<HealthIndex> filteredHealthIndices =
        allMappedIndices
            .where((index) => visibleNames.contains(index.name))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 공용 위젯 사용 ---
        const SectionTitleWidget(title: '전체 건강 지수'),
        const SizedBox(height: 10),
        if (filteredHealthIndices.isEmpty)
          // --- 공용 위젯 사용 ---
          const DataErrorPlaceholderWidget(message: '표시할 건강 지수가 선택되지 않았습니다.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredHealthIndices.length,
            itemBuilder: (context, index) {
              return HealthIndexCard(
                healthIndex: filteredHealthIndices[index],
                showProgressBar: false,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
