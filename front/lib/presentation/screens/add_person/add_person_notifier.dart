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

  void resetState() {
    state = const AddPersonState(); // 초기 상태로 설정
    _fetchGuData(); // 구 목록 다시 로드
    print("[AddPersonNotifier] State reset.");
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
    if (!mounted) return;
    // 메서드 시작 시 isSaving을 true로 설정하고, 에러 메시지 초기화
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
      // locationErrorText는 버튼 클릭 시점에 이미 사용자에게 인지되었거나,
      // 버튼 활성화 조건에서 체크되었어야 하므로 여기서는 초기화하지 않거나,
      // 혹은 사용자가 다시 지역을 선택하도록 유도해야 합니다.
      // 여기서는 일단 그대로 두거나, 필요시 초기화합니다.
      // locationErrorText: null,
      // clearLocationErrorText: true,
    );

    // 유효성 검사: 각 실패 케이스에서 isSaving을 false로 되돌려줍니다.
    if (name.trim().isEmpty) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '이름을 입력해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }
    if (state.selectedBirthDate == null) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '생년월일을 선택해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }
    if (state.selectedGu == null) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '지역(구)을 선택해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }
    if (state.selectedDong == null) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '지역(동)을 선택해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }
    if (state.selectedGender == null) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '성별을 선택해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }
    // AddPersonScreen의 버튼 onPressed에서 이미 locationErrorText를 체크하므로,
    // 여기까지 왔다면 locationErrorText는 null이거나 사용자가 무시한 경우입니다.
    // 만약 여기서도 체크하려면:
    if (state.locationErrorText != null) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: '지역 정보를 다시 확인하고 선택해주세요.',
        isSaving: false,
      ); // isSaving: false 추가
      return;
    }

    print("[AddPersonNotifier] addPerson: Starting to add person '$name'");

    try {
      print("[AddPersonNotifier] addPerson: Fetching coordinates...");
      final CoordinatesResponse coords = await _apiService.fetchCoordinates(
        state.selectedGu!,
        state.selectedDong!,
      );
      if (!mounted) {
        print(
          "[AddPersonNotifier] addPerson: Not mounted after fetching coordinates. Aborting.",
        );
        state = state.copyWith(isSaving: false); // 중요: 여기서도 isSaving을 false로!
        return;
      }
      print(
        "[AddPersonNotifier] addPerson: Coordinates fetched: ${coords.latitude}, ${coords.longitude}",
      );

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
        isPregnant: state.selectedIsPregnant,
        latitude: coords.latitude,
        longitude: coords.longitude,
        workingType: selectedWorkingType == '없음' ? null : selectedWorkingType,
        diseases: selectedDiseasesList.isNotEmpty ? selectedDiseasesList : null,
      );

      print(
        "[AddPersonNotifier] addPerson: New person object created: ${newPerson.toJson()}",
      );

      print(
        "[AddPersonNotifier] addPerson: Saving person to SharedPreferences...",
      );
      await _prefsService.addPerson(newPerson);
      print(
        "[AddPersonNotifier] addPerson: Person saved to SharedPreferences.",
      );

      if (!mounted) {
        print(
          "[AddPersonNotifier] addPerson: Not mounted after saving to SharedPreferences. Aborting state update for success.",
        );
        // 이 경우 isSaving은 true로 남아있을 수 있으나, provider가 autoDispose면 정리됨.
        // autoDispose가 아니라면 여기서도 state = state.copyWith(isSaving: false); 고려.
        return;
      }

      print(
        "[AddPersonNotifier] addPerson: All async operations complete AND mounted is true. Updating state to success.",
      );
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
      print(
        "[AddPersonNotifier] addPerson: State updated. isSaving: ${state.isSaving}, savedSuccessfully: ${state.savedSuccessfully}",
      );
      print("'${newPerson.name}'님이 추가되었습니다.");
    } catch (e, s) {
      print("[AddPersonNotifier] addPerson: Error adding person: $e");
      print("[AddPersonNotifier] addPerson: Stacktrace: $s");
      if (!mounted) {
        print(
          "[AddPersonNotifier] addPerson: Not mounted during error handling.",
        );
        // 오류 발생 시 isSaving이라도 false로.
        // state = state.copyWith(isSaving: false); // Provider가 dispose되었을 수 있으므로 주의
        return;
      }
      state = state.copyWith(errorMessage: '사람 추가 중 오류: $e', isSaving: false);
      print(
        "[AddPersonNotifier] addPerson: Error state updated. isSaving: ${state.isSaving}, errorMessage: ${state.errorMessage}",
      );
    }
  }
}

// --- Provider 정의 ---
final addPersonNotifierProvider = StateNotifierProvider.autoDispose<
  AddPersonNotifier,
  AddPersonState
>((ref) {
  // '.autoDispose' 추가
  // autoDispose를 사용하면 이 Provider를 더 이상 사용하지 않을 때 자동으로 상태를 파기합니다.
  // AddPersonScreen이 닫힐 때 이 Notifier의 상태도 초기화됩니다.
  return AddPersonNotifier(
    ref.read(apiServiceProvider), // apiServiceProvider는 autoDispose가 아닐 수 있음
    ref.read(preferencesServiceProvider), // preferencesServiceProvider도 마찬가지
  );
});
