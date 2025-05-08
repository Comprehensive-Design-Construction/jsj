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
// --- 공용 폼 위젯 import ---
import '../../widgets/common/form/labeled_text_form_field.dart';
import '../../widgets/common/form/labeled_dropdown_form_field.dart';
import '../../widgets/common/form/labeled_date_picker_button.dart';
import '../../widgets/common/form/labeled_multi_select_field.dart';
// -------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listener 등록 (기존과 동일)
    ref.listenManual<OnboardingState>(onboardingNotifierProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }
      if (next.onboardingProcessComplete &&
          previous?.onboardingProcessComplete == false) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    /* 기존과 동일 */
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
      theme: const picker.DatePickerTheme(/* ... */),
    );
  }

  void _showErrorSnackBar(String message) {
    /* 기존과 동일 */
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 (기존과 동일)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Image.asset(
                    'assets/images/welogo.png',
                    height: 60,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const SizedBox(height: 60),
                  ),
                ),

                // --- 이름 입력 (LabeledTextFormField 사용) ---
                LabeledTextFormField(
                  label: '이름',
                  controller: _nameController,
                  hintText: '이름을 입력하세요 (선택)',
                  textInputAction: TextInputAction.next,
                  // isRequired: true, // 이름은 필수가 아니므로 false (기본값)
                ),
                const SizedBox(height: 16),

                // 성별 선택 (기존 RadioListTile 유지 - Labeled 위젯으로 만들기 애매)
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

                // 기타 정보 (기존 CheckboxListTile 유지)
                Text('기타 정보', style: Theme.of(context).textTheme.titleSmall),
                CheckboxListTile(
                  title: const Text('임산부'),
                  value: state.selectedIsPregnant ?? false,
                  onChanged:
                      state.isSaving ? null : (v) => notifier.setIsPregnant(v),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                // 생년월일 선택 (기존 TextButton 유지 - Labeled 위젯화 가능하나 일단 유지)
                LabeledDatePickerButton(
                  label: '생년월일',
                  selectedDate: state.selectedBirthDate,
                  isRequired: false,
                  isEnabled: !state.isSaving, // 저장 중 아닐 때만 활성화
                  onConfirm: (date) => notifier.setBirthDate(date),
                ),
                const SizedBox(height: 24),

                // --- 지역 선택 (LabeledDropdownFormField 사용) ---
                LabeledDropdownFormField<String>(
                  label: '거주 지역 (구)',
                  value: state.selectedGu,
                  hintText: '구를 선택하세요',
                  isRequired: true,
                  isLoading: state.isLoadingLocationData, // 로딩 상태 전달
                  items:
                      state.guList
                          .map(
                            (String gu) => DropdownMenuItem<String>(
                              value: gu,
                              child: Text(gu),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isSaving ? null : (v) => notifier.setSelectedGu(v),
                  validator: (value) => value == null ? '구를 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),
                LabeledDropdownFormField<String>(
                  label: '거주 지역 (동)',
                  value: state.selectedDong,
                  hintText:
                      state.selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요',
                  isRequired: true,
                  isLoading: state.isLoadingLocationData, // 구 로딩과 동일하게 처리
                  items:
                      state.dongList
                          .map(
                            (String dong) => DropdownMenuItem<String>(
                              value: dong,
                              child: Text(dong),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (state.selectedGu == null || state.isSaving)
                          ? null
                          : (v) => notifier.setSelectedDong(v),
                  validator:
                      (value) =>
                          (state.selectedGu != null && value == null)
                              ? '동을 선택해주세요.'
                              : null,
                ),
                const SizedBox(height: 24),

                // --- 사용자 특성 선택 (LabeledDropdownFormField 사용) ---
                LabeledDropdownFormField<String>(
                  label: '사용자 특성',
                  value: state.selectedUserType,
                  hintText: '사용자 특성을 선택하세요 (선택)',
                  items:
                      OnboardingState.availableUserTypes
                          .map(
                            (String type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged:
                      state.isSaving ? null : (v) => notifier.setUserType(v),
                  // isRequired: false, // 선택 사항
                ),
                const SizedBox(height: 24),

                // 기저질환 선택 (기존 MultiSelectDialogField 유지 - Labeled 위젯화 가능하나 일단 유지)
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
                  isEnabled: !state.isSaving, // 저장 중 아닐 때만 활성화
                  onConfirm:
                      (results) =>
                          notifier.setSelectedDiseases(results.toSet()),
                  onItemTapped:
                      (item) =>
                          notifier.toggleDiseaseSelection(item), // Chip 탭 시 제거
                ),
                const SizedBox(height: 40),

                // 시작 버튼 (기존과 동일)
                ElevatedButton(
                  onPressed:
                      state.isSaving
                          ? null
                          : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              notifier.startApp(_nameController.text);
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
                  ),
                  child:
                      state.isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text('시작'),
                ),
                const SizedBox(height: 12),
                // 간편시작 버튼 (기존과 동일)
                TextButton(
                  onPressed: state.isSaving ? null : notifier.simpleStartApp,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  child:
                      state.isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                          : const Text('간편시작'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
