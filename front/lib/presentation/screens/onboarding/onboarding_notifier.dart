import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/data/models/added_person.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/services/api_service.dart'; // ApiService import
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider, apiServiceProvider 사용 위해
import 'onboarding_state.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferencesService _prefsService;
  final ApiService _apiService;

  OnboardingNotifier(this._prefsService, this._apiService)
    : super(const OnboardingState()) {
    _fetchGuData(); // Notifier 생성 시 구 목록 로드
  }

  // --- 상태 업데이트 함수 (대부분 동기 작업) ---
  void setBirthDate(DateTime date) {
    if (!mounted) return;
    state = state.copyWith(
      selectedBirthDate: date,
      errorMessage: null, // 생년월일 선택 시 에러 메시지 초기화
      clearErrorMessage: true,
    );
  }

  void setUserType(String? type) {
    if (!mounted) return;
    state = state.copyWith(selectedUserType: type);
  }

  void setGender(String? gender) {
    if (!mounted) return;
    state = state.copyWith(selectedGender: gender);
  }

  void setIsPregnant(bool? value) {
    if (!mounted) return;
    state = state.copyWith(selectedIsPregnant: value);
  }

  void toggleDiseaseSelection(String diseaseName) {
    if (!mounted) return;
    final currentSelection = Set<String>.from(state.selectedDiseases);
    if (currentSelection.contains(diseaseName)) {
      currentSelection.remove(diseaseName);
    } else {
      currentSelection.add(diseaseName);
    }
    state = state.copyWith(selectedDiseases: currentSelection);
  }

  void setSelectedDiseases(Set<String> newSelection) {
    if (state.selectedDiseases != newSelection) {
      if (!mounted) return;
      state = state.copyWith(selectedDiseases: newSelection);
    }
  }

  // --- 비동기 작업 포함 함수 ---
  Future<void> _fetchGuData() async {
    if (!mounted) return;
    // 로딩 시작 시 locationErrorText 초기화
    state = state.copyWith(
      isLoadingLocationData: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );
    try {
      final gus = await _apiService.fetchGuList();
      if (!mounted) return;
      state = state.copyWith(guList: gus, isLoadingLocationData: false);
    } catch (e) {
      print("Error fetching Gu list in Onboarding: $e");
      if (!mounted) return;
      // errorMessage 대신 locationErrorText 설정
      state = state.copyWith(
        locationErrorText: '구 목록 로드 실패', // 간단한 메시지
        isLoadingLocationData: false,
      );
    }
  }

  Future<void> setSelectedGu(String? gu) async {
    if (gu == state.selectedGu) return;
    if (!mounted) return;

    if (gu == null) {
      state = state.copyWith(
        selectedGu: null,
        selectedDong: null,
        clearSelectedDong: true,
        dongList: [],
        locationErrorText: null,
        clearLocationErrorText: true,
      ); // 에러 초기화
      return;
    }

    // 동 로딩 시작 시 locationErrorText 초기화
    state = state.copyWith(
      selectedGu: gu,
      selectedDong: null,
      clearSelectedDong: true,
      dongList: [],
      isLoadingLocationData: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );

    try {
      final dongs = await _apiService.fetchDongList(gu);
      if (!mounted) return;
      state = state.copyWith(dongList: dongs, isLoadingLocationData: false);
    } catch (e) {
      print("Error fetching Dong list for $gu in Onboarding: $e");
      if (!mounted) return;
      // errorMessage 대신 locationErrorText 설정
      state = state.copyWith(
        locationErrorText: '$gu 동 목록 로드 실패',
        isLoadingLocationData: false,
      );
    }
  }

  void setSelectedDong(String? dong) {
    // `mounted` 확인: 동기 상태 변경이지만, 일관성을 위해 추가 가능
    if (!mounted) return;
    state = state.copyWith(selectedDong: dong, clearSelectedDong: dong == null);
  }

  // --- 로직 함수 ---
  int? _calculateAge(DateTime? birthDate) {
    // 동기 작업
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  // "시작" 버튼 로직 (정보 저장 및 완료 처리)
  Future<void> startApp(String? name) async {
    // 유효성 검사: 실패 시 errorMessage 설정 (SnackBar 용도)
    if (state.selectedBirthDate == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    if (state.selectedGu == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '거주 지역(구)을 선택해주세요.');
      return;
    }
    if (state.selectedDong == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '거주 지역(동)을 선택해주세요.');
      return;
    }
    if (state.selectedGender == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '성별을 선택해주세요.');
      return;
    }

    // 저장 시작 상태 (errorMessage 초기화)
    if (!mounted) return;
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    ); // 모든 에러 초기화

    try {
      // 저장 로직 (기존과 동일, await Future.wait 사용)
      final age = _calculateAge(state.selectedBirthDate);
      final String? selectedType = state.selectedUserType;
      final List<String> selectedDiseasesList = state.selectedDiseases.toList();
      await Future.wait([/* ... SharedPreferences 저장 ... */]);

      if (!mounted) return;
      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print("OnboardingNotifier: Onboarding complete (with data).");
    } catch (e) {
      print("OnboardingNotifier: Error starting app: $e");
      if (!mounted) return;
      // 저장 실패 시 errorMessage 설정 (SnackBar 용도)
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }

  Future<void> simpleStartApp() async {
    // 저장 시작 상태 (errorMessage 초기화)
    if (!mounted) return;
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );

    try {
      // 저장 로직 (기존과 동일, await Future.wait 사용)
      await Future.wait([/* ... SharedPreferences 저장 (기본값) ... */]);

      if (!mounted) return;
      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print("OnboardingNotifier: Onboarding complete (simple start).");
    } catch (e) {
      print("OnboardingNotifier: Error simple starting app: $e");
      if (!mounted) return;
      // 저장 실패 시 errorMessage 설정 (SnackBar 용도)
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }
}

// --- Provider 정의 ---
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(
        ref.read(preferencesServiceProvider),
        ref.read(apiServiceProvider),
      );
    });
