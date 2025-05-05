import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/api/coordinates_response.dart';
import '../../../data/services/api_service.dart';
import '../main/main_screen_notifier.dart';
import 'add_person_state.dart'; // 위에서 정의한 State 클래스 import

// AddPersonScreen의 로직 및 상태 관리를 담당하는 Notifier
class AddPersonNotifier extends StateNotifier<AddPersonState> {
  final ApiService _apiService;
  final PreferencesService _prefsService;

  AddPersonNotifier(this._apiService, this._prefsService)
    : super(const AddPersonState()) {
    _fetchGuData(); // Notifier 생성 시 구 목록 로드 시작
  }

  // --- 상태 업데이트 함수 ---

  void setBirthDate(DateTime date) {
    state = state.copyWith(selectedBirthDate: date);
  }

  Future<void> setSelectedGu(String? gu) async {
    if (gu == null || gu == state.selectedGu) return;

    state = state.copyWith(
      selectedGu: gu,
      selectedDong: null, // 구 변경 시 동 선택 초기화
      clearSelectedDong: true,
      dongList: [], // 동 목록 초기화
      isLoadingDong: true, // 동 목록 로딩 시작
      errorMessage: null,
      clearErrorMessage: true, // 에러 메시지 초기화
    );

    try {
      final dongs = await _apiService.fetchDongList(gu);
      state = state.copyWith(dongList: dongs, isLoadingDong: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '$gu의 동 목록 로드 실패: $e',
        isLoadingDong: false,
      );
    }
  }

  void setSelectedDong(String? dong) {
    if (dong == null || dong == state.selectedDong) return;
    state = state.copyWith(selectedDong: dong);
  }

  // void toggleUserType(String type, bool value) {
  //   final currentSelection = Map<String, bool>.from(state.userTypeSelection);
  //   currentSelection[type] = value;
  //   state = state.copyWith(userTypeSelection: currentSelection);
  // }

  void setUserType(String? type) {
    state = state.copyWith(selectedUserType: type);
  }

  // 성별 설정 함수
  void setGender(String? gender) {
    state = state.copyWith(selectedGender: gender);
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

  // 구 목록 불러오기 (내부 사용)
  Future<void> _fetchGuData() async {
    state = state.copyWith(
      isLoadingGu: true,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final gus = await _apiService.fetchGuList();
      state = state.copyWith(guList: gus, isLoadingGu: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '구 목록 로드 실패: $e',
        isLoadingGu: false,
      );
    }
  }

  // 나이 계산 (AddPersonScreen에서 가져옴)
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

  // 사람 추가 로직 (AddPersonScreen에서 가져옴)
  Future<void> addPerson(String name) async {
    // 이름은 Screen에서 전달받음
    // 유효성 검사는 Screen 또는 여기서 추가 가능 (여기서 하는게 더 적합)
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: '이름을 입력해주세요.');
      return;
    }
    if (state.selectedBirthDate == null) {
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    if (state.selectedGu == null) {
      state = state.copyWith(errorMessage: '지역(구)을 선택해주세요.');
      return;
    }
    if (state.selectedDong == null) {
      state = state.copyWith(errorMessage: '지역(동)을 선택해주세요.');
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
      final CoordinatesResponse coords = await _apiService.fetchCoordinates(
        state.selectedGu!,
        state.selectedDong!,
      );
      final age = _calculateAge(state.selectedBirthDate);
      final String? selectedWorkingType =
          state.selectedUserType; // UI에서 선택한 근무 유형

      // TODO: 향후 기저 질환 선택 UI 구현 시, 여기서 선택된 기저 질환 목록을 가져와야 함.
      final List<String> selectedDiseasesList =
          state.selectedDiseases.toList(); // <<< Set -> List
      await _prefsService.saveIsPregnant(state.selectedIsPregnant);

      final newPerson = AddedPerson(
        id: const Uuid().v4(),
        name: name.trim(),
        birthDate: state.selectedBirthDate,
        gu: state.selectedGu,
        dong: state.selectedDong,
        gender: state.selectedGender,
        isPregnant: state.selectedIsPregnant,
        latitude: coords.latitude,
        longitude: coords.longitude,
        workingType:
            selectedWorkingType == '없음'
                ? null
                : selectedWorkingType, // <<< 근무 유형 저장
        diseases:
            selectedDiseasesList.isNotEmpty
                ? selectedDiseasesList
                : null, // <<< 기저 질환 저장 (현재는 빈 리스트)
      );

      await _prefsService.addPerson(newPerson);

      state = state.copyWith(isSaving: false, savedSuccessfully: true);
      print('${newPerson.name}님이 추가되었습니다.');
    } catch (e) {
      state = state.copyWith(errorMessage: '사람 추가 중 오류: $e', isSaving: false);
      print('Error adding person: $e');
    }
  }
}

// --- Provider 정의 ---
// ApiService와 PreferencesService는 main_screen_notifier에서 정의된 Provider 재사용
final addPersonNotifierProvider =
    StateNotifierProvider<AddPersonNotifier, AddPersonState>((ref) {
      return AddPersonNotifier(
        ref.read(apiServiceProvider), // main_screen_notifier.dart의 Provider 사용
        ref.read(
          preferencesServiceProvider,
        ), // main_screen_notifier.dart의 Provider 사용
      );
    });
