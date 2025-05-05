import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

import 'edit_profile_notifier.dart'; // Notifier import
import 'edit_profile_state.dart'; // State import

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
  DateTime? _selectedBirthDate;
  String? _selectedGu; // 로컬 상태 추가
  String? _selectedDong; // 로컬 상태 추가
  Map<String, bool> _userTypeSelection = {
    '농촌': false,
    '비닐하우스': false,
    '실외작업자': false,
  };

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
      if ((previous?.isLoading == true ||
              previous?.isLoadingLocationData == true) &&
          next.isLoading == false &&
          next.isLoadingLocationData == false) {
        if (next.initialBirthDate != null) {
          setState(() {
            _selectedBirthDate = next.initialBirthDate;
          });
        }
        // 구/동 초기값 설정 (Notifier의 selectedGu/Dong 사용)
        if (next.selectedGu != null) {
          // Notifier 상태를 로컬 상태로 동기화
          setState(() {
            _selectedGu = next.selectedGu;
            _selectedDong = next.selectedDong;
          });
        }
        setState(() {
          _userTypeSelection = Map.from(next.initialUserTypeSelection);
        });
      }

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
          ),
        );
        if (context.mounted) {
          Navigator.of(context).pop(); // 이전 화면으로 돌아가기
        }
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
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        setState(() {
          // 로컬 상태(_selectedBirthDate) 업데이트
          _selectedBirthDate = date;
        });
        print('Selected birth date: $date');
      },
      currentTime:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      locale: picker.LocaleType.ko,
      theme: const picker.DatePickerTheme(/* 테마 설정 */),
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

                      // 생년월일 선택 (로컬 상태 _selectedBirthDate 사용)
                      TextButton.icon(
                        icon: Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        label: Text(
                          _selectedBirthDate == null
                              ? '생년월일 선택 *'
                              : '생년월일: ${DateFormat('yyyy.MM.dd').format(_selectedBirthDate!)}',
                          style: TextStyle(
                            color:
                                _selectedBirthDate == null
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
                        onPressed: _presentDatePicker,
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
                        value: _selectedGu, // 로컬 상태 사용
                        hint: Text(
                          state.isLoadingLocationData
                              ? '불러오는 중...'
                              : '구를 선택하세요',
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
                            state.isLoadingLocationData
                                ? null
                                : (String? newValue) {
                                  // null 선택 시 처리 추가
                                  setState(() {
                                    _selectedGu = newValue;
                                    _selectedDong = null; // 구 변경 시 동 로컬 상태 초기화
                                  });
                                  notifier.setSelectedGu(
                                    newValue,
                                  ); // Notifier 호출 (동 목록 로드 또는 초기화)
                                },
                        // validator는 Form 사용 시 필요
                      ),
                      const SizedBox(height: 12),
                      // 동 선택 드롭다운
                      DropdownButtonFormField<String>(
                        value: _selectedDong, // 로컬 상태 사용
                        hint: Text(
                          state.isLoadingLocationData
                              ? '불러오는 중...'
                              : (_selectedGu == null
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
                        // 구 선택 전에는 비활성화, 로딩 중 비활성화
                        items:
                            (state.isLoadingLocationData || _selectedGu == null)
                                ? []
                                : state.dongList.map((String dong) {
                                  return DropdownMenuItem<String>(
                                    value: dong,
                                    child: Text(dong),
                                  );
                                }).toList(),
                        onChanged:
                            (state.isLoadingLocationData || _selectedGu == null)
                                ? null
                                : (String? newValue) {
                                  // null 선택 시 처리 추가
                                  setState(() {
                                    _selectedDong = newValue;
                                  }); // 로컬 상태 업데이트
                                  notifier.setSelectedDong(
                                    newValue,
                                  ); // Notifier에도 반영 (선택적이지만 상태 동기화 위해 권장)
                                },
                      ),
                      const SizedBox(height: 24),

                      // 사용자 특성 선택 (로컬 상태 _userTypeSelection 사용)
                      Text(
                        '사용자 특성 (중복 선택 가능)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._userTypeSelection.keys.map((String key) {
                        return CheckboxListTile(
                          title: Text(key),
                          value: _userTypeSelection[key],
                          onChanged: (bool? value) {
                            setState(() {
                              // 로컬 상태 업데이트
                              _userTypeSelection[key] = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.blueAccent,
                        );
                      }).toList(),
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
                        // isSaving 상태 확인
                        onPressed:
                            state.isSaving
                                ? null
                                : () {
                                  // 로컬 상태를 Notifier의 saveProfile 함수로 전달
                                  notifier.saveProfile(
                                    birthDate: _selectedBirthDate,
                                    selectedGu: _selectedGu, // 선택된 구 전달
                                    selectedDong: _selectedDong, // 선택된 동 전달
                                    userTypeSelection: _userTypeSelection,
                                    // name: _nameController.text, // 이름 저장 필요 시
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
