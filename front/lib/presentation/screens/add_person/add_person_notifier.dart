import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/api/coordinates_response.dart';
import '../../../data/services/api_service.dart';
import '../main/main_screen_notifier.dart';
import 'add_person_state.dart';

class AddPersonNotifier extends StateNotifier<AddPersonState> {
  final ApiService _apiService;
  final PreferencesService _prefsService;

  AddPersonNotifier(this._apiService, this._prefsService)
    : super(const AddPersonState()) {
    _fetchGuData(); // Notifier 생성 시 구 목록 로드 시작
  }

  // --- 상태 업데이트 함수 (동기) ---
  void setBirthDate(DateTime date) {
    if (!mounted) return;
    state = state.copyWith(selectedBirthDate: date);
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

  void setSelectedDong(String? dong) {
    if (dong == state.selectedDong) return; // 값 변경 없으면 무시
    if (!mounted) return;
    state = state.copyWith(selectedDong: dong);
  }

  // --- 비동기 함수 ---
  Future<void> _fetchGuData() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoadingGu: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    ); // 에러 초기화
    try {
      final gus = await _apiService.fetchGuList();
      if (!mounted) return;
      state = state.copyWith(guList: gus, isLoadingGu: false);
    } catch (e) {
      print("Error fetching Gu list in AddPerson: $e");
      if (!mounted) return;
      // locationErrorText 설정
      state = state.copyWith(
        locationErrorText: '구 목록 로드 실패',
        isLoadingGu: false,
      );
    }
  }

  Future<void> setSelectedGu(String? gu) async {
    if (gu == null || gu == state.selectedGu) return;
    if (!mounted) return;

    // 동 로딩 시작, 에러 초기화
    state = state.copyWith(
      selectedGu: gu,
      selectedDong: null,
      clearSelectedDong: true,
      dongList: [],
      isLoadingDong: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );

    try {
      final dongs = await _apiService.fetchDongList(gu);
      if (!mounted) return;
      state = state.copyWith(dongList: dongs, isLoadingDong: false);
    } catch (e) {
      print("Error fetching Dong list for $gu in AddPerson: $e");
      if (!mounted) return;
      // locationErrorText 설정
      state = state.copyWith(
        locationErrorText: '$gu 동 목록 로드 실패',
        isLoadingDong: false,
      );
    }
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

  Future<void> addPerson(String name) async {
    // 유효성 검사 (동기)
    if (name.trim().isEmpty) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '이름을 입력해주세요.');
      return;
    }
    if (state.selectedBirthDate == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '생년월일을 선택해주세요.');
      return;
    }
    if (state.selectedGu == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '지역(구)을 선택해주세요.');
      return;
    }
    if (state.selectedDong == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '지역(동)을 선택해주세요.');
      return;
    }
    if (state.selectedGender == null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '성별을 선택해주세요.');
      return;
    }
    if (state.locationErrorText != null) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: '지역 정보를 확인해주세요.');
      return;
    }

    // 저장 시작 상태 업데이트
    if (!mounted) return;
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
      locationErrorText: null,
      clearLocationErrorText: true,
    );

    try {
      // 1. 좌표 가져오기 (API 호출)
      final CoordinatesResponse coords = await _apiService.fetchCoordinates(
        state.selectedGu!,
        state.selectedDong!,
      );
      // `mounted` 확인: 좌표 API 호출 후
      if (!mounted) return;

      // 2. 사용자 정보 준비 (동기)
      final age = _calculateAge(state.selectedBirthDate);
      final String? selectedWorkingType = state.selectedUserType;
      final List<String> selectedDiseasesList = state.selectedDiseases.toList();

      // 3. AddedPerson 객체 생성 (동기)
      final newPerson = AddedPerson(
        id: const Uuid().v4(),
        name: name.trim(),
        birthDate: state.selectedBirthDate,
        gu: state.selectedGu,
        dong: state.selectedDong,
        gender: state.selectedGender,
        isPregnant: state.selectedIsPregnant, // 상태에서 가져옴
        latitude: coords.latitude,
        longitude: coords.longitude,
        workingType: selectedWorkingType == '없음' ? null : selectedWorkingType,
        diseases: selectedDiseasesList.isNotEmpty ? selectedDiseasesList : null,
      );

      // 4. 정보 저장 (SharedPreferences 비동기)
      // 임신 여부 저장은 사람 정보에 포함되므로 별도 호출 불필요
      // await _prefsService.saveIsPregnant(state.selectedIsPregnant);
      await _prefsService.addPerson(newPerson);

      // `mounted` 확인: SharedPreferences 저장 후
      if (!mounted) return;

      // 5. 완료 상태 업데이트
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
      print('${newPerson.name}님이 추가되었습니다.');
    } catch (e) {
      print('Error adding person: $e');
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(errorMessage: '사람 추가 중 오류: $e', isSaving: false);
    }
  }
}

// --- Provider 정의 ---
final addPersonNotifierProvider =
    StateNotifierProvider<AddPersonNotifier, AddPersonState>((ref) {
      return AddPersonNotifier(
        ref.read(apiServiceProvider),
        ref.read(preferencesServiceProvider),
      );
    });
