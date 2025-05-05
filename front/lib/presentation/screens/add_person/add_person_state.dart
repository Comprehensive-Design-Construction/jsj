import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // DateTime 사용

@immutable
class AddPersonState extends Equatable {
  final DateTime? selectedBirthDate;
  final bool? initialIsPregnant;
  final bool? selectedIsPregnant;
  final Set<String> selectedDiseases; // <<< 추가
  final String? selectedGu;
  final String? selectedDong;
  final String? selectedGender;
  // final Map<String, bool> userTypeSelection; // <<< 제거
  final String? selectedUserType; // <<< 추가
  final bool isLoadingGu;
  final List<String> guList;
  final bool isLoadingDong;
  final List<String> dongList;
  final String? locationErrorText; // <<< 지역 로딩 에러 메시지 추가
  final bool isSaving;
  final String? errorMessage;
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

  const AddPersonState({
    this.selectedBirthDate,
    this.selectedGu,
    this.selectedDong,
    // this.userTypeSelection = const { ... }, // <<< 제거
    this.selectedUserType, // <<< 추가
    this.initialIsPregnant,
    this.selectedIsPregnant,
    this.selectedDiseases = const {}, // <<< 기본값 빈 Set
    this.isLoadingGu = false,
    this.guList = const [],
    this.isLoadingDong = false,
    this.dongList = const [],
    this.locationErrorText, // <<< 추가
    this.selectedGender,
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  AddPersonState copyWith({
    DateTime? selectedBirthDate,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    // Map<String, bool>? userTypeSelection, // <<< 제거
    String? selectedUserType, // <<< 추가
    bool? initialIsPregnant,
    bool? selectedIsPregnant,
    bool clearSelectedUserType = false, // <<< 추가
    bool? isLoadingGu,
    List<String>? guList,
    bool? isLoadingDong,
    List<String>? dongList,
    String? locationErrorText, // <<< 추가
    bool clearLocationErrorText = false, // <<< 추가
    String? selectedGender,
    Set<String>? selectedDiseases, // <<< 추가
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? savedSuccessfully,
  }) {
    return AddPersonState(
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      initialIsPregnant: initialIsPregnant ?? this.initialIsPregnant,
      selectedIsPregnant: selectedIsPregnant ?? this.selectedIsPregnant,
      selectedGu: clearSelectedGu ? null : selectedGu ?? this.selectedGu,
      selectedDong:
          clearSelectedDong ? null : selectedDong ?? this.selectedDong,
      // userTypeSelection: userTypeSelection ?? this.userTypeSelection, // <<< 제거
      selectedUserType:
          clearSelectedUserType
              ? null
              : selectedUserType ?? this.selectedUserType, // <<< 수정
      isLoadingGu: isLoadingGu ?? this.isLoadingGu,
      guList: guList ?? this.guList,
      isLoadingDong: isLoadingDong ?? this.isLoadingDong,
      dongList: dongList ?? this.dongList,
      locationErrorText:
          clearLocationErrorText
              ? null
              : locationErrorText ?? this.locationErrorText, // <<< 추가
      selectedGender: selectedGender ?? this.selectedGender,
      selectedDiseases: selectedDiseases ?? this.selectedDiseases, // <<< 추가
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  @override
  List<Object?> get props => [
    selectedBirthDate,
    selectedGu,
    selectedDong,
    // userTypeSelection, // <<< 제거
    selectedUserType, // <<< 추가
    initialIsPregnant,
    selectedIsPregnant,
    selectedDiseases, // <<< 추가
    isLoadingGu,
    guList,
    isLoadingDong,
    dongList,
    locationErrorText,
    selectedGender,
    isSaving,
    errorMessage,
    savedSuccessfully,
  ];
}
