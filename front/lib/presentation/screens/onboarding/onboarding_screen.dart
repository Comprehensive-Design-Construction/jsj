import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker; // 이름 충돌 방지
import 'package:intl/intl.dart'; // 날짜 포매팅

import '../../../core/utils/preferences_service.dart'; // Preferences 서비스
import '../main/main_screen.dart'; // 메인 화면

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  final Map<String, bool> _userTypeSelection = {
    '농촌': false,
    '비닐하우스': false,
    '실외작업자': false,
  };
  // TODO: 기저질환 선택 UI 및 상태 변수 추가

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 생년월일 선택 DatePicker 표시
  void _presentDatePicker() {
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1), // 선택 가능한 최소 날짜
      maxTime: DateTime.now(), // 선택 가능한 최대 날짜 (오늘)
      onConfirm: (date) {
        setState(() {
          _selectedBirthDate = date;
        });
        print('Selected birth date: $date');
      },
      currentTime: _selectedBirthDate ?? DateTime.now(), // 초기 선택 날짜
      locale: picker.LocaleType.ko, // 한국어 설정
      theme: const picker.DatePickerTheme(
        // DatePicker 테마 (선택 사항)
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

  // 나이 계산 함수
  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    // 생일 안 지났으면 -1
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0; // 음수 방지
  }

  // "시작" 버튼 로직
  Future<void> _startApp() async {
    // 입력값 검증 (간단 예시)
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
    // 선택된 사용자 특성 리스트 생성
    final selectedTypes =
        _userTypeSelection.entries
            .where((entry) => entry.value) // 체크된 것만 필터링
            .map((entry) => entry.key) // 키(특성 이름)만 추출
            .toList();
    // TODO: 기저질환 리스트 가져오기
    final List<String> diseases = []; // 현재는 비어있음

    // 사용자 특성과 기저질환을 합쳐서 'disease' 파라미터용 리스트 생성
    final List<String> diseaseParam = [...selectedTypes, ...diseases];

    // 로컬 저장소에 정보 저장
    await _prefsService.saveUserInfo(age: age, userTypes: diseaseParam);
    await _prefsService.setOnboardingComplete(); // 온보딩 완료 플래그 설정

    // 메인 화면으로 이동 (현재 화면 스택 제거)
    if (mounted) {
      // 위젯이 아직 화면에 있는지 확인
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  // "간편시작" 버튼 로직
  Future<void> _simpleStartApp() async {
    // 기본값(null)으로 정보 저장
    await _prefsService.saveUserInfo(age: null, userTypes: []);
    await _prefsService.setOnboardingComplete(); // 온보딩 완료 플래그 설정

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 상태바 등 시스템 영역 침범 방지
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 자식 위젯 가로로 꽉 채우기
            children: [
              // 1. 로고
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Image.asset(
                  'assets/images/welogo.png', // 로고 경로 확인
                  height: 60,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const SizedBox(height: 60),
                ),
              ),

              // 2. 이름 입력
              TextField(
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
                textInputAction: TextInputAction.next, // 다음 입력 필드로 이동
              ),
              const SizedBox(height: 16),

              // 3. 생년월일 선택
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
                onPressed: _presentDatePicker,
                child: Text(
                  _selectedBirthDate == null
                      ? '생년월일 (예: 1999.01.01)'
                      : '생년월일: ${DateFormat('yyyy.MM.dd').format(_selectedBirthDate!)}', // intl 패키지 사용
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

              // 4. 사용자 특성 선택 (CheckboxListTile 사용)
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
                      _userTypeSelection[key] = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading, // 체크박스 왼쪽으로
                  contentPadding: EdgeInsets.zero, // 내부 여백 제거
                  activeColor: Colors.blueAccent, // 체크 시 색상
                );
              }).toList(),
              const SizedBox(height: 24),

              // 5. 기저질환 Placeholder
              Text('기저질환 (선택)', style: Theme.of(context).textTheme.titleSmall),
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

              // 6. 시작 버튼
              ElevatedButton(
                onPressed: _startApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('시작'),
              ),
              const SizedBox(height: 12),

              // 7. 간편시작 버튼
              TextButton(
                onPressed: _simpleStartApp,
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
                child: const Text('간편시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
