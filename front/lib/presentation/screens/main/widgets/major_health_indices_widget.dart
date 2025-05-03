import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart'; // defaultMajorIndices 사용
import '../../../../data/models/ui/health_index.dart';
import '../../../widgets/main_screen/health_index_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용

class MajorHealthIndicesWidget extends ConsumerWidget {
  const MajorHealthIndicesWidget({
    super.key,
    required this.buildSectionTitle, // MainScreen의 함수를 전달받음
    required this.buildDataErrorPlaceholder, // MainScreen의 함수를 전달받음
  });

  final Widget Function(BuildContext, String, {bool showInfoIcon})
  buildSectionTitle;
  final Widget Function(String) buildDataErrorPlaceholder;

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
        buildSectionTitle(context, '주요 건강 지수', showInfoIcon: true),
        const SizedBox(height: 10),
        if (visibleMajorIndices.isEmpty)
          buildDataErrorPlaceholder('표시할 주요 건강 지수가 없거나\n선택된 지수가 없습니다.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleMajorIndices.length,
            itemBuilder: (context, index) {
              return HealthIndexCard(
                healthIndex: visibleMajorIndices[index],
                showProgressBar: true, // 주요 지수는 프로그레스 바 표시
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
