import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart'; // availableHealthIndices 사용 위해 필요 (특성 목록)
import '../../../core/utils/preferences_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  final Map<String, bool> _userTypeSelection = {
    // Onboarding과 동일하게 초기화
    '농촌': false,
    '비닐하우스': false,
    '실외작업자': false,
  };
  bool _isLoading = true; // 데이터 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 저장된 사용자 데이터 불러오기
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 저장된 사용자 데이터 불러오기
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    // 이름은 현재 저장 기능이 없으므로 비워둠 (필요시 PreferencesService에 추가)
    _nameController.text = ""; // 예: await _prefsService.getUserName() ?? "";

    // 나이 -> 생년월일 변환 (정확한 생년월일 저장이 더 좋으나, 현재는 나이만 저장)
    final int? savedAge = await _prefsService.getUserAge();
    if (savedAge != null) {
      // 나이로부터 대략적인 생년월일 역산 (정확하지 않음)
      // TODO: 생년월일을 직접 저장하고 불러오는 방식으로 개선 권장
      _selectedBirthDate = DateTime(DateTime.now().year - savedAge);
    } else {
      _selectedBirthDate = null;
    }

    // 사용자 특성/질병 목록 불러오기
    final List<String>? savedTypes = await _prefsService.getUserTypes();
    // 불러온 목록을 바탕으로 체크박스 상태 업데이트
    _userTypeSelection.forEach((key, value) {
      _userTypeSelection[key] = savedTypes?.contains(key) ?? false;
    });

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // 생년월일 선택 DatePicker 표시 (Onboarding과 동일)
  void _presentDatePicker() {
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        setState(() {
          _selectedBirthDate = date;
        });
        print('Selected birth date: $date');
      },
      // 현재 선택된 날짜 또는 이전에 저장된 날짜로 초기화
      currentTime:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)), // 30세 기준 초기화
      locale: picker.LocaleType.ko,
      theme: const picker.DatePickerTheme(/* ... (테마 설정) ... */),
    );
  }

  // 나이 계산 함수 (Onboarding과 동일)
  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  // "저장" 버튼 로직
  Future<void> _saveProfile() async {
    // 생년월일 검증
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('생년월일을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final age = _calculateAge(_selectedBirthDate);
    final selectedTypes =
        _userTypeSelection.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
    // TODO: 기저질환 정보 가져오기

    final List<String> diseaseParam = [...selectedTypes /*, ...diseases*/];

    // 로컬 저장소에 수정된 정보 저장
    await _prefsService.saveUserInfo(age: age, userTypes: diseaseParam);
    // TODO: 이름 저장 로직 추가 시 여기에 포함

    // 저장 완료 메시지 표시 및 이전 화면으로 돌아가기
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('정보가 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(); // MenuScreen으로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar 추가
        title: const Text('내 정보 수정'),
        leading: IconButton(
          // 뒤로가기 버튼
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator()) // 데이터 로딩 중
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 로고는 보통 수정 화면에서 제거
                      // Padding( ... 로고 Image ...),

                      // 이름 입력 (Onboarding과 동일)
                      TextField(
                        /* ... (controller, decoration 등) ... */
                        controller: _nameController,
                        decoration: InputDecoration(labelText: '이름' /* ... */),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // 생년월일 선택 (Onboarding과 동일)
                      TextButton(
                        /* ... (style, onPressed 등) ... */
                        style: TextButton.styleFrom(/* ... */),
                        onPressed: _presentDatePicker,
                        child: Text(
                          /* ... (_selectedBirthDate 표시) ... */
                          _selectedBirthDate == null
                              ? '생년월일 선택 (예: 1999.01.01)'
                              : '생년월일: ${DateFormat('yyyy.MM.dd').format(_selectedBirthDate!)}',
                          style: TextStyle(
                            color:
                                _selectedBirthDate == null
                                    ? Colors.grey[600]
                                    : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 사용자 특성 선택 (Onboarding과 동일)
                      Text(
                        '사용자 특성 (중복 선택 가능)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._userTypeSelection.keys.map((String key) {
                        return CheckboxListTile(
                          /* ... (title, value, onChanged 등) ... */
                          title: Text(key),
                          value: _userTypeSelection[key],
                          onChanged: (bool? value) {
                            setState(() {
                              _userTypeSelection[key] = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.blueAccent,
                        );
                      }).toList(),
                      const SizedBox(height: 24),

                      // 기저질환 Placeholder (Onboarding과 동일)
                      Text(
                        '기저질환 (선택)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        /* ... (Placeholder 내용) ... */
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

                      // "저장" 버튼 (텍스트 변경)
                      ElevatedButton(
                        onPressed: _saveProfile, // 저장 함수 호출
                        style: ElevatedButton.styleFrom(
                          /* ... (Onboarding과 동일한 스타일) ... */
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: Theme.of(context).textTheme.labelLarge,
                        ),
                        child: const Text('저장'), // 버튼 텍스트 변경
                      ),
                      // "간편시작" 버튼 제거
                    ],
                  ),
                ),
      ),
    );
  }
}
