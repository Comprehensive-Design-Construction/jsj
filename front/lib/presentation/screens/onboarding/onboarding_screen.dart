import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

// import '../../../core/utils/preferences_service.dart'; // Notifier에서 사용
import '../main/main_screen.dart';
import 'onboarding_notifier.dart'; // Notifier import
import 'onboarding_state.dart'; // State import

// ConsumerStatefulWidget으로 변경
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ConsumerState로 변경
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // PreferencesService 인스턴스 제거
  final _nameController = TextEditingController(); // 이름 컨트롤러는 로컬 상태 유지

  // 상태 변수 제거 -> Riverpod State에서 관리
  // DateTime? _selectedBirthDate;
  // Map<String, bool> _userTypeSelection = { ... };

  @override
  void initState() {
    super.initState();

    // Notifier의 완료 상태를 감지하여 화면 전환
    ref.listenManual<OnboardingState>(onboardingNotifierProvider, (
      previous,
      next,
    ) {
      // 에러 메시지 표시
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
      }

      // 온보딩 완료 시 MainScreen으로 이동
      if (next.onboardingProcessComplete &&
          previous?.onboardingProcessComplete == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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
        // Notifier 함수 호출
        notifier.setBirthDate(date);
      },
      currentTime:
          currentBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)), // 초기값 수정
      locale: picker.LocaleType.ko,
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 3. 생년월일 선택 (state.selectedBirthDate 사용)
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

              // 4. 사용자 특성 선택 (state.userTypeSelection 사용)
              Text(
                '사용자 특성 (중복 선택 가능)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...state.userTypeSelection.keys.map((String key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: state.userTypeSelection[key],
                  onChanged:
                      state.isSaving
                          ? null
                          : (bool? value) {
                            // 저장 중 비활성화
                            // Notifier 함수 호출
                            notifier.toggleUserType(key, value!);
                          },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.blueAccent,
                );
              }).toList(),
              const SizedBox(height: 24),

              // 5. 기저질환 Placeholder (기존과 동일)
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

              // 6. 시작 버튼 (Notifier 함수 호출)
              ElevatedButton(
                onPressed:
                    state.isSaving
                        ? null
                        : () {
                          // isSaving 상태 확인
                          notifier.startApp(
                            _nameController.text,
                          ); // 이름 전달 (선택적)
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
                onPressed:
                    state.isSaving
                        ? null
                        : notifier.simpleStartApp, // isSaving 상태 확인
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
                    state
                            .isSaving // isSaving 상태 확인
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
    );
  }
}
