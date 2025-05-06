import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:front/presentation/screens/main/main_screen_notifier.dart';

import 'edit_profile_notifier.dart';
import 'edit_profile_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/added_person.dart';
// --- 공용 폼 위젯 import ---
import '../../widgets/common/form/labeled_dropdown_form_field.dart';
import '../../widgets/common/form/labeled_date_picker_button.dart';
import '../../widgets/common/form/labeled_multi_select_field.dart';
// -------------------------

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // final _nameController = TextEditingController(); // 이름 필드 제거됨

  @override
  void initState() {
    /* 기존과 동일 (Listener 부분 main_screen_notifier import 필요) */
    super.initState();
    ref.listenManual<EditProfileState>(editProfileNotifierProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }
      if (next.savedSuccessfully && previous?.savedSuccessfully == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보가 저장되었습니다.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // MainScreen 데이터 갱신 요청
        ref
            .read(mainScreenNotifierProvider.notifier)
            .loadDataForSelectedPerson(
              refresh: true,
            ); // ref.read 사용 시 import 필요
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    /* _nameController 관련 제거 */
    super.dispose();
  }

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
    final state = ref.watch(editProfileNotifierProvider);
    final notifier = ref.read(editProfileNotifierProvider.notifier);

    if (state.isLoading ||
        (state.isLoadingLocationData && state.guList.isEmpty)) {
      /* 로딩 UI 기존과 동일 */
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 성별 선택
              Text('성별 *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  /* 기존 RadioListTile */
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
              // 기타 정보
              Text('기타 정보', style: Theme.of(context).textTheme.titleSmall),
              CheckboxListTile(
                title: const Text('임산부'),
                value: state.selectedIsPregnant ?? false,
                onChanged:
                    // --- 수정 시작 ---
                    state.selectedGender ==
                            Gender
                                .male // 선택된 성별이 남성이면
                        ? null // onChanged를 null로 만들어 비활성화
                        : (v) => notifier.setIsPregnant(
                          v,
                        ), // 여성이거나 선택되지 않았으면 Notifier 함수 호출
                // --- 수정 종료 ---
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              // --- 생년월일 선택 (LabeledDatePickerButton 사용) ---
              LabeledDatePickerButton(
                label: '생년월일',
                selectedDate: state.selectedBirthDate,
                isRequired: true,
                isEnabled: !state.isSaving,
                onConfirm: (date) => notifier.setBirthDate(date),
              ),
              const SizedBox(height: 24),

              // 지역 선택 (기존 LabeledDropdownFormField 유지)
              LabeledDropdownFormField<String>(
                label: '거주 지역 (구)',
                value: state.selectedGu,
                hintText: '구를 선택하세요',
                isRequired: true,
                isLoading: state.isLoadingLocationData,
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
              ),
              const SizedBox(height: 12),
              LabeledDropdownFormField<String>(
                label: '거주 지역 (동)',
                value: state.selectedDong,
                hintText: state.selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요',
                isRequired: true,
                isLoading: state.isLoadingLocationData,
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
                            state.isSaving)
                        ? null
                        : (v) => notifier.setSelectedDong(v),
              ),
              const SizedBox(height: 24),

              // 사용자 특성 선택 (기존 LabeledDropdownFormField 유지)
              LabeledDropdownFormField<String>(
                label: '사용자 특성',
                value: state.selectedUserType,
                hintText: '사용자 특성을 선택하세요 (선택)',
                items:
                    EditProfileState.availableUserTypes
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

              // --- 기저질환 선택 (LabeledMultiSelectField 사용) ---
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

              // 저장 버튼 (Notifier 호출 로직 확인 - 상태값 직접 전달 제거 필요 시 Notifier 수정)
              ElevatedButton(
                onPressed:
                    state.isSaving
                        ? null
                        : () {
                          // Notifier가 자신의 상태를 사용하도록 변경했으므로 파라미터 불필요
                          notifier.saveProfile(
                            selectedGu:
                                state
                                    .selectedGu, // Screen의 현재 상태값을 넘겨주는 것이 안전할 수 있음
                            selectedDong: state.selectedDong,
                            selectedGender: state.selectedGender,
                          );
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
                        : const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
