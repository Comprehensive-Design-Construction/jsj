import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/services/api_service.dart'; // ApiService import
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider, apiServiceProvider 사용 위해
import 'edit_profile_state.dart';

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  // ApiService 의존성 추가
  final ApiService _apiService;
  final PreferencesService _prefsService;

  // Notifier 생성 시 초기 데이터 로드 시작
  // ApiService Provider는 Provider 정의 부분에서 주입받음
  EditProfileNotifier(this._prefsService, this._apiService)
    : super(const EditProfileState()) {
    loadUserData();
    _fetchGuData(); // 구 목록 로드 추가
  }

  // 저장된 사용자 데이터 불러오기
  Future<void> loadUserData() async {
    // isLoadingLocationData도 true로 설정 (구/동 로딩 포함)
    state = state.copyWith(
      isLoading: true,
      isLoadingLocationData: true,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      // 이름은 현재 저장 기능 없음 (필요시 추가)

      // 나이 -> 생년월일 변환 (기존 로직 유지, 개선 필요 시 생년월일 직접 저장)
      final int? savedAge = await _prefsService.getUserAge();
      DateTime? initialBirthDate;
      if (savedAge != null) {
        // TODO: 생년월일 직접 저장 방식으로 개선 권장
        initialBirthDate = DateTime(DateTime.now().year - savedAge);
      }

      // 사용자 특성 불러오기
      final List<String>? savedTypes = await _prefsService.getUserTypes();
      final initialUserTypeSelection = <String, bool>{
        '농촌': savedTypes?.contains('농촌') ?? false,
        '비닐하우스': savedTypes?.contains('비닐하우스') ?? false,
        '실외작업자': savedTypes?.contains('실외작업자') ?? false,
      };

      // 저장된 '내 정보' 구/동 정보 로드
      final (savedGu, savedDong) = await _prefsService.getMyGuDong();

      // 동 목록은 구 선택 시 로드되므로 여기서는 초기화만
      state = state.copyWith(
        isLoading: false, // 기본 정보 로딩 완료
        initialBirthDate: initialBirthDate,
        initialUserTypeSelection: initialUserTypeSelection,
        selectedGu: savedGu, // 로드된 구 정보 설정
        // selectedDong은 setSelectedGu 호출 시 설정됨
      );
      print("EditProfileNotifier: User basic data loaded.");

      if (savedGu != null) {
        // 저장된 구가 있으면 해당 구의 동 목록 로드 시도
        await setSelectedGu(savedGu); // 동 목록 로드 포함
        // 동 정보도 있으면 설정 (setSelectedGu 호출 후 동 목록 로드가 완료된 상태에서 설정)
        if (savedDong != null && state.dongList.contains(savedDong)) {
          // await 키워드 추가하여 동 목록 로드 완료 후 실행 보장 (선택적)
          await Future.delayed(Duration.zero); // 상태 업데이트 반영 대기
          state = state.copyWith(selectedDong: savedDong);
        }
      } else {
        // 저장된 구가 없으면 지역 데이터 로딩 완료 처리
        state = state.copyWith(isLoadingLocationData: false);
      }
      // 구/동 로딩 상태는 _fetchGuData 및 setSelectedGu에서 최종 관리됨
    } catch (e) {
      print("EditProfileNotifier: Error loading user data: $e");
      state = state.copyWith(
        isLoading: false,
        isLoadingLocationData: false, // 에러 시 로딩 종료
        errorMessage: "사용자 정보 로드 실패: $e",
      );
    }
  }

  // 구 목록 불러오기 (add_person_notifier 로직 참고)
  Future<void> _fetchGuData() async {
    // isLoadingLocationData는 loadUserData에서 이미 true로 설정될 수 있음
    // 중복 로딩 방지 또는 상태 관리 방식에 따라 로직 조정 가능
    if (!state.isLoadingLocationData && state.guList.isNotEmpty)
      return; // 이미 로딩 완료 시 스킵

    state = state.copyWith(isLoadingLocationData: true); // 명시적으로 로딩 시작
    try {
      final gus = await _apiService.fetchGuList();
      // loadUserData에서 이미 false로 설정했을 수 있으므로, 조건부 업데이트
      // 또는 isLoadingLocationData 를 loadUserData 완료 후 여기서 false로 설정
      state = state.copyWith(guList: gus);
    } catch (e) {
      state = state.copyWith(errorMessage: '구 목록 로드 실패: $e');
    } finally {
      // loadUserData에서 저장된 구가 없는 경우, 여기서 로딩 상태 해제
      if (state.selectedGu == null) {
        state = state.copyWith(isLoadingLocationData: false);
      }
      // 저장된 구가 있는 경우는 setSelectedGu 에서 로딩 상태 관리
    }
  }

  // 구 선택 시 동 목록 로드 (add_person_notifier 로직 참고)
  Future<void> setSelectedGu(String? gu) async {
    // 선택값이 같거나 null이면 무시 (null 선택 시 초기화 로직은 필요할 수 있음)
    if (gu == state.selectedGu) return;

    // 구 선택 해제 (null) 시 처리
    if (gu == null) {
      state = state.copyWith(
        selectedGu: null,
        selectedDong: null,
        clearSelectedDong: true,
        dongList: [],
        errorMessage: null, // 관련 에러 메시지 초기화
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      selectedGu: gu,
      selectedDong: null,
      clearSelectedDong: true, // 동 선택 초기화
      dongList: [], // 동 목록 초기화
      isLoadingLocationData: true, // 동 목록 로딩 시작
      errorMessage: null,
      clearErrorMessage: true, // 에러 초기화
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

  // 동 선택 (add_person_notifier 로직 참고)
  void setSelectedDong(String? dong) {
    // null 선택 시 처리 포함 (선택 해제)
    state = state.copyWith(selectedDong: dong, clearSelectedDong: dong == null);
  }

  // 나이 계산 함수 (기존과 동일)
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

  // 프로필 저장 로직 (기존 로직 이전)
  Future<void> saveProfile({
    required DateTime? birthDate, // Screen에서 현재 선택된 값 전달 받음
    required String? selectedGu, // Screen에서 현재 선택된 값 전달 받음
    required String? selectedDong, // Screen에서 현재 선택된 값 전달 받음
    required Map<String, bool> userTypeSelection, // Screen에서 현재 선택된 값 전달 받음
    // required String name, // 이름 저장 필요 시 추가
  }) async {
    // 유효성 검사 (생년월일 필수)
    if (birthDate == null) {
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    // 지역 선택 유효성 검사 추가
    if (selectedGu == null) {
      state = state.copyWith(errorMessage: '거주 지역(구)을 선택해주세요.');
      return;
    }
    if (selectedDong == null) {
      state = state.copyWith(errorMessage: '거주 지역(동)을 선택해주세요.');
      return;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      final age = _calculateAge(birthDate);
      final selectedTypes =
          userTypeSelection.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      // TODO: 기저질환 정보 가져오기
      final List<String> diseaseParam = [...selectedTypes /*, ...diseases*/];

      // 로컬 저장소에 수정된 정보 저장
      await _prefsService.saveUserInfo(age: age, userTypes: diseaseParam);
      // '내 정보'의 구/동 정보 저장
      await _prefsService.saveMyGuDong(selectedGu, selectedDong);
      // TODO: 이름 저장 로직 추가 시 여기에 포함 (_prefsService에 관련 함수 추가 필요)

      // 저장 성공 시 초기값들도 업데이트 (선택사항)
      state = state.copyWith(
        isSaving: false,
        savedSuccessfully: true,
        initialBirthDate: birthDate, // 저장된 값으로 초기값 업데이트
        // selectedGu, selectedDong은 이미 상태에 반영되어 있음
        initialUserTypeSelection: userTypeSelection,
      );
      print("EditProfileNotifier: Profile saved successfully.");
    } catch (e) {
      print("EditProfileNotifier: Error saving profile: $e");
      state = state.copyWith(isSaving: false, errorMessage: "정보 저장 실패: $e");
    }
  }
}

// --- Provider 정의 ---
final editProfileNotifierProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
      // ApiService Provider도 주입
      return EditProfileNotifier(
        ref.read(preferencesServiceProvider),
        ref.read(apiServiceProvider), // main_screen_notifier.dart의 Provider 재사용
      );
    });
