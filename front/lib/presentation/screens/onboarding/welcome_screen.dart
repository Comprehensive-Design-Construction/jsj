// lib/presentation/screens/onboarding/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/presentation/screens/onboarding/consent_screen.dart'; // ConsentScreen import
// 필요한 경우 MainScreen import 유지 (리스너에서 사용 시)
// import '../main/main_screen.dart';
import 'onboarding_notifier.dart';
// import 'onboarding_state.dart'; // 리스너에서 State 타입 명시 시 필요

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  // _listenToCompletion 리스너는 이제 simpleStartApp 완료를 감지할 필요 없으므로,
  // 에러 메시지 표시 부분만 남기거나, 필요 없다면 제거 가능.
  // 여기서는 에러 메시지 처리를 위해 유지.
  void _listenToCompletion(BuildContext context, WidgetRef ref) {
    ref.listenManual(onboardingNotifierProvider, (previous, next) {
      // 에러 메시지 표시 (예: 정보 입력 화면에서 저장 실패 시 Welcome으로 돌아왔을 경우)
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      }
      // onboardingProcessComplete 관련 로직 제거 (simpleStartApp 없음)
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenToCompletion(context, ref); // 에러 리스너 등록

    // OnboardingNotifier의 isSaving 상태는 여전히 '시작하기' 후 Consent/InfoInput 화면에서
    // '완료' 버튼을 눌렀을 때 사용될 수 있으므로 watch 유지 가능 (선택 사항)
    final isSaving = ref.watch(
      onboardingNotifierProvider.select((state) => state.isSaving),
    );
    // final notifier = ref.read(onboardingNotifierProvider.notifier); // simpleStartApp 호출 안 하므로 제거 가능

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 로고 ---
                Padding(
                  padding: const EdgeInsets.only(
                    top: 340.0, // 레이아웃 조정 필요 시 값 변경
                    bottom: 60.0,
                  ),
                  child: Image.asset(
                    'assets/images/welogo.png',
                    height: 120,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const SizedBox(height: 120), // 높이 유지
                  ),
                ),
                const Spacer(),

                // --- 시작 버튼 ---
                ElevatedButton(
                  onPressed:
                      isSaving // isSaving 상태를 로딩 표시 외 다른 용도로 쓰지 않는다면 null 체크 제거 가능
                          ? null
                          : () {
                            // ConsentScreen으로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConsentScreen(),
                              ),
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
                  // isSaving에 따른 로딩 표시는 '완료' 버튼에만 필요하므로 제거 가능
                  // child: isSaving ? SizedBox(...) : Text('시작하기'),
                  child: const Text('시작하기'),
                ),
                const SizedBox(height: 40), // 하단 여백
                // --- 간편시작 버튼 및 SizedBox 제거 ---
                // TextButton(...) 제거
                // const SizedBox(height: 12) 제거 (ElevatedButton 아래)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
