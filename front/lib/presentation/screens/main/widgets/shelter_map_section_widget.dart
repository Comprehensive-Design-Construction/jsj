import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart'; // WebView 관련 import 유지

import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
import '../main_screen_state.dart'; // MainScreenState 사용
// --- 공용 위젯 import ---
import '../../../widgets/common/section_title_widget.dart';
import '../../../widgets/common/map_type_dropdown_widget.dart';
import '../../../widgets/common/webview_map_widget.dart';
// ---------------------

class ShelterMapSectionWidget extends ConsumerWidget {
  const ShelterMapSectionWidget({
    super.key,
    required this.disasterTypes, // 지도 타입 정보는 계속 받음
  });

  final Map<String, String> disasterTypes;
  // --- buildSectionTitle, buildMapTypeDropdown, buildWebViewMap 파라미터 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 공용 위젯 사용 ---
        const SectionTitleWidget(title: '대피소 위치'),
        const SizedBox(height: 10),
        // --- 공용 위젯 사용 ---
        MapTypeDropdownWidget(
          mapTypes: disasterTypes,
          selectedValue: state.selectedDisasterType,
          isLoading: state.isLoading, // 로딩 상태 전달
          onChanged: (v) => notifier.setSelectedDisasterType(v!),
        ),
        const SizedBox(height: 10),
        // --- 공용 위젯 사용 ---
        WebViewMapWidget(
          controller: state.shelterMapControllers[state.selectedDisasterType],
          placeholderIcon: Icons.pin_drop_outlined,
          placeholderText:
              '${disasterTypes[state.selectedDisasterType] ?? "대피소"} 지도 로딩 중...',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
