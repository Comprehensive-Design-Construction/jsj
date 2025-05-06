import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../main/main_screen.dart';
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';
import '../../../data/models/added_person.dart';
// 공용 폼 위젯 import
import '../../widgets/common/form/labeled_text_form_field.dart';
import '../../widgets/common/form/labeled_dropdown_form_field.dart';
import '../../widgets/common/form/labeled_date_picker_button.dart';
import '../../widgets/common/form/labeled_multi_select_field.dart';

// 기존 OnboardingScreen 클래스 이름을 변경하거나 이 클래스 사용
class OnboardingInfoInputScreen extends ConsumerStatefulWidget {
  const OnboardingInfoInputScreen({super.key});
  @override
  ConsumerState<OnboardingInfoInputScreen> createState() =>
      _OnboardingInfoInputScreenState();
}

class _OnboardingInfoInputScreenState
    extends ConsumerState<OnboardingInfoInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // 이름 컨트롤러 유지

  @override
  void initState() {
    super.initState();
    // Listener 등록 (startApp 완료 시 네비게이션 및 에러 처리)
    ref.listenManual<OnboardingState>(onboardingNotifierProvider, (
      previous,
      next,
    ) {
      // 정보 입력 후 완료 시 메인 화면으로 이동
      if (next.onboardingProcessComplete &&
          previous?.onboardingProcessComplete == false) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) => false, // 모든 이전 경로를 제거합니다.
          );
        }
      }
      // 에러 메시지 표시
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그 표시 함수 (기존과 동일)
  void _presentDatePicker() {
    final currentBirthDate =
        ref.read(onboardingNotifierProvider).selectedBirthDate;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) => notifier.setBirthDate(date),
      currentTime:
          currentBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
      // 필요시 DatePickerTheme 설정
      theme: const picker.DatePickerTheme(
        headerColor: Colors.white,
        backgroundColor: Colors.white,
        itemStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        doneStyle: TextStyle(
          color: Colors.blueAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        cancelStyle: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  // 에러 스낵바 표시 함수 (기존과 동일)
  void _showErrorSnackBar(String message) {
    // 현재 빌드 프레임이 완료된 후 다음 프레임에서 실행되도록 지연
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return; // 위젯이 마운트 해제되지 않았는지 다시 확인

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      // AppBar 추가
      appBar: AppBar(
        title: const Text('정보 입력'),
        leading: IconButton(
          // 뒤로가기 버튼 (WelcomeScreen으로 돌아감)
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 로고 제거 ---
                // Padding( ... Image.asset ... ) 부분 제거

                // --- 이름 입력 (기존과 동일) ---
                LabeledTextFormField(
                  label: '이름',
                  controller: _nameController,
                  hintText: '이름을 입력하세요 (선택)',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // --- 성별 선택 (기존과 동일) ---
                Text('성별 *', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('남성'),
                        value: Gender.male,
                        groupValue: state.selectedGender,
                        onChanged:
                            state.isSaving
                                ? null
                                : (v) => notifier.setGender(v),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('여성'),
                        value: Gender.female,
                        groupValue: state.selectedGender,
                        onChanged:
                            state.isSaving
                                ? null
                                : (v) => notifier.setGender(v),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 기타 정보 (임산부) (기존과 동일) ---
                Text('기타 정보', style: Theme.of(context).textTheme.titleSmall),
                CheckboxListTile(
                  title: const Text('임산부'),
                  value: state.selectedIsPregnant ?? false,
                  onChanged:
                      state.isSaving ? null : (v) => notifier.setIsPregnant(v),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // --- 생년월일 선택 (기존과 동일 - _presentDatePicker 호출 방식 대신 LabeledDatePickerButton 사용) ---
                LabeledDatePickerButton(
                  label: '생년월일',
                  selectedDate: state.selectedBirthDate,
                  isRequired: true,
                  isEnabled: !state.isSaving,
                  onConfirm: (date) => notifier.setBirthDate(date),
                ),
                const SizedBox(height: 24),

                // --- 지역 선택 (구) (기존과 동일) ---
                LabeledDropdownFormField<String>(
                  label: '거주 지역 (구)',
                  value: state.selectedGu,
                  hintText: '구를 선택하세요',
                  isRequired: true,
                  isLoading: state.isLoadingLocationData,
                  errorText: state.locationErrorText, // 에러 텍스트 전달
                  items:
                      state.guList
                          .map(
                            (gu) => DropdownMenuItem<String>(
                              value: gu,
                              child: Text(gu),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isSaving || state.locationErrorText != null
                          ? null
                          : (v) => notifier.setSelectedGu(v),
                  validator: (value) => value == null ? '구를 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),

                // --- 지역 선택 (동) (기존과 동일) ---
                LabeledDropdownFormField<String>(
                  label: '거주 지역 (동)',
                  value: state.selectedDong,
                  hintText:
                      state.selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요',
                  isRequired: true,
                  isLoading: state.isLoadingLocationData,
                  errorText: state.locationErrorText, // 에러 텍스트 전달
                  items:
                      state.dongList
                          .map(
                            (dong) => DropdownMenuItem<String>(
                              value: dong,
                              child: Text(dong),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (state.selectedGu == null ||
                              state.isLoadingLocationData ||
                              state.isSaving ||
                              state.locationErrorText != null)
                          ? null
                          : (v) => notifier.setSelectedDong(v),
                  validator:
                      (value) =>
                          (state.selectedGu != null && value == null)
                              ? '동을 선택해주세요.'
                              : null,
                ),
                const SizedBox(height: 24),

                // --- 사용자 특성 선택 (기존과 동일) ---
                LabeledDropdownFormField<String>(
                  label: '사용자 특성',
                  value: state.selectedUserType,
                  hintText: '사용자 특성을 선택하세요 (선택)',
                  items:
                      OnboardingState.availableUserTypes
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isSaving ? null : (v) => notifier.setUserType(v),
                ),
                const SizedBox(height: 24),

                // --- 기저질환 선택 (기존과 동일) ---
                LabeledMultiSelectField<String>(
                  label: '기저질환 (중복 선택 가능)',
                  items:
                      availableDiseases
                          .map((d) => MultiSelectItem<String>(d, d))
                          .toList(),
                  initialValue: state.selectedDiseases.toList(),
                  buttonHint: "기저질환을 선택하세요 (선택)",
                  dialogTitle: "기저질환 선택",
                  searchHint: "검색",
                  isEnabled: !state.isSaving,
                  onConfirm:
                      (results) =>
                          notifier.setSelectedDiseases(results.toSet()),
                  onItemTapped: (item) => notifier.toggleDiseaseSelection(item),
                ),
                const SizedBox(height: 40),

                // --- "시작", "간편시작" 버튼 제거하고 "완료" 버튼 추가 ---
                ElevatedButton(
                  onPressed:
                      state.isSaving
                          ? null
                          : () {
                            // 폼 유효성 검사
                            if (_formKey.currentState?.validate() ?? false) {
                              // 지역 로딩 에러 추가 확인
                              if (state.locationErrorText == null) {
                                // 유효하면 정보 저장 로직 호출
                                notifier.startApp(_nameController.text);
                              } else {
                                _showErrorSnackBar(
                                  '지역 정보를 불러오는 중 오류가 발생했습니다. 다시 시도해주세요.',
                                );
                              }
                            } else {
                              _showErrorSnackBar('필수 정보를 모두 입력해주세요.');
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child:
                      state.isSaving
                          ? const SizedBox(
                            // 저장 중 로딩 표시
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text('완료'), // 버튼 텍스트 변경
                ),
                // const SizedBox(height: 12), // 간편시작 버튼 제거
                // TextButton(...) // 간편시작 버튼 제거
              ],
            ),
          ),
        ),
      ),
    );
  }
}
