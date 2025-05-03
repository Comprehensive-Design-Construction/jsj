import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class OnboardingState extends Equatable {
  final DateTime? selectedBirthDate;
  final Map<String, bool> userTypeSelection;
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
    this.isSaving = false,
    this.errorMessage,
    this.onboardingProcessComplete = false,
  });

  OnboardingState copyWith({
    DateTime? selectedBirthDate,
    Map<String, bool>? userTypeSelection,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? onboardingProcessComplete,
  }) {
    return OnboardingState(
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      userTypeSelection: userTypeSelection ?? this.userTypeSelection,
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
    isSaving,
    errorMessage,
    onboardingProcessComplete,
  ];
}
