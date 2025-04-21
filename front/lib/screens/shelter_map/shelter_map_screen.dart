// lib/screens/shelter_map/shelter_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/location_provider.dart'; // 위치 정보 사용 위해
import '../loading_error/loading_indicator.dart';
import '../loading_error/error_message.dart';
import 'widgets/shelter_map_section.dart'; // 지도 섹션 위젯 import

class ShelterMapScreen extends ConsumerWidget {
  const ShelterMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 대피소 지도 표시에 현재 위치 정보가 필요하므로 locationProvider watch
    final locationAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('주변 대피소 찾기')),
      // 위치 정보 상태에 따라 UI 분기
      body: locationAsync.when(
        loading: () => const LoadingIndicator(),
        error:
            (err, stack) => ErrorMessage(
              message: '대피소 지도를 표시하기 위해 현재 위치를 가져올 수 없습니다.\n$err',
              onRetry: () => ref.invalidate(currentPositionProvider),
            ),
        // 위치 정보 로딩 성공 시 지도 섹션 표시
        data: (position) {
          // ShelterMapSection 위젯에 현재 위치 정보는 내부적으로 provider를 통해 전달되므로
          // 여기서는 별도 전달 필요 없음 (필요하다면 파라미터로 전달 가능)
          return const SingleChildScrollView(
            // 내용 길어질 수 있으므로 스크롤 가능하게
            padding: EdgeInsets.all(16.0),
            child: ShelterMapSection(), // 지도 선택 및 표시 위젯
          );
        },
      ),
    );
  }
}
