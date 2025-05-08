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
    print('[OnboardingNotifier] Created.');
    _fetchGuData(); // Notifier 생성 시 구 목록 로드
  }

  // --- 상태 업데이트 함수 (대부분 동기 작업) ---
  void setBirthDate(DateTime date) {
    // if (!mounted) return;
    state = state.copyWith(
      selectedBirthDate: date,
      errorMessage: null, // 생년월일 선택 시 에러 메시지 초기화
      clearErrorMessage: true,
    );
  }

  void setUserType(String? type) {
    // if (!mounted) return;
    state = state.copyWith(selectedUserType: type);
  }

  void setGender(String? gender) {
    if (!mounted) return;
    // --- 수정 시작 ---
    // 성별 상태를 업데이트합니다.
    // 만약 새로 선택된 성별이 남성이면, 임산부 상태를 false로 재설정합니다.
    state = state.copyWith(
      selectedGender: gender,
      selectedIsPregnant:
          gender == Gender.male
              ? false
              : state.selectedIsPregnant, // 남성이면 false, 아니면 기존 값 유지
    );
    // --- 수정 종료 ---
  }

  void setIsPregnant(bool? value) {
    // if (!mounted) return;
    state = state.copyWith(selectedIsPregnant: value);
  }

  void toggleDiseaseSelection(String diseaseName) {
    // if (!mounted) return;
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
      // if (!mounted) return;
      state = state.copyWith(selectedDiseases: newSelection);
    }
  }

  // --- 비동기 작업 포함 함수 ---
  Future<void> _fetchGuData() async {
    print('[OnboardingNotifier] Fetching Gu data...');
    state = state.copyWith(
      isLoadingLocationData: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );
    try {
      final gus = await _apiService.fetchGuList();
      if (!mounted) return;
      print('[OnboardingNotifier] Fetched Gu data: ${gus.length} items.');
      state = state.copyWith(guList: gus, isLoadingLocationData: false);
    } catch (e) {
      print("[OnboardingNotifier] Error fetching Gu list in Onboarding: $e");
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
    // if (!mounted) return;

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
      // if (!mounted) return;
      state = state.copyWith(dongList: dongs, isLoadingLocationData: false);
    } catch (e) {
      print("Error fetching Dong list for $gu in Onboarding: $e");
      // if (!mounted) return;
      // errorMessage 대신 locationErrorText 설정
      state = state.copyWith(
        locationErrorText: '$gu 동 목록 로드 실패',
        isLoadingLocationData: false,
      );
    }
  }

  void setSelectedDong(String? dong) {
    // `mounted` 확인: 동기 상태 변경이지만, 일관성을 위해 추가 가능
    // if (!mounted) return;
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
    print('[OnboardingNotifier] startApp called.');
    state = state.copyWith(
      isSaving: true, // 이 부분 전후에 로그 추가
      errorMessage: null,
      clearErrorMessage: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );
    // 유효성 검사 통과 후, 저장 로직 시작 직전에 현재 Notifier 상태 값 로그
    print(
      '[OnboardingNotifier] startApp: Values from current state before saving:',
    );
    print('  - selectedBirthDate: ${state.selectedBirthDate}');
    print('  - selectedUserType: ${state.selectedUserType}');
    print('  - selectedGender: ${state.selectedGender}');
    print('  - selectedIsPregnant: ${state.selectedIsPregnant}');
    print('  - selectedGu: ${state.selectedGu}');
    print('  - selectedDong: ${state.selectedDong}');
    print('  - selectedDiseases: ${state.selectedDiseases}');

    // 유효성 검사: 실패 시 errorMessage 설정 (SnackBar 용도)
    // if (state.selectedBirthDate == null) {
    //   // if (!mounted) return;
    //   state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
    //   return;
    // }

    // 저장 시작 상태 (errorMessage 초기화)
    // if (!mounted) return;
    state = state.copyWith(isSaving: true); // 모든 에러 초기화

    try {
      // 저장 로직 (기존과 동일, await Future.wait 사용)
      final age = _calculateAge(state.selectedBirthDate);
      final String? selectedType = state.selectedUserType;
      final List<String> selectedDiseasesList = state.selectedDiseases.toList();

      print(
        '[OnboardingNotifier] startApp: Calling PreferenceService save functions...',
      );

      await Future.wait([
        _prefsService.saveUserInfo(
          // 이 호출에서 위에서 추가한 saveUserInfo 로그가 찍힐 것입니다.
          age: age,
          userType: selectedType == '없음' ? null : selectedType,
          gender: state.selectedGender,
        ),
        _prefsService.saveUserDiseases(
          selectedDiseasesList,
        ), // 이 호출에서 saveUserDiseases 로그가 찍힐 것입니다.
        _prefsService.saveMyGuDong(
          state.selectedGu,
          state.selectedDong,
        ), // 이 호출에서 saveMyGuDong 로그가 찍힐 것입니다.
        _prefsService.saveIsPregnant(
          state.selectedIsPregnant,
        ), // 이 호출에서 saveIsPregnant 로그가 찍힐 것입니다.
      ]);
      await Future.wait([
        _prefsService.setOnboardingComplete(),
        _prefsService.setUsedSimpleStart(false), // 시작하기를 눌렀으므로 간편시작 아님
        // _prefsService.setConsentGiven(true)는 ConsentScreen에서 처리했으므로 여기서 호출 불필요
      ]);
      print(
        '[OnboardingNotifier] startApp: All PreferenceService save calls awaited.',
      );

      if (!mounted) return;
      state = state.copyWith(isSaving: false, onboardingProcessComplete: true);
      print("OnboardingNotifier: Onboarding complete (with data).");
    } catch (e) {
      print("OnboardingNotifier: Error starting app: $e");
      // if (!mounted) return;
      // 저장 실패 시 errorMessage 설정 (SnackBar 용도)
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }

  Future<void> simpleStartApp() async {
    print('[OnboardingNotifier] simpleStartApp called.');
    state = state.copyWith(
      isSaving: true, // 이 부분 전후에 로그 추가
      errorMessage: null,
      clearErrorMessage: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );
    print('[OnboardingNotifier] simpleStartApp: isSaving = true');

    try {
      // 저장 로직 (기존과 동일, await Future.wait 사용)
      await Future.wait([
        _prefsService.saveUserInfo(age: null, userType: null, gender: null),
        _prefsService.saveMyGuDong(null, null),
        _prefsService.saveUserDiseases(null),
        _prefsService.saveIsPregnant(null),
        // 간편 시작은 개인정보 동의를 받지 않으므로 consent는 false 또는 저장 안 함
        _prefsService.setConsentGiven(false),
        // 온보딩 완료 및 간편시작 사용 기록
        _prefsService.setOnboardingComplete(),
        _prefsService.setUsedSimpleStart(true),
      ]);

      // if (!mounted) return;
      print(
        '[OnboardingNotifier] simpleStartApp: Saving complete. Setting onboardingProcessComplete = true',
      );
      state = state.copyWith(
        isSaving: false,
        onboardingProcessComplete: true,
      ); // 이 부분 전후에 로그 추가
      print(
        '[OnboardingNotifier] simpleStartApp: isSaving = false, onboardingProcessComplete = true',
      );
    } catch (e) {
      print("OnboardingNotifier: Error simple starting app: $e");
      // if (!mounted) return;
      // 저장 실패 시 errorMessage 설정 (SnackBar 용도)
      state = state.copyWith(isSaving: false, errorMessage: "처리 중 오류 발생: $e");
    }
  }
}

// --- Provider 정의 ---
final onboardingNotifierProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>((
      ref,
    ) {
      // ref.keepAlive(); // 필요 시 Provider 상태를 유지할 수 있지만, 여기서는 자동 폐기가 목적
      return OnboardingNotifier(
        ref.read(
          preferencesServiceProvider,
        ), // apiServiceProvider 등 다른 의존성도 read 사용
        ref.read(apiServiceProvider),
      );
    });
