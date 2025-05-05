import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart'; // DateTime 사용 위해 추가

@immutable
class OnboardingState extends Equatable {
  final DateTime? selectedBirthDate;
  final Map<String, bool> userTypeSelection;
  // 구/동 선택 관련 상태 추가
  final String? selectedGu;
  final String? selectedDong;
  final List<String> guList;
  final List<String> dongList;
  final bool isLoadingLocationData; // 구/동 목록 로딩 상태

  final bool isSaving; // 저장/진행 중 로딩 상태
  final String? errorMessage;
  final bool onboardingProcessComplete; // 온보딩 완료 및 화면 전환 트리거

  const OnboardingState({
    this.selectedBirthDate,
    this.userTypeSelection = const {
      // 기본값
      '농촌': false,
      '비닐하우스': false,
      '실외작업자': false,
    },
    // 구/동 상태 초기값
    this.selectedGu,
    this.selectedDong,
    this.guList = const [],
    this.dongList = const [],
    this.isLoadingLocationData = true, // 초기 로딩 true

    this.isSaving = false,
    this.errorMessage,
    this.onboardingProcessComplete = false,
  });

  OnboardingState copyWith({
    DateTime? selectedBirthDate,
    Map<String, bool>? userTypeSelection,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    List<String>? guList,
    List<String>? dongList,
    bool? isLoadingLocationData,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? onboardingProcessComplete,
  }) {
    return OnboardingState(
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      userTypeSelection: userTypeSelection ?? this.userTypeSelection,
      // 구/동 상태 copyWith
      selectedGu: clearSelectedGu ? null : selectedGu ?? this.selectedGu,
      selectedDong:
          clearSelectedDong ? null : selectedDong ?? this.selectedDong,
      guList: guList ?? this.guList,
      dongList: dongList ?? this.dongList,
      isLoadingLocationData:
          isLoadingLocationData ?? this.isLoadingLocationData,

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
    userTypeSelection,
    // 구/동 상태 props 추가
    selectedGu,
    selectedDong,
    guList,
    dongList,
    isLoadingLocationData,

    isSaving,
    errorMessage,
    onboardingProcessComplete,
  ];
}
