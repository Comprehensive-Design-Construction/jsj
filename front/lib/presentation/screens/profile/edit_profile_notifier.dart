import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/services/api_service.dart'; // ApiService import
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider, apiServiceProvider 사용 위해
import 'edit_profile_state.dart';
import '../../../data/models/added_person.dart';

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final ApiService _apiService;
  final PreferencesService _prefsService;

  EditProfileNotifier(this._prefsService, this._apiService)
    : super(const EditProfileState()) {
    _initialize();
  }

  // 초기화 로직 통합
  Future<void> _initialize() async {
    await loadUserData();
    // `mounted` 확인: loadUserData 완료 후
    if (!mounted) return;
    // 구 목록 로드가 loadUserData 에서 시작되지 않았다면 여기서 시작
    if (state.guList.isEmpty && !state.isLoadingLocationData) {
      await _fetchGuData();
    }
  }

  // 저장된 사용자 데이터 불러오기
  Future<void> loadUserData() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingLocationData: true, // 구/동 로딩 포함
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      // 여러 SharedPreferences 값 병렬 로드 시도 (더 효율적)
      final results = await Future.wait([
        _prefsService.getUserAge(),
        _prefsService.getUserType(),
        _prefsService.getUserDiseases(),
        _prefsService.getMyGuDong(),
        _prefsService.getUserGender(),
        _prefsService.getIsPregnant(),
      ]);

      // `mounted` 확인: 모든 SharedPreferences 작업 완료 후
      if (!mounted) return;

      final int? savedAge = results[0] as int?;
      final String? initialUserType = results[1] as String?;
      final List<String>? initialDiseasesList = results[2] as List<String>?;
      final (savedGu, savedDong) = results[3] as (String?, String?);
      final String? savedGender = results[4] as String?;
      final bool? initialIsPregnant = results[5] as bool?;

      DateTime? initialBirthDate;
      if (savedAge != null) {
        initialBirthDate = DateTime(DateTime.now().year - savedAge);
      }
      final Set<String> initialDiseasesSet =
          initialDiseasesList?.toSet() ?? const {};
      final initialGender = savedGender ?? Gender.male; // 기본값 남성

      // 상태 업데이트
      state = state.copyWith(
        // isLoading: false, // 아직 지역 로딩이 남았을 수 있으므로 여기서 false로 설정 안 함
        initialBirthDate: initialBirthDate,
        initialUserType: initialUserType,
        initialIsPregnant: initialIsPregnant,
        selectedBirthDate: initialBirthDate,
        selectedUserType: initialUserType,
        selectedGender: initialGender,
        initialDiseases: initialDiseasesSet,
        selectedDiseases: initialDiseasesSet,
        selectedIsPregnant: initialIsPregnant,
        selectedGu: savedGu,
        // selectedDong은 setSelectedGu 내부에서 설정됨
      );
      print("EditProfileNotifier: User basic data loaded.");

      // 저장된 '구'가 있으면 해당 '동' 목록 로드 시작
      if (savedGu != null) {
        // setSelectedGu 는 내부적으로 mounted 체크를 포함해야 함
        await setSelectedGu(savedGu);
        // `mounted` 확인: setSelectedGu 완료 후
        if (!mounted) return;
        // 저장된 '동'이 있고, 로드된 동 목록에 포함되어 있으면 선택
        if (savedDong != null && state.dongList.contains(savedDong)) {
          // 동 선택 상태 업데이트 (동기 작업이므로 mounted 체크 불필요)
          state = state.copyWith(
            selectedDong: savedDong,
            isLoading: false,
            isLoadingLocationData: false,
          );
        } else {
          // 저장된 동이 없거나 목록에 없으면 로딩 완료 처리
          state = state.copyWith(
            isLoading: false,
            isLoadingLocationData: false,
          );
        }
      } else {
        // 저장된 구가 없으면 로딩 완료
        state = state.copyWith(isLoading: false, isLoadingLocationData: false);
      }
    } catch (e) {
      print("EditProfileNotifier: Error loading user data: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(
        isLoading: false,
        isLoadingLocationData: false,
        errorMessage: "사용자 정보 로드 실패: $e",
      );
    }
  }

  // 생년월일 설정 (동기 작업)
  void setBirthDate(DateTime? date) {
    if (date != state.selectedBirthDate) {
      if (!mounted) return;
      state = state.copyWith(selectedBirthDate: date);
    }
  }

  // 사용자 특성 설정 (동기 작업)
  void setUserType(String? type) {
    if (!mounted) return;
    state = state.copyWith(selectedUserType: type);
  }

  // 성별 설정 (동기 작업)
  void setGender(String? gender) {
    if (gender != null && gender != state.selectedGender) {
      if (!mounted) return;
      state = state.copyWith(selectedGender: gender);
    }
  }

  // 임신 여부 설정 (동기 작업)
  void setIsPregnant(bool? value) {
    if (!mounted) return;
    state = state.copyWith(selectedIsPregnant: value);
  }

  // 기저 질환 토글 (동기 작업)
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

  // 기저 질환 전체 설정 (동기 작업)
  void setSelectedDiseases(Set<String> newSelection) {
    if (state.selectedDiseases != newSelection) {
      if (!mounted) return;
      state = state.copyWith(selectedDiseases: newSelection);
    }
  }

  // 구 목록 불러오기
  Future<void> _fetchGuData() async {
    if (state.guList.isNotEmpty) return; // 이미 로딩되었으면 스킵

    state = state.copyWith(isLoadingLocationData: true);
    try {
      final gus = await _apiService.fetchGuList();
      // `mounted` 확인: API 호출 후
      if (!mounted) return;
      state = state.copyWith(guList: gus, isLoadingLocationData: false);
    } catch (e) {
      print("Error fetching Gu list: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(
        errorMessage: '구 목록 로드 실패: $e',
        isLoadingLocationData: false,
      );
    }
  }

  // 구 선택 시 동 목록 로드
  Future<void> setSelectedGu(String? gu) async {
    if (gu == state.selectedGu) return;

    // `mounted` 확인: 상태 변경 전
    if (!mounted) return;

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

    // 새 구 선택, 동 로딩 시작
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
      // `mounted` 확인: 동 목록 API 호출 후
      if (!mounted) return;
      // 동 목록 로드 완료 (지역 로딩 상태는 loadUserData에서 최종 결정)
      state = state.copyWith(dongList: dongs); //isLoadingLocationData: false);
    } catch (e) {
      print("Error fetching Dong list for $gu: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(
        errorMessage: '$gu의 동 목록 로드 실패: $e',
        //isLoadingLocationData: false, // 에러 시에도 로딩은 끝남
      );
    } finally {
      // 동 로딩 시도가 끝났으므로 로딩 상태 해제 (성공/실패 무관)
      // loadUserData 내에서 최종 isLoading, isLoadingLocationData 관리가 더 명확할 수 있음
      if (mounted) {
        state = state.copyWith(isLoadingLocationData: false);
      }
    }
  }

  // 동 선택 (동기 작업)
  void setSelectedDong(String? dong) {
    // null 선택 시 처리 포함
    if (!mounted) return;
    state = state.copyWith(selectedDong: dong, clearSelectedDong: dong == null);
  }

  // 나이 계산 (동기 작업)
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

  // 프로필 저장 로직
  Future<void> saveProfile({
    required String? selectedGu,
    required String? selectedDong,
    required String? selectedGender,
  }) async {
    // 유효성 검사 (동기 작업)
    final currentBirthDate = state.selectedBirthDate;
    if (currentBirthDate == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    if (selectedGu == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '거주 지역(구)을 선택해주세요.');
      return;
    }
    if (selectedDong == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '거주 지역(동)을 선택해주세요.');
      return;
    }
    if (selectedGender == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '성별을 선택해주세요.');
      return;
    }

    // 저장 시작 상태 업데이트
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      final age = _calculateAge(currentBirthDate);
      final currentSelectedUserType = state.selectedUserType;
      final String? userTypeToSave =
          currentSelectedUserType == '없음' ? null : currentSelectedUserType;
      final List<String> selectedDiseasesList = state.selectedDiseases.toList();

      // 여러 SharedPreferences 저장 병렬 처리
      await Future.wait([
        _prefsService.saveUserInfo(
          age: age,
          userType: userTypeToSave,
          gender: selectedGender,
        ),
        _prefsService.saveUserDiseases(selectedDiseasesList),
        _prefsService.saveMyGuDong(selectedGu, selectedDong),
        _prefsService.saveIsPregnant(state.selectedIsPregnant),
      ]);

      // `mounted` 확인: 모든 저장 작업 완료 후
      if (!mounted) return;

      // 저장 완료 상태 업데이트
      state = state.copyWith(
        isSaving: false,
        savedSuccessfully: true,
        initialBirthDate: currentBirthDate, // 초기값 업데이트
        initialUserType: currentSelectedUserType,
        initialDiseases: state.selectedDiseases,
        initialIsPregnant: state.selectedIsPregnant,
      );
      print("EditProfileNotifier: Profile saved successfully.");
    } catch (e) {
      print("EditProfileNotifier: Error saving profile: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(isSaving: false, errorMessage: "정보 저장 실패: $e");
    }
  }
}

// --- Provider 정의 ---
final editProfileNotifierProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
      return EditProfileNotifier(
        ref.read(preferencesServiceProvider),
        ref.read(apiServiceProvider),
      );
    });
