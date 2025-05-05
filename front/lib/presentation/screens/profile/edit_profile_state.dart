import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class EditProfileState extends Equatable {
  final bool isLoading; // 데이터 로딩 중 상태
  final bool isSaving; // 저장 중 상태
  final DateTime? initialBirthDate; // 로드된 초기 생년월일 (수정용)
  final Map<String, bool> initialUserTypeSelection; // 로드된 초기 사용자 특성
  final String? errorMessage;
  // 구/동 선택 관련 상태
  final String? selectedGu;
  final String? selectedDong;
  final List<String> guList;
  final List<String> dongList;
  final bool isLoadingLocationData; // 구/동 목록 로딩 상태 통합
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
    this.selectedGu,
    this.selectedDong,
    this.guList = const [],
    this.dongList = const [],
    this.isLoadingLocationData = true, // 초기 로딩 상태 true
    this.savedSuccessfully = false,
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    DateTime? initialBirthDate,
    Map<String, bool>? initialUserTypeSelection,
    String? errorMessage,
    String? selectedGu,
    bool clearSelectedGu = false,
    String? selectedDong,
    bool clearSelectedDong = false,
    List<String>? guList,
    List<String>? dongList,
    bool? isLoadingLocationData,
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
    initialUserTypeSelection,
    errorMessage,
    selectedGu,
    selectedDong,
    guList,
    dongList,
    isLoadingLocationData,
    savedSuccessfully,
  ];
}
