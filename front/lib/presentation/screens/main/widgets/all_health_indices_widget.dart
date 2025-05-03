import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/ui/health_index.dart';
import '../../../widgets/main_screen/health_index_card.dart'; // 기존 위젯 사용
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용

class AllHealthIndicesWidget extends ConsumerWidget {
  const AllHealthIndicesWidget({
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

    // 보이는 지수 필터링
    final List<HealthIndex> filteredHealthIndices =
        allMappedIndices
            .where((index) => visibleNames.contains(index.name))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(
          context,
          '전체 건강 지수',
          showInfoIcon: false,
        ), // INFO 아이콘 필요 여부 확인
        const SizedBox(height: 10),
        if (filteredHealthIndices.isEmpty)
          buildDataErrorPlaceholder('표시할 건강 지수가 선택되지 않았습니다.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredHealthIndices.length,
            itemBuilder: (context, index) {
              return HealthIndexCard(
                healthIndex: filteredHealthIndices[index],
                showProgressBar: false, // 전체 목록에서는 프로그레스 바 숨김
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
