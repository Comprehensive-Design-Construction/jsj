import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class EditProfileState extends Equatable {
  final bool isLoading; // 데이터 로딩 중 상태
  final bool isSaving; // 저장 중 상태
  final DateTime? initialBirthDate; // 로드된 초기 생년월일 (수정용)
  final Map<String, bool> initialUserTypeSelection; // 로드된 초기 사용자 특성
  final String? errorMessage;
  final bool savedSuccessfully; // 저장 성공 플래그

  const EditProfileState({
    this.isLoading = true,
    this.isSaving = false,
    this.initialBirthDate,
    this.initialUserTypeSelection = const {
      // 기본값
      '농촌': false,
      '비닐하우스': false,
      '실외작업자': false,
    },
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    DateTime? initialBirthDate,
    Map<String, bool>? initialUserTypeSelection,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? savedSuccessfully,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      initialBirthDate: initialBirthDate ?? this.initialBirthDate,
      initialUserTypeSelection:
          initialUserTypeSelection ?? this.initialUserTypeSelection,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    initialBirthDate,
    initialUserTypeSelection,
    errorMessage,
    savedSuccessfully,
  ];
}
