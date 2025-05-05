import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:front/presentation/screens/main/main_screen_notifier.dart';
import 'package:intl/intl.dart';

import 'edit_profile_notifier.dart'; // Notifier import
import 'edit_profile_state.dart'; // State import
import '../../../data/models/added_person.dart';

// ConsumerStatefulWidget으로 변경
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

// ConsumerState로 변경
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController(); // 이름은 로컬 상태로 유지

  // 로컬 상태: 사용자가 화면에서 수정하는 값들
  // DateTime? _selectedBirthDate;
  // String? _selectedGu; // 로컬 상태 추가
  // String? _selectedDong; // 로컬 상태 추가
  // Map<String, bool> _userTypeSelection = {
  //   '농촌': false,
  //   '비닐하우스': false,
  //   '실외작업자': false,
  // };

  @override
  void initState() {
    super.initState();

    // Notifier의 초기 데이터 로드가 완료되면 로컬 상태 업데이트
    ref.listenManual<EditProfileState>(editProfileNotifierProvider, (
      previous,
      next,
    ) {
      // 초기 데이터 로드 완료 시 로컬 상태 업데이트
      // isLoading과 isLoadingLocationData 모두 false일 때 UI 업데이트
      // if ((previous?.isLoading == true ||
      //         previous?.isLoadingLocationData == true) &&
      //     next.isLoading == false &&
      //     next.isLoadingLocationData == false) {
      //   if (next.initialBirthDate != null) {
      //     setState(() {
      //       _selectedBirthDate = next.initialBirthDate;
      //     });
      //   }
      //   // 구/동 초기값 설정 (Notifier의 selectedGu/Dong 사용)
      //   if (next.selectedGu != null) {
      //     // Notifier 상태를 로컬 상태로 동기화
      //     setState(() {
      //       _selectedGu = next.selectedGu;
      //       _selectedDong = next.selectedDong;
      //     });
      //   }
      //   setState(() {
      //     _userTypeSelection = Map.from(next.initialUserTypeSelection);
      //   });
      // }

      // 에러 메시지 표시
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }

      // 저장 성공 시 이전 화면으로 돌아가기
      if (next.savedSuccessfully && previous?.savedSuccessfully == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보가 저장되었습니다.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref
            .refresh(mainScreenNotifierProvider.notifier)
            .loadDataForSelectedPerson(refresh: true);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            // 화면이 여전히 유효한지 확인 후 pop
            Navigator.of(context).pop(); // true 값 없이 그냥 pop
          }
        });
      }
    }, fireImmediately: true); // 초기 상태도 listener가 받을 수 있도록 설정
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 생년월일 선택 DatePicker 표시 (로컬 상태 업데이트)
  void _presentDatePicker() {
    // <<< 로컬 상태(_selectedBirthDate) 대신 Notifier 상태 사용 >>>
    final currentBirthDate =
        ref.read(editProfileNotifierProvider).initialBirthDate; // 초기값 기준
    final notifier = ref.read(editProfileNotifierProvider.notifier);

    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        // <<< 로컬 상태 업데이트 대신 Notifier 함수 호출 (별도 함수 필요 시 추가) >>>
        // 현재는 저장 버튼 누를 때만 Notifier에 전달하므로 여기서는 직접 상태 변경 X
        // 만약 선택 즉시 상태 변경이 필요하다면 Notifier에 setBirthDate 함수 추가 필요
        // 여기서는 UI 표시용 로컬 변수만 사용하거나, 저장 시점에만 값을 가져오는 방식 유지
        // **주의**: 현재 구조는 저장 버튼 클릭 시 모든 값을 가져가므로, DatePicker에서 Notifier 직접 호출 불필요
        //          대신 화면 리빌드를 위해 setState는 필요할 수 있음 -> Riverpod 상태 쓰면 불필요
        //          현재 상태에서 Notifier의 상태(initialBirthDate)를 직접 사용하도록 build 메소드 수정
      },
      currentTime:
          currentBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
      theme: const picker.DatePickerTheme(/* ... */),
    );
    // <<< 로컬 상태 업데이트 제거 >>>
    // setState(() { _selectedBirthDate = date; });
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
    final state = ref.watch(editProfileNotifierProvider);
    final notifier = ref.read(editProfileNotifierProvider.notifier);

    // Notifier 로드 완료 후 로컬 상태 초기화 (initState에서 listenManual로 처리)
    // if (!state.isLoading && !state.isLoadingLocationData && _selectedBirthDate == null && _selectedGu == null) {
    //   _selectedBirthDate = state.initialBirthDate;
    //   _selectedGu = state.selectedGu;
    //   _selectedDong = state.selectedDong;
    //   _userTypeSelection = Map.from(state.initialUserTypeSelection);
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child:
            (state.isLoading ||
                    (state.isLoadingLocationData &&
                        state.guList.isEmpty)) // 초기 구 목록 로딩 중일 때도 인디케이터 표시
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이름 입력 (로컬 컨트롤러 사용)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '이름', // 필수 여부 등 표시 필요 시 추가
                          hintText: '이름을 입력하세요 (선택)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // <<< 성별 선택 UI 추가 >>>
                      Text(
                        '성별 *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('남성'),
                              value: Gender.male,
                              // <<< groupValue에 state.selectedGender 사용 >>>
                              groupValue: state.selectedGender,
                              onChanged:
                                  state.isSaving
                                      ? null
                                      : (value) {
                                        // <<< Notifier 함수 호출하여 상태 업데이트 >>>
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
                              // <<< groupValue에 state.selectedGender 사용 >>>
                              groupValue: state.selectedGender,
                              onChanged:
                                  state.isSaving
                                      ? null
                                      : (value) {
                                        // <<< Notifier 함수 호출하여 상태 업데이트 >>>
                                        notifier.setGender(value);
                                      },
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // <<<-------------------->>>

                      // 생년월일 선택 (로컬 상태 _selectedBirthDate 사용)
                      TextButton.icon(
                        icon: Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        label: Text(
                          state.selectedBirthDate == null
                              ? '생년월일 선택 *'
                              : '생년월일: ${DateFormat('yyyy.MM.dd').format(state.selectedBirthDate!)}',
                          style: TextStyle(
                            color:
                                state.initialBirthDate == null
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
                        onPressed: () {
                          picker.DatePicker.showDatePicker(
                            context,
                            showTitleActions: true,
                            minTime: DateTime(1900, 1, 1),
                            maxTime: DateTime.now(),
                            // <<< onConfirm에서 Notifier 직접 호출 대신, 선택값은 '저장' 시점에 사용 >>>
                            onConfirm: (date) {
                              notifier.setBirthDate(date);
                            },
                            currentTime:
                                state.selectedBirthDate ??
                                DateTime.now().subtract(
                                  const Duration(days: 365 * 30),
                                ),
                            locale: picker.LocaleType.ko,
                            theme: const picker.DatePickerTheme(/* ... */),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // --- 지역 선택 UI 추가 (add_person_screen.dart 참고) ---
                      Text(
                        '거주 지역 *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      // 구 선택 드롭다운
                      DropdownButtonFormField<String>(
                        value: state.selectedGu, // 로컬 상태 사용
                        hint: Text(
                          state.isLoadingLocationData
                              ? '불러오는 중...'
                              : '구를 선택하세요',
                        ),
                        // isExpanded: true,
                        // decoration: InputDecoration(
                        //   border: OutlineInputBorder(
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   filled: true,
                        //   fillColor: Colors.grey[100],
                        //   contentPadding: const EdgeInsets.symmetric(
                        //     horizontal: 16,
                        //     vertical: 14,
                        //   ),
                        // ),
                        items:
                            state.guList.map((String gu) {
                              return DropdownMenuItem<String>(
                                value: gu,
                                child: Text(gu),
                              );
                            }).toList(),
                        onChanged:
                            state.isLoadingLocationData
                                ? null
                                : (String? newValue) {
                                  notifier.setSelectedGu(
                                    newValue,
                                  ); // Notifier 호출 (동 목록 로드 또는 초기화)
                                },
                        // validator는 Form 사용 시 필요
                      ),
                      const SizedBox(height: 12),
                      // 동 선택 드롭다운
                      DropdownButtonFormField<String>(
                        value: state.selectedDong, // 로컬 상태 사용
                        hint: Text(
                          state.isLoadingLocationData
                              ? '불러오는 중...'
                              : (state.selectedGu == null
                                  ? '구를 먼저 선택하세요'
                                  : '동을 선택하세요'),
                        ),
                        // isExpanded: true,
                        // decoration: InputDecoration(
                        //   border: OutlineInputBorder(
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   filled: true,
                        //   fillColor: Colors.grey[100],
                        //   contentPadding: const EdgeInsets.symmetric(
                        //     horizontal: 16,
                        //     vertical: 14,
                        //   ),
                        // ),
                        // 구 선택 전에는 비활성화, 로딩 중 비활성화
                        items:
                            (state.isLoadingLocationData ||
                                    state.selectedGu == null)
                                ? []
                                : state.dongList.map((String dong) {
                                  return DropdownMenuItem<String>(
                                    value: dong,
                                    child: Text(dong),
                                  );
                                }).toList(),
                        onChanged:
                            (state.isLoadingLocationData ||
                                    state.selectedGu == null)
                                ? null
                                : (String? newValue) {
                                  // null 선택 시 처리 추가
                                  notifier.setSelectedDong(
                                    newValue,
                                  ); // Notifier에도 반영 (선택적이지만 상태 동기화 위해 권장)
                                },
                      ),
                      const SizedBox(height: 24),

                      // 사용자 특성 선택 (로컬 상태 _userTypeSelection 사용)
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
                            EditProfileState.availableUserTypes.map((
                              String type,
                            ) {
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

                      // 기저질환 Placeholder (기존과 동일)
                      Text(
                        '기저질환 (선택)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '향후 기저질환 선택 기능이 추가될 예정입니다.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // "저장" 버튼 (Notifier 함수 호출)
                      ElevatedButton(
                        onPressed:
                            state.isSaving
                                ? null
                                : () {
                                  // <<< Notifier의 saveProfile 호출 시, UI 상태 값들을 직접 넘길 필요 없어짐 >>>
                                  // (단, 지역/성별은 파라미터 유지했으므로 전달)
                                  notifier.saveProfile(
                                    // birthDate, userTypeSelection 파라미터 제거됨
                                    selectedGu: state.selectedGu,
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
                          textStyle: Theme.of(context).textTheme.labelLarge,
                        ),
                        child:
                            state
                                    .isSaving // isSaving 상태 확인
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
