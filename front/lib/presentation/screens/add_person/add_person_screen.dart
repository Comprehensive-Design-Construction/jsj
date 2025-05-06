import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import 'add_person_notifier.dart';
import 'add_person_state.dart';
import '../../../data/models/added_person.dart';
// --- 공용 폼 위젯 import ---
import '../../widgets/common/form/labeled_text_form_field.dart';
import '../../widgets/common/form/labeled_dropdown_form_field.dart';
import '../../widgets/common/form/labeled_date_picker_button.dart';
import '../../widgets/common/form/labeled_multi_select_field.dart';
// -------------------------

class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});
  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listener 등록 (기존과 동일)
    ref.listenManual(addPersonNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }
      if (next.savedSuccessfully) {
        Navigator.of(context).pop(true); // 저장 성공 시 true 반환하며 닫기
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
        ref.read(addPersonNotifierProvider).selectedBirthDate;
    final notifier = ref.read(addPersonNotifierProvider.notifier);
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
      theme: const picker.DatePickerTheme(/* 테마 설정 */),
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
    final state = ref.watch(addPersonNotifierProvider);
    final notifier = ref.read(addPersonNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사람 추가'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 이름 (LabeledTextFormField 사용) ---
              LabeledTextFormField(
                label: '이름',
                controller: _nameController,
                hintText: '추가할 사람의 이름을 입력하세요',
                isRequired: true,
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? '이름을 입력해주세요.'
                            : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 성별 선택 (기존 RadioListTile 유지)
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
                          state.isSaving ? null : (v) => notifier.setGender(v),
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
                          state.isSaving ? null : (v) => notifier.setGender(v),
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

              // 생년월일 선택 (기존 TextButton 유지)
              LabeledDatePickerButton(
                label: '생년월일',
                selectedDate: state.selectedBirthDate,
                isRequired: true,
                isEnabled: !state.isSaving,
                onConfirm: (date) => notifier.setBirthDate(date),
              ),
              const SizedBox(height: 24),

              // --- 지역 선택 (LabeledDropdownFormField 사용) ---
              LabeledDropdownFormField<String>(
                label: '거주 지역 (구)',
                value: state.selectedGu,
                hintText: '구를 선택하세요',
                isRequired: true,
                isLoading: state.isLoadingGu,
                errorText: state.locationErrorText, // <<< 전달
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
                    state.isSaving ? null : (v) => notifier.setSelectedGu(v),
                validator: (v) => v == null ? '구를 선택해주세요.' : null,
              ),
              const SizedBox(height: 12),
              // 지역 선택 (동) - errorText 전달
              LabeledDropdownFormField<String>(
                label: '거주 지역 (동)',
                value: state.selectedDong,
                hintText: state.selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요',
                isRequired: true,
                isLoading: state.isLoadingDong,
                errorText: state.locationErrorText, // <<< 전달
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
                            state.isLoadingDong ||
                            state.isSaving ||
                            state.locationErrorText != null)
                        ? null
                        : (v) => notifier.setSelectedDong(v), // 에러 시 비활성화
                validator:
                    (v) =>
                        (state.selectedGu != null && v == null)
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
                    AddPersonState.availableUserTypes
                        .map(
                          (String type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                onChanged:
                    state.isSaving ? null : (v) => notifier.setUserType(v),
              ),
              const SizedBox(height: 24),

              // 기저질환 선택 (기존 MultiSelectDialogField 유지)
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
                    (results) => notifier.setSelectedDiseases(results.toSet()),
                onItemTapped: (item) => notifier.toggleDiseaseSelection(item),
              ),
              const SizedBox(height: 40),

              // 추가하기 버튼 (기존과 동일)
              ElevatedButton(
                onPressed:
                    state.isSaving
                        ? null
                        : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            // 지역 로딩 에러 체크
                            if (state.locationErrorText == null) {
                              notifier.addPerson(_nameController.text);
                            } else {
                              _showErrorSnackBar('지역 정보를 확인해주세요.');
                            }
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
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                        : const Text('추가하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
