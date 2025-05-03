import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/preferences_service.dart';
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider 사용 위해
import 'onboarding_state.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferencesService _prefsService;

  OnboardingNotifier(this._prefsService) : super(const OnboardingState());

  // --- 상태 업데이트 함수 ---
  void setBirthDate(DateTime date) {
    state = state.copyWith(
      selectedBirthDate: date,
      errorMessage: null,
      clearErrorMessage: true,
    );
  }

  void toggleUserType(String type, bool value) {
    final currentSelection = Map<String, bool>.from(state.userTypeSelection);
    currentSelection[type] = value;
    state = state.copyWith(userTypeSelection: currentSelection);
  }

  // --- 로직 함수 ---

  // 나이 계산 (기존 로직)
  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  // "시작" 버튼 로직 (기존 로직 이전)
  Future<void> startApp(String? name /* 이름 필요시 전달 */) async {
    // 유효성 검사
    if (state.selectedBirthDate == null) {
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      final age = _calculateAge(state.selectedBirthDate);
      final selectedTypes =
          state.userTypeSelection.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      // TODO: 기저질환 리스트 가져오기
      final List<String> diseaseParam = [...selectedTypes /*, ...diseases*/];

      // 로컬 저장소에 정보 저장
      // TODO: 이름 저장 로직 추가 시 여기에 포함 (prefsService에 함수 추가 필요)
      await _prefsService.saveUserInfo(age: age, userTypes: diseaseParam);
      await _prefsService.setOnboardingComplete(); // 온보딩 완료 플래그 설정

      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print("OnboardingNotifier: Onboarding complete (with data).");
    } catch (e) {
      print("OnboardingNotifier: Error starting app: $e");
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }

  // "간편시작" 버튼 로직 (기존 로직 이전)
  Future<void> simpleStartApp() async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      // 기본값(null)으로 정보 저장
      await _prefsService.saveUserInfo(age: null, userTypes: []);
      await _prefsService.setOnboardingComplete(); // 온보딩 완료 플래그 설정

      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print("OnboardingNotifier: Onboarding complete (simple start).");
    } catch (e) {
      print("OnboardingNotifier: Error simple starting app: $e");
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }
}

// --- Provider 정의 ---
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(
        ref.read(
          preferencesServiceProvider,
        ), // main_screen_notifier.dart의 Provider 재사용
      );
    });
