import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart'; // 이제 Notifier에서 사용

import '../../../core/constants/app_constants.dart';
// import '../../../core/utils/preferences_service.dart'; // Notifier에서 사용
// import '../../../data/models/added_person.dart'; // Notifier에서 사용
// import '../../../data/models/api/coordinates_response.dart'; // Notifier에서 사용
// import '../../../data/services/api_service.dart'; // Notifier에서 사용
import 'add_person_notifier.dart'; // Notifier import
import 'add_person_state.dart'; // State import
import '../../../data/models/added_person.dart';

// ConsumerStatefulWidget으로 변경
class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

// ConsumerState로 변경
class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  // ApiService, PreferencesService 인스턴스 제거 -> Notifier에서 관리

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // 이름 컨트롤러는 로컬 상태로 유지

  // 상태 변수들 제거 -> Riverpod State에서 관리

  @override
  void initState() {
    super.initState();
    // initState에서 데이터 로딩 로직 제거 -> Notifier 생성 시 처리
    // _fetchGuData();

    // Notifier의 저장 성공 상태를 감지하여 화면 전환
    // Listener를 사용하여 상태 변경 시 특정 액션 수행
    ref.listenManual(addPersonNotifierProvider, (previous, next) {
      // 에러 메시지 표시 (SnackBar)
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }

      // 저장 성공 시 이전 화면으로 돌아가기 (true 전달)
      if (next.savedSuccessfully) {
        // 성공 메시지 (Notifier에서 처리해도 됨)
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('${_nameController.text.trim()}님이 추가되었습니다.'), // 이름 접근 주의
        //     duration: Duration(seconds: 2),
        //   ),
        // );
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // _fetchGuData, _fetchDongData, _calculateAge, _addPerson 함수 제거 -> Notifier로 이동

  // 생년월일 선택 DatePicker (Notifier 호출 방식으로 변경)
  void _presentDatePicker() {
    // 현재 상태의 생년월일 가져오기
    final currentBirthDate =
        ref.read(addPersonNotifierProvider).selectedBirthDate;

    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        // Notifier를 통해 상태 업데이트
        ref.read(addPersonNotifierProvider.notifier).setBirthDate(date);
      },
      currentTime:
          currentBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
      theme: const picker.DatePickerTheme(/* 테마 설정 */),
    );
  }

  // 에러 메시지 SnackBar 표시 헬퍼 (기존과 동일)
  void _showErrorSnackBar(String message) {
    // 이전에 표시된 SnackBar가 있다면 제거
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상태 구독
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
              // --- 이름 ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름 *',
                  hintText: '추가할 사람의 이름을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 성별
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

              // --- 생년월일 ---
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey[700],
                ),
                label: Text(
                  state.selectedBirthDate == null
                      ? '생년월일 선택 *'
                      : DateFormat(
                        'yyyy년 MM월 dd일',
                      ).format(state.selectedBirthDate!),
                  style: TextStyle(
                    color:
                        state.selectedBirthDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                    fontSize: 16,
                  ),
                ),
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
                  foregroundColor: Colors.black87,
                ),
                onPressed: _presentDatePicker, // 수정된 함수 호출
              ),
              const SizedBox(height: 24),

              // --- 지역 선택 ---
              Text('거주 지역 *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              // 구 선택 드롭다운
              DropdownButtonFormField<String>(
                value: state.selectedGu,
                hint: Text(state.isLoadingGu ? '불러오는 중...' : '구를 선택하세요'),
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
                      // state에서 목록 가져옴
                      return DropdownMenuItem<String>(
                        value: gu,
                        child: Text(gu),
                      );
                    }).toList(),
                onChanged:
                    state.isLoadingGu
                        ? null
                        : (String? newValue) {
                          // Notifier 함수 호출
                          notifier.setSelectedGu(newValue);
                        },
                validator: (value) => value == null ? '구를 선택해주세요.' : null,
              ),
              const SizedBox(height: 12),
              // 동 선택 드롭다운
              DropdownButtonFormField<String>(
                value: state.selectedDong,
                hint: Text(
                  state.isLoadingDong
                      ? '불러오는 중...'
                      : (state.selectedGu == null ? '구를 먼저 선택하세요' : '동을 선택하세요'),
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
                    state.dongList.map((String dong) {
                      // state에서 목록 가져옴
                      return DropdownMenuItem<String>(
                        value: dong,
                        child: Text(dong),
                      );
                    }).toList(),
                onChanged:
                    (state.selectedGu == null || state.isLoadingDong)
                        ? null
                        : (String? newValue) {
                          // Notifier 함수 호출
                          notifier.setSelectedDong(newValue);
                        },
                validator:
                    (value) =>
                        (state.selectedGu != null && value == null)
                            ? '동을 선택해주세요.'
                            : null,
              ),
              const SizedBox(height: 24),

              // --- 사용자 특성 ---
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
                    AddPersonState.availableUserTypes.map((String type) {
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

              // --- 기저질환 Placeholder ---
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
                      : state.selectedDiseases.join(', '), // 선택된 항목 표시 (쉼표 구분)
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
                    MultiSelectListType.LIST, // 다이얼로그 내 항목 표시 방식 (LIST 또는 CHIP)
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
                  textStyle: TextStyle(color: Colors.blueAccent, fontSize: 13),
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

              // --- 추가하기 버튼 ---
              ElevatedButton(
                onPressed:
                    state
                            .isSaving // state에서 로딩 상태 확인
                        ? null
                        : () {
                          // Form 유효성 검사 후 Notifier 함수 호출
                          if (_formKey.currentState?.validate() ?? false) {
                            notifier.addPerson(_nameController.text);
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
                    state
                            .isSaving // state에서 로딩 상태 확인
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

              // 에러 메시지 표시는 initState의 listener에서 SnackBar로 처리하므로 제거 가능
              // if (state.errorMessage != null) ...
            ],
          ),
        ),
      ),
    );
  }
}
