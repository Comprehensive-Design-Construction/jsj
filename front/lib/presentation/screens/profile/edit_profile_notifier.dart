import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/preferences_service.dart';
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider 사용 위해
import 'edit_profile_state.dart';

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final PreferencesService _prefsService;

  // Notifier 생성 시 초기 데이터 로드 시작
  EditProfileNotifier(this._prefsService) : super(const EditProfileState()) {
    loadUserData();
  }

  // 저장된 사용자 데이터 불러오기 (기존 로직 이전)
  Future<void> loadUserData() async {
    state = state.copyWith(
      isLoading: true,
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

      state = state.copyWith(
        isLoading: false,
        initialBirthDate: initialBirthDate,
        initialUserTypeSelection: initialUserTypeSelection,
      );
      print("EditProfileNotifier: User data loaded.");
    } catch (e) {
      print("EditProfileNotifier: Error loading user data: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: "사용자 정보 로드 실패: $e",
      );
    }
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
    required Map<String, bool> userTypeSelection, // Screen에서 현재 선택된 값 전달 받음
    // required String name, // 이름 저장 필요 시 추가
  }) async {
    // 유효성 검사 (생년월일 필수)
    if (birthDate == null) {
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
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
      // TODO: 이름 저장 로직 추가 시 여기에 포함 (_prefsService에 관련 함수 추가 필요)

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
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
      return EditProfileNotifier(
        ref.read(
          preferencesServiceProvider,
        ), // main_screen_notifier.dart의 Provider 재사용
      );
    });
