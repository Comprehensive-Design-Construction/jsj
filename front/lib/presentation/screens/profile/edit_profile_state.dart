import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import '../../../data/models/added_person.dart';

@immutable
class EditProfileState extends Equatable {
  final bool isLoading;
  final bool isSaving;

  // final Map<String, bool> initialUserTypeSelection; // <<< 제거 (필요시 단일 String으로 변경)
  final String? initialUserType; // <<< 추가: 로드된 초기 사용자 특성

  final DateTime? initialBirthDate;
  final DateTime? selectedBirthDate;
  // final Map<String, bool> selectedUserTypeSelection; // <<< 제거
  final String? selectedUserType; // <<< 추가: UI에서 선택된 사용자 특성
  final String? selectedGender;
  final String? selectedGu;
  final String? selectedDong;

  final String? errorMessage;
  final List<String> guList;
  final List<String> dongList;
  final bool isLoadingLocationData;
  final bool savedSuccessfully;

  // 사용 가능한 사용자 특성 목록
  static const List<String> availableUserTypes = [
    '없음',
    '농촌',
    '비닐하우스',
    '실외작업자_도로',
    '실외작업자_건설현장',
    '실외작업자_조선소',
  ];

  const EditProfileState({
    this.isLoading = true,
    this.isSaving = false,
    this.initialBirthDate,
    // this.initialUserTypeSelection = const { ... }, // <<< 제거
    this.initialUserType, // <<< 추가
    this.selectedBirthDate,
    // this.selectedUserTypeSelection = const { ... }, // <<< 제거
    this.selectedUserType, // <<< 추가
    this.selectedGender,
    this.errorMessage,
    this.selectedGu,
    this.selectedDong,
    this.guList = const [],
    this.dongList = const [],
    this.isLoadingLocationData = true, // 초기값 true 유지 (loadUserData에서 관리)
    this.savedSuccessfully = false,
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    DateTime? initialBirthDate,
    // Map<String, bool>? initialUserTypeSelection, // <<< 제거
    String? initialUserType, // <<< 추가
    DateTime? selectedBirthDate,
    // Map<String, bool>? selectedUserTypeSelection, // <<< 제거
    String? selectedUserType, // <<< 추가
    bool clearSelectedUserType = false, // <<< 추가
    String? selectedGender,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    List<String>? guList,
    List<String>? dongList,
    bool? isLoadingLocationData,
    bool? savedSuccessfully,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      initialBirthDate: initialBirthDate ?? this.initialBirthDate,
      // initialUserTypeSelection: initialUserTypeSelection ?? this.initialUserTypeSelection, // <<< 제거
      initialUserType: initialUserType ?? this.initialUserType, // <<< 추가
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      // selectedUserTypeSelection: selectedUserTypeSelection ?? this.selectedUserTypeSelection, // <<< 제거
      selectedUserType:
          clearSelectedUserType
              ? null
              : selectedUserType ?? this.selectedUserType, // <<< 수정
      selectedGender: selectedGender ?? this.selectedGender,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      selectedGu: clearSelectedGu ? null : selectedGu ?? this.selectedGu,
      selectedDong:
          clearSelectedDong ? null : selectedDong ?? this.selectedDong,
      guList: guList ?? this.guList,
      dongList: dongList ?? this.dongList,
      isLoadingLocationData:
          isLoadingLocationData ?? this.isLoadingLocationData,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    initialBirthDate,
    // initialUserTypeSelection, // <<< 제거
    initialUserType, // <<< 추가
    selectedBirthDate,
    // selectedUserTypeSelection, // <<< 제거
    selectedUserType, // <<< 추가
    selectedGender,
    errorMessage,
    selectedGu,
    selectedDong,
    guList,
    dongList,
    isLoadingLocationData,
    savedSuccessfully,
  ];
}
