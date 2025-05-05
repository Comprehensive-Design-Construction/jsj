import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart'; // DateTime 사용 위해 추가

import '../../../data/models/added_person.dart';

@immutable
class OnboardingState extends Equatable {
  final DateTime? selectedBirthDate;
  // final Map<String, bool> userTypeSelection;
  final String? selectedUserType;
  final String? selectedGu;
  final String? selectedDong;
  final List<String> guList;
  final List<String> dongList;
  final bool isLoadingLocationData;
  final String? selectedGender; // <<< 성별 상태 추가
  final bool isSaving;
  final String? errorMessage;
  final bool onboardingProcessComplete;

  static const List<String> availableUserTypes = [
    '없음',
    '농촌',
    '비닐하우스',
    '실외작업자_도로',
    '실외작업자_건설현장',
    '실외작업자_조선소',
  ];

  const OnboardingState({
    this.selectedBirthDate,
    // this.userTypeSelection = const {
    //   '농촌': false,
    //   '비닐하우스': false,
    //   '실외작업자': false,
    // },
    this.selectedUserType,
    this.selectedGu,
    this.selectedDong,
    this.guList = const [],
    this.dongList = const [],
    this.isLoadingLocationData = true,
    this.selectedGender, // <<< 초기값 null
    this.isSaving = false,
    this.errorMessage,
    this.onboardingProcessComplete = false,
  });

  OnboardingState copyWith({
    DateTime? selectedBirthDate,
    // Map<String, bool>? userTypeSelection,
    String? selectedUserType,
    bool clearSelectedUserType = false,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    List<String>? guList,
    List<String>? dongList,
    bool? isLoadingLocationData,
    String? selectedGender, // <<< copyWith에 추가
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? onboardingProcessComplete,
  }) {
    return OnboardingState(
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      // userTypeSelection: userTypeSelection ?? this.userTypeSelection,
      selectedUserType:
          clearSelectedUserType
              ? null
              : selectedUserType ?? this.selectedUserType,
      selectedGu: clearSelectedGu ? null : selectedGu ?? this.selectedGu,
      selectedDong:
          clearSelectedDong ? null : selectedDong ?? this.selectedDong,
      guList: guList ?? this.guList,
      dongList: dongList ?? this.dongList,
      isLoadingLocationData:
          isLoadingLocationData ?? this.isLoadingLocationData,
      selectedGender: selectedGender ?? this.selectedGender, // <<< 추가
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      onboardingProcessComplete:
          onboardingProcessComplete ?? this.onboardingProcessComplete,
    );
  }

  @override
  List<Object?> get props => [
    selectedBirthDate,
    // userTypeSelection,
    selectedUserType,
    selectedGu,
    selectedDong,
    guList,
    dongList,
    isLoadingLocationData,
    selectedGender, // <<< props에 추가
    isSaving,
    errorMessage,
    onboardingProcessComplete,
  ];
}
