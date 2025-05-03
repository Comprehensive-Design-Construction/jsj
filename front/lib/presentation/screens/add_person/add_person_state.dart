import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // DateTime 사용

// AddPersonScreen의 상태를 정의하는 클래스
@immutable
class AddPersonState extends Equatable {
  // 폼 입력 관련 상태
  final DateTime? selectedBirthDate;
  final String? selectedGu;
  final String? selectedDong;
  final Map<String, bool> userTypeSelection;

  // 데이터 로딩 상태
  final bool isLoadingGu;
  final List<String> guList;
  final bool isLoadingDong;
  final List<String> dongList;
  final bool isSaving; // 저장 중 로딩 상태

  // 기타 상태
  final String? errorMessage; // 오류 메시지
  final bool savedSuccessfully; // 저장 성공 여부 (화면 전환 트리거용)

  // 생성자
  const AddPersonState({
    this.selectedBirthDate,
    this.selectedGu,
    this.selectedDong,
    this.userTypeSelection = const {
      // 기본값 설정
      '농촌': false,
      '비닐하우스': false,
      '실외작업자': false,
    },
    this.isLoadingGu = false,
    this.guList = const [],
    this.isLoadingDong = false,
    this.dongList = const [],
    this.isSaving = false,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  // copyWith 메소드
  AddPersonState copyWith({
    DateTime? selectedBirthDate,
    String? selectedGu,
    bool clearSelectedGu = false, // 선택 해제 옵션
    String? selectedDong,
    bool clearSelectedDong = false, // 선택 해제 옵션
    Map<String, bool>? userTypeSelection,
    bool? isLoadingGu,
    List<String>? guList,
    bool? isLoadingDong,
    List<String>? dongList,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? savedSuccessfully,
  }) {
    return AddPersonState(
      // 조건부 null 할당 및 clear 옵션 처리
      selectedBirthDate: selectedBirthDate ?? this.selectedBirthDate,
      selectedGu: clearSelectedGu ? null : selectedGu ?? this.selectedGu,
      selectedDong:
          clearSelectedDong ? null : selectedDong ?? this.selectedDong,
      userTypeSelection: userTypeSelection ?? this.userTypeSelection,
      isLoadingGu: isLoadingGu ?? this.isLoadingGu,
      guList: guList ?? this.guList,
      isLoadingDong: isLoadingDong ?? this.isLoadingDong,
      dongList: dongList ?? this.dongList,
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
    userTypeSelection,
    isLoadingGu,
    guList,
    isLoadingDong,
    dongList,
    isSaving,
    errorMessage,
    savedSuccessfully,
  ];
}
