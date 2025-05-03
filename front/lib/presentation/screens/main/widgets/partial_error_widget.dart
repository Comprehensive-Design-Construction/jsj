import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용

class PartialErrorWidget extends ConsumerWidget {
  const PartialErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);

    // 데이터가 일부라도 있고, 에러 메시지가 있을 경우에만 표시
    if (state.errorMessage != null && state.weatherDataUI != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), // 하단 간격 추가
        child: Text(
          '일부 데이터 로딩 실패:\n${state.errorMessage}',
          style: TextStyle(color: Colors.orange[800], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const SizedBox.shrink(); // 조건 만족 안 하면 빈 위젯 반환
    }
  }
}
