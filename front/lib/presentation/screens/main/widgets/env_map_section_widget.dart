import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
import '../main_screen_state.dart'; // MainScreenState 사용

class EnvMapSectionWidget extends ConsumerWidget {
  const EnvMapSectionWidget({
    super.key,
    required this.envMapTypes,
    required this.buildSectionTitle,
    required this.buildMapTypeDropdown,
    required this.buildWebViewMap,
  });

  final Map<String, String> envMapTypes;
  final Widget Function(BuildContext, String, {bool showInfoIcon})
  buildSectionTitle;
  final Widget Function({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, String> mapTypes,
    required String selectedValueKey,
    required Function(String?) onChangedCallback,
  })
  buildMapTypeDropdown;
  final Widget Function({
    required WebViewController? controller, // WebViewController? 타입
    required IconData placeholderIcon,
    required String placeholderText,
    // double height,
  })
  buildWebViewMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(context, '환경 지도'),
        const SizedBox(height: 10),
        buildMapTypeDropdown(
          context: context,
          ref: ref,
          mapTypes: envMapTypes,
          selectedValueKey: 'selectedEnvMapType',
          onChangedCallback: (v) => notifier.setSelectedEnvMapType(v!),
        ),
        const SizedBox(height: 10),
        buildWebViewMap(
          controller: state.envMapControllers[state.selectedEnvMapType],
          placeholderIcon: Icons.public,
          placeholderText:
              '${envMapTypes[state.selectedEnvMapType] ?? "환경"} 지도 로딩 중...',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
