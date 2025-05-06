import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart'; // defaultMajorIndices 사용
import '../../../../data/models/ui/health_index.dart';
import '../../../widgets/main_screen/health_index_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
// --- 공용 위젯 import ---
import '../../../widgets/common/section_title_widget.dart';
import '../../../widgets/common/data_error_placeholder_widget.dart';
// ---------------------

class MajorHealthIndicesWidget extends ConsumerWidget {
  const MajorHealthIndicesWidget({super.key});

  // --- buildSectionTitle, buildDataErrorPlaceholder 파라미터 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final allMappedIndices = state.healthIndicesUI;
    final visibleNames = state.visibleIndices;

    // 보이는 지수 중에서 '주요 지수' 목록 필터링
    final List<HealthIndex> visibleMajorIndices =
        allMappedIndices
            .where(
              (index) =>
                  visibleNames.contains(index.name) &&
                  defaultMajorIndices.contains(index.name),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 공용 위젯 사용 (showInfoIcon: true 전달) ---
        const SectionTitleWidget(title: '주요 건강 지수', showInfoIcon: true),
        const SizedBox(height: 10),
        if (visibleMajorIndices.isEmpty)
          // --- 공용 위젯 사용 ---
          const DataErrorPlaceholderWidget(
            message: '표시할 주요 건강 지수가 없거나\n선택된 지수가 없습니다.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleMajorIndices.length,
            itemBuilder: (context, index) {
              return HealthIndexCard(
                healthIndex: visibleMajorIndices[index],
                showProgressBar: true,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
