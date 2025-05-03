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

  void toggleUserType(String type, bool value) {
    final currentSelection = Map<String, bool>.from(state.userTypeSelection);
    currentSelection[type] = value;
    state = state.copyWith(userTypeSelection: currentSelection);
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

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      // 1. 위경도 좌표 조회
      final CoordinatesResponse coords = await _apiService.fetchCoordinates(
        state.selectedGu!,
        state.selectedDong!,
      );

      // 2. 저장할 데이터 준비
      final age = _calculateAge(state.selectedBirthDate);
      final selectedTypes =
          state.userTypeSelection.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
      // TODO: 기저질환 리스트 가져오기
      final List<String> diseaseParam = [...selectedTypes /*, ...diseases*/];

      // 3. AddedPerson 객체 생성
      final newPerson = AddedPerson(
        id: const Uuid().v4(), // 고유 ID 생성
        name: name.trim(), // 전달받은 이름 사용
        birthDate: state.selectedBirthDate,
        gu: state.selectedGu,
        dong: state.selectedDong,
        latitude: coords.latitude,
        longitude: coords.longitude,
        userTypes: diseaseParam.isNotEmpty ? diseaseParam : null,
      );

      // 4. 로컬 저장소에 추가
      await _prefsService.addPerson(newPerson);

      // 5. 성공 상태 업데이트
      state = state.copyWith(isSaving: false, savedSuccessfully: true);
      print('${newPerson.name}님이 추가되었습니다.');
    } catch (e) {
      // 오류 처리
      state = state.copyWith(errorMessage: '사람 추가 중 오류: $e', isSaving: false);
      print('Error adding person: $e');
    } finally {
      // 저장 시도 후에는 savedSuccessfully 상태를 다시 false로 초기화 (연속 추가 대비)
      // 단, 화면 전환 후 초기화하거나 다른 방식 사용 가능
      // state = state.copyWith(savedSuccessfully: false); // <<< 위치 주의: 화면 전환 후가 더 나을 수 있음
    }
  }

  // Notifier가 제거될 때 savedSuccessfully 상태 초기화 (선택적)
  // @override
  // void dispose() {
  //   // 필요한 경우 정리 로직
  //   super.dispose();
  // }
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
