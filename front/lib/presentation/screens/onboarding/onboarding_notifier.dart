import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/data/models/added_person.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/services/api_service.dart'; // ApiService import
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider, apiServiceProvider 사용 위해
import 'onboarding_state.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferencesService _prefsService;
  final ApiService _apiService; // ApiService 의존성 추가

  OnboardingNotifier(this._prefsService, this._apiService) // 생성자 수정
    : super(const OnboardingState()) {
    _fetchGuData(); // Notifier 생성 시 구 목록 로드
  }

  // --- 상태 업데이트 함수 ---
  void setBirthDate(DateTime date) {
    state = state.copyWith(
      selectedBirthDate: date,
      errorMessage: null,
      clearErrorMessage: true,
    );
  }

  // void toggleUserType(String type, bool value) {
  //   final currentSelection = Map<String, bool>.from(state.userTypeSelection);
  //   currentSelection[type] = value;
  //   state = state.copyWith(userTypeSelection: currentSelection);
  // }

  void setUserType(String? type) {
    // '없음'을 선택하면 null로 저장할지, '없음' 문자열 그대로 저장할지 결정 필요
    // 여기서는 '없음'도 유효한 값으로 간주하고 그대로 저장
    state = state.copyWith(selectedUserType: type);
  }

  // 성별 설정 함수
  void setGender(String? gender) {
    state = state.copyWith(selectedGender: gender);
  }

  // 구/동 선택 관련 함수 추가 (edit_profile_notifier.dart 와 유사)
  Future<void> _fetchGuData() async {
    state = state.copyWith(isLoadingLocationData: true);
    try {
      final gus = await _apiService.fetchGuList();
      state = state.copyWith(guList: gus, isLoadingLocationData: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '구 목록 로드 실패: $e',
        isLoadingLocationData: false,
      );
    }
  }

  Future<void> setSelectedGu(String? gu) async {
    if (gu == state.selectedGu) return; // 변경 없으면 무시

    if (gu == null) {
      // 구 선택 해제
      state = state.copyWith(
        selectedGu: null,
        selectedDong: null,
        clearSelectedDong: true,
        dongList: [],
        errorMessage: null,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      selectedGu: gu,
      selectedDong: null,
      clearSelectedDong: true,
      dongList: [],
      isLoadingLocationData: true, // 동 로딩 시작
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final dongs = await _apiService.fetchDongList(gu);
      state = state.copyWith(dongList: dongs, isLoadingLocationData: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '$gu의 동 목록 로드 실패: $e',
        isLoadingLocationData: false,
      );
    }
  }

  void setSelectedDong(String? dong) {
    state = state.copyWith(selectedDong: dong, clearSelectedDong: dong == null);
  }

  void setIsPregnant(bool? value) {
    state = state.copyWith(selectedIsPregnant: value);
  }

  // 기저 질환 선택/해제 처리 함수
  void toggleDiseaseSelection(String diseaseName) {
    // 현재 Set 복사 (불변성 유지)
    final currentSelection = Set<String>.from(state.selectedDiseases);
    if (currentSelection.contains(diseaseName)) {
      currentSelection.remove(diseaseName); // 있으면 제거
    } else {
      currentSelection.add(diseaseName); // 없으면 추가
    }
    // 변경된 Set으로 상태 업데이트 (각 Notifier의 State 타입에 맞게 copyWith 호출)
    state = state.copyWith(selectedDiseases: currentSelection);
    // 아래 각 Notifier 수정 시 이 함수 호출 부분 참고
  }

  void setSelectedDiseases(Set<String> newSelection) {
    // 상태 변경 시에만 업데이트 (불필요한 리빌드 방지)
    if (state.selectedDiseases != newSelection) {
      state = state.copyWith(selectedDiseases: newSelection);
    }
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

  // "시작" 버튼 로직 수정 (구/동 정보 저장 추가)
  Future<void> startApp(String? name /* 이름 필요시 전달 */) async {
    // 유효성 검사 (생년월일, 구, 동 추가)
    if (state.selectedBirthDate == null) {
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    if (state.selectedGu == null) {
      state = state.copyWith(errorMessage: '거주 지역(구)을 선택해주세요.');
      return;
    }
    if (state.selectedDong == null) {
      state = state.copyWith(errorMessage: '거주 지역(동)을 선택해주세요.');
      return;
    }
    if (state.selectedGender == null) {
      state = state.copyWith(errorMessage: '성별을 선택해주세요.');
      return;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      final age = _calculateAge(state.selectedBirthDate);
      // final selectedTypes =
      //     state.userTypeSelection.entries
      //         .where((entry) => entry.value)
      //         .map((entry) => entry.key)
      //         .toList();
      // final List<String> diseaseParam = [...selectedTypes];
      final String? selectedType = state.selectedUserType;
      final List<String> selectedDiseasesList =
          state.selectedDiseases.toList(); // <<< Set -> List

      // 로컬 저장소에 정보 저장
      await _prefsService.saveUserInfo(
        age: age,
        userType: selectedType == '없음' ? null : selectedType,
        gender: state.selectedGender,
      );
      // '내 정보'의 구/동 정보 저장 추가
      await _prefsService.saveUserDiseases(selectedDiseasesList);
      await _prefsService.saveMyGuDong(state.selectedGu, state.selectedDong);
      await _prefsService.saveIsPregnant(state.selectedIsPregnant);
      await _prefsService.setOnboardingComplete(); // 온보딩 완료 플래그 설정

      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print(
        "OnboardingNotifier: Onboarding complete (with data including location).",
      );
    } catch (e) {
      print("OnboardingNotifier: Error starting app: $e");
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }

  // "간편시작" 버튼 로직 (기존 로직 유지 - 구/동 정보 저장 안 함)
  Future<void> simpleStartApp() async {
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      // 기본값(null)으로 정보 저장
      await _prefsService.saveUserInfo(
        age: null,
        userType: null,
        gender: Gender.male,
      );
      await _prefsService.saveUserDiseases(null);
      // '내 정보' 구/동 정보는 저장하지 않음 (또는 명시적으로 null 저장)
      await _prefsService.saveMyGuDong(null, null);
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
        ref.read(preferencesServiceProvider),
        ref.read(apiServiceProvider), // ApiService 주입
      );
    });
