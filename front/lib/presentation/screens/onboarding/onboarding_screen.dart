import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../main/main_screen.dart';
import 'onboarding_notifier.dart'; // Notifier import
import 'onboarding_state.dart'; // State import
import '../../../data/models/added_person.dart';

// ConsumerStatefulWidget으로 변경
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ConsumerState로 변경
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController(); // 이름 컨트롤러는 로컬 상태 유지
  // Form Key 추가 (유효성 검사 위함)
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

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
        // 화면 전환 시 현재 context가 유효한지 확인
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

  // 생년월일 선택 DatePicker 표시 (Notifier 호출)
  void _presentDatePicker() {
    final currentBirthDate =
        ref.read(onboardingNotifierProvider).selectedBirthDate;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        notifier.setBirthDate(date);
      },
      currentTime:
          currentBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
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

  // 에러 메시지 SnackBar 표시 헬퍼
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        // Form 위젯으로 감싸기
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 로고 (기존과 동일)
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

                // 2. 이름 입력 (로컬 컨트롤러 사용)
                TextFormField(
                  // TextField -> TextFormField 변경
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '이름',
                    hintText: '이름을 입력하세요 (선택)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  // validator 추가 (선택사항, 이름은 필수가 아니므로 주석처리)
                  // validator: (value) {
                  //   if (value == null || value.trim().isEmpty) {
                  //     return '이름을 입력해주세요.';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                // <<< 성별 선택 UI 추가 >>>
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
                                : (value) {
                                  notifier.setGender(value);
                                },
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
                                : (value) {
                                  notifier.setGender(value);
                                },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // <<<------------------->>>
                Text('기타 정보', style: Theme.of(context).textTheme.titleSmall),
                CheckboxListTile(
                  title: const Text('임산부'),
                  value: state.selectedIsPregnant ?? false, // null이면 false로 간주
                  onChanged:
                      state.isSaving
                          ? null
                          : (bool? value) {
                            notifier.setIsPregnant(value);
                          },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  // activeColor: Colors.pinkAccent, // 색상 예시
                ),

                // 3. 생년월일 선택 (state.selectedBirthDate 사용)
                // TextFormField 대신 TextButton 유지, 유효성 검사는 버튼 클릭 시 Notifier에서
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed:
                      state.isSaving ? null : _presentDatePicker, // 저장 중 비활성화
                  child: Text(
                    state.selectedBirthDate == null
                        ? '생년월일 * (예: 1999.01.01)' // 필수 표시 추가
                        : '생년월일: ${DateFormat('yyyy.MM.dd').format(state.selectedBirthDate!)}',
                    style: TextStyle(
                      color:
                          state.selectedBirthDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- 지역 선택 UI 추가 ---
                Text('거주 지역 *', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                // 구 선택 드롭다운
                DropdownButtonFormField<String>(
                  value: state.selectedGu,
                  hint: Text(
                    state.isLoadingLocationData ? '불러오는 중...' : '구를 선택하세요',
                  ),
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items:
                      state.guList.map((String gu) {
                        return DropdownMenuItem<String>(
                          value: gu,
                          child: Text(gu),
                        );
                      }).toList(),
                  onChanged:
                      state.isLoadingLocationData || state.isSaving
                          ? null
                          : (String? newValue) {
                            notifier.setSelectedGu(newValue);
                          },
                  validator: (value) => value == null ? '구를 선택해주세요.' : null,
                ),
                const SizedBox(height: 12),
                // 동 선택 드롭다운
                DropdownButtonFormField<String>(
                  value: state.selectedDong,
                  hint: Text(
                    state.isLoadingLocationData
                        ? '불러오는 중...'
                        : (state.selectedGu == null
                            ? '구를 먼저 선택하세요'
                            : '동을 선택하세요'),
                  ),
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items:
                      (state.isLoadingLocationData || state.selectedGu == null)
                          ? []
                          : state.dongList.map((String dong) {
                            return DropdownMenuItem<String>(
                              value: dong,
                              child: Text(dong),
                            );
                          }).toList(),
                  onChanged:
                      (state.isLoadingLocationData ||
                              state.selectedGu == null ||
                              state.isSaving)
                          ? null
                          : (String? newValue) {
                            notifier.setSelectedDong(newValue);
                          },
                  validator:
                      (value) =>
                          (state.selectedGu != null && value == null)
                              ? '동을 선택해주세요.'
                              : null,
                ),
                const SizedBox(height: 24),

                // 4. 사용자 특성 선택 (state.userTypeSelection 사용)
                Text('사용자 특성', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state.selectedUserType, // <<< 상태 값 바인딩
                  hint: const Text('사용자 특성을 선택하세요'), // 힌트 텍스트
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  // items 목록: 해당 State 클래스에 정의된 availableUserTypes 사용
                  // 예: OnboardingState.availableUserTypes
                  items:
                      OnboardingState.availableUserTypes.map((String type) {
                        // <<< State 클래스의 목록 사용
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged:
                      state.isSaving
                          ? null
                          : (String? newValue) {
                            notifier.setUserType(
                              newValue,
                            ); // <<< Notifier의 새 함수 호출
                          },
                  // validator: (value) => value == null ? '사용자 특성을 선택해주세요.' : null, // 필요시 유효성 검사 추가
                ),
                const SizedBox(height: 24),

                // 5. 기저질환 Placeholder (기존과 동일)
                Text(
                  '기저질환 (중복 선택 가능)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                MultiSelectDialogField<String>(
                  items:
                      availableDiseases // app_constants 에 정의된 목록
                          .map(
                            (disease) =>
                                MultiSelectItem<String>(disease, disease),
                          )
                          .toList(),
                  initialValue:
                      state.selectedDiseases.toList(), // 현재 선택된 값 (List로 변환)
                  title: Text("기저질환 선택"), // 다이얼로그 제목
                  selectedColor: Colors.blueAccent, // 선택 항목 강조 색상
                  // --- 버튼 스타일링 ---
                  decoration: BoxDecoration(
                    // 버튼 모양 설정
                    color: Colors.grey[100], // 배경색
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  buttonIcon: Icon(
                    // 버튼 옆 아이콘
                    Icons.arrow_drop_down,
                    color: Colors.grey[700],
                  ),
                  buttonText: Text(
                    // 버튼에 표시될 텍스트
                    state.selectedDiseases.isEmpty
                        ? "기저질환을 선택하세요 (선택)"
                        : state.selectedDiseases.join(
                          ', ',
                        ), // 선택된 항목 표시 (쉼표 구분)
                    style: TextStyle(
                      color:
                          state.selectedDiseases.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis, // 길면 ... 처리
                  ),
                  // --- 다이얼로그 설정 ---
                  listType:
                      MultiSelectListType
                          .LIST, // 다이얼로그 내 항목 표시 방식 (LIST 또는 CHIP)
                  searchable: true, // 검색 기능 활성화
                  searchHint: '검색',
                  confirmText: Text('확인'),
                  cancelText: Text('취소'),
                  // --- 선택 완료 시 콜백 ---
                  onConfirm: (results) {
                    // results는 선택된 항목들의 List<String>
                    // Notifier의 새 함수 호출하여 상태 업데이트
                    notifier.setSelectedDiseases(results.toSet());
                  },
                  // --- 선택된 항목 표시 방식 (버튼 아래 Chip) ---
                  chipDisplay: MultiSelectChipDisplay<String>(
                    chipColor: Colors.blueAccent.withOpacity(0.15),
                    textStyle: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                    ),
                    // 아이콘 버튼으로 개별 삭제 기능 (선택적)
                    icon: Icon(Icons.close, color: Colors.blueAccent, size: 16),
                    onTap: (value) {
                      // 개별 Chip 탭 시 제거 (toggle 함수 필요)
                      notifier.toggleDiseaseSelection(value);
                    },
                    // 스크롤 가능하게 하려면 scrollbar 추가
                    // scrollBar: HorizontalScrollBar(),
                  ),
                  // validator: (value) { ... } // 필요시 유효성 검사
                ),
                const SizedBox(height: 40),

                // 6. 시작 버튼 (Notifier 함수 호출, Form 유효성 검사 추가)
                ElevatedButton(
                  onPressed:
                      state.isSaving
                          ? null
                          : () {
                            // Form 유효성 검사
                            if (_formKey.currentState?.validate() ?? false) {
                              // 생년월일 null 체크는 Notifier 에서 수행
                              notifier.startApp(_nameController.text);
                            } else {
                              // 유효성 검사 실패 시 메시지 표시 (선택적)
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

                // 7. 간편시작 버튼 (Notifier 함수 호출)
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
