import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

// import '../../../core/constants/app_constants.dart'; // Notifier에서 사용
// import '../../../core/utils/preferences_service.dart'; // Notifier에서 사용
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
  // PreferencesService 인스턴스 제거 -> Notifier에서 관리
  final _nameController = TextEditingController(); // 이름은 로컬 상태로 유지

  // 로컬 상태: 사용자가 화면에서 수정하는 값들
  DateTime? _selectedBirthDate;
  Map<String, bool> _userTypeSelection = {
    // 초기값은 Notifier에서 로드 후 설정
    '농촌': false,
    '비닐하우스': false,
    '실외작업자': false,
  };

  // 로딩/저장 상태는 Riverpod State에서 관리 (_isLoading 제거)

  @override
  void initState() {
    super.initState();
    // initState에서 데이터 로딩 로직 제거 -> Notifier 생성 시 처리

    // Notifier의 초기 데이터 로드가 완료되면 로컬 상태 업데이트
    // 또는 build 메서드에서 초기값을 설정하거나, listener 사용
    // 여기서는 listener를 사용하여 초기값 설정
    ref.listenManual<EditProfileState>(editProfileNotifierProvider, (
      previous,
      next,
    ) {
      // 초기 데이터 로드 완료 시 로컬 상태 업데이트 (한 번만 실행되도록 조건 추가 가능)
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.initialBirthDate != null) {
          setState(() {
            _selectedBirthDate = next.initialBirthDate;
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
        Navigator.of(context).pop(); // 이전 화면으로 돌아가기
      }
    }, fireImmediately: true); // 초기 상태도 listener가 받을 수 있도록 설정
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // _loadUserData, _calculateAge, _saveProfile 함수 제거 -> Notifier로 이동

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
            state
                    .isLoading // 초기 로딩 상태 확인
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
                                  // Notifier의 saveProfile 함수 호출 시 로컬 상태 전달
                                  notifier.saveProfile(
                                    birthDate: _selectedBirthDate,
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
