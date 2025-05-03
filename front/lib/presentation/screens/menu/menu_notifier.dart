import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart'; // availableHealthIndices 사용
import '../../../core/utils/preferences_service.dart'; // PreferencesService 사용
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider 사용 위해
import 'menu_state.dart';

class MenuNotifier extends StateNotifier<MenuState> {
  final PreferencesService _prefsService;

  MenuNotifier(this._prefsService) : super(const MenuState()) {
    _loadVisibleIndices(); // 생성 시 로드
  }

  // 저장된 보이는 지수 목록 불러오기
  Future<void> _loadVisibleIndices() async {
    state = state.copyWith(isLoading: true);
    try {
      Set<String>? savedIndices = await _prefsService.getVisibleIndices();
      // 저장된 값이 없으면 기본값(모든 지수) 사용
      final initialVisible = savedIndices ?? availableHealthIndices.toSet();
      state = state.copyWith(visibleIndices: initialVisible, isLoading: false);
      print("MenuNotifier: Visible indices loaded: $initialVisible");
    } catch (e) {
      print("MenuNotifier: Error loading visible indices: $e");
      // 오류 발생 시 기본값으로 설정하거나 에러 상태 추가 가능
      state = state.copyWith(
        visibleIndices: availableHealthIndices.toSet(),
        isLoading: false,
      );
    }
  }

  // 지수 보이기/숨기기 토글 및 저장
  Future<void> toggleIndexVisibility(String indexName) async {
    final currentVisible = Set<String>.from(state.visibleIndices); // 현재 Set 복사
    if (currentVisible.contains(indexName)) {
      currentVisible.remove(indexName);
    } else {
      currentVisible.add(indexName);
    }
    // 상태 즉시 업데이트 (UI 반응성)
    state = state.copyWith(visibleIndices: currentVisible);

    // 변경된 상태를 저장소에 저장
    try {
      await _prefsService.saveVisibleIndices(currentVisible);
      print("MenuNotifier: Saved visible indices: $currentVisible");
    } catch (e) {
      print("MenuNotifier: Error saving visible indices: $e");
      // 저장 실패 시 사용자에게 알림 또는 롤백 로직 추가 가능
    }
  }
}

// --- Provider 정의 ---
final menuNotifierProvider = StateNotifierProvider<MenuNotifier, MenuState>((
  ref,
) {
  return MenuNotifier(
    ref.read(
      preferencesServiceProvider,
    ), // main_screen_notifier.dart의 Provider 재사용
  );
});
