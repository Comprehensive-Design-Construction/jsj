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
    // 로딩 시작 상태 업데이트 (선택적)
    if (!mounted) return;
    // state = state.copyWith(isLoading: true); // 필요시 활성화

    try {
      Set<String>? savedIndices = await _prefsService.getVisibleIndices();
      // `mounted` 확인: SharedPreferences 작업 후
      if (!mounted) return;

      // 저장된 값이 없으면 기본값(모든 지수) 사용
      final initialVisible = savedIndices ?? availableHealthIndices.toSet();
      state = state.copyWith(visibleIndices: initialVisible, isLoading: false);
      print("MenuNotifier: Visible indices loaded: $initialVisible");
    } catch (e) {
      print("MenuNotifier: Error loading visible indices: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      // 오류 발생 시 기본값으로 설정하거나 에러 상태 추가 가능
      state = state.copyWith(
        visibleIndices: availableHealthIndices.toSet(), // 오류 시 기본값
        isLoading: false,
        // errorMessage: "표시 지수 로드 오류: $e" // 필요 시 에러 메시지 상태 추가
      );
    }
  }

  // 지수 보이기/숨기기 토글 및 저장
  Future<void> toggleIndexVisibility(String indexName) async {
    // `mounted` 확인: 상태 변경 전
    if (!mounted) return;

    final currentVisible = Set<String>.from(state.visibleIndices); // 현재 Set 복사
    if (currentVisible.contains(indexName)) {
      currentVisible.remove(indexName);
    } else {
      currentVisible.add(indexName);
    }
    // 상태 즉시 업데이트 (UI 반응성)
    state = state.copyWith(visibleIndices: currentVisible);

    // 변경된 상태를 저장소에 저장 (비동기)
    try {
      await _prefsService.saveVisibleIndices(currentVisible);
      // `mounted` 확인: 저장 작업 후 (선택적 - 이후 상태 변경 없으므로)
      // if (!mounted) return;
      print("MenuNotifier: Saved visible indices: $currentVisible");
    } catch (e) {
      print("MenuNotifier: Error saving visible indices: $e");
      // 저장 실패 시 사용자에게 알림 또는 롤백 로직 추가 가능
      // if (mounted) {
      //   state = state.copyWith(errorMessage: "표시 지수 저장 실패: $e");
      // }
    }
  }
}

// --- Provider 정의 ---
final menuNotifierProvider = StateNotifierProvider<MenuNotifier, MenuState>((
  ref,
) {
  return MenuNotifier(ref.read(preferencesServiceProvider));
});
