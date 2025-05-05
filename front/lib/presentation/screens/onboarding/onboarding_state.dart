import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart'; // DateTime 사용 위해 추가

import '../../../data/models/added_person.dart';

@immutable
class OnboardingState extends Equatable {
  final DateTime? selectedBirthDate;
  final bool? initialIsPregnant;
  final bool? selectedIsPregnant;
  final Set<String> selectedDiseases;
  final String? selectedUserType;
  final String? selectedGu;
  final String? selectedDong;
  final List<String> guList;
  final List<String> dongList;
  final bool isLoadingLocationData;
  final String? selectedGender;
  final bool isSaving;
  final String? errorMessage; // 저장/제출 관련 에러 메시지
  final String? locationErrorText; // <<< 지역 로딩 에러 메시지 추가
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
    this.selectedUserType,
    this.initialIsPregnant,
    this.selectedIsPregnant,
    this.selectedGu,
    this.selectedDong,
    this.guList = const [],
    this.dongList = const [],
    this.isLoadingLocationData = true,
    this.selectedGender,
    this.selectedDiseases = const {},
    this.isSaving = false,
    this.errorMessage,
    this.locationErrorText, // <<< 추가
    this.onboardingProcessComplete = false,
  });

  OnboardingState copyWith({
    DateTime? selectedBirthDate,
    String? selectedUserType,
    bool clearSelectedUserType = false,
    bool? initialIsPregnant,
    bool? selectedIsPregnant,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    List<String>? guList,
    List<String>? dongList,
    bool? isLoadingLocationData,
    String? selectedGender,
    Set<String>? selectedDiseases,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? locationErrorText, // <<< 추가
    bool clearLocationErrorText = false, // <<< 추가
    bool? onboardingProcessComplete,
  }) {
    return OnboardingState(
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      initialIsPregnant: initialIsPregnant ?? this.initialIsPregnant,
      selectedIsPregnant: selectedIsPregnant ?? this.selectedIsPregnant,
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
      selectedGender: selectedGender ?? this.selectedGender,
      selectedDiseases: selectedDiseases ?? this.selectedDiseases,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      locationErrorText:
          clearLocationErrorText
              ? null
              : locationErrorText ?? this.locationErrorText, // <<< 추가
      onboardingProcessComplete:
          onboardingProcessComplete ?? this.onboardingProcessComplete,
    );
  }

  @override
  List<Object?> get props => [
    selectedBirthDate,
    // userTypeSelection,
    selectedUserType,
    initialIsPregnant,
    selectedIsPregnant,
    selectedGu,
    selectedDong,
    guList,
    dongList,
    isLoadingLocationData,
    selectedGender, // <<< props에 추가
    selectedDiseases, // <<< 추가
    isSaving,
    errorMessage,
    locationErrorText,
    onboardingProcessComplete,
  ];
}
