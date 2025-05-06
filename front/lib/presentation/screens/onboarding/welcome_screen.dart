import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main/main_screen.dart'; // MainScreen 경로
import 'onboarding_info_input_screen.dart'; // 정보 입력 화면 경로 (다음 단계에서 생성/수정)
import 'onboarding_notifier.dart';
import 'onboarding_state.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _listenToCompletion(BuildContext context, WidgetRef ref) {
    ref.listenManual<OnboardingState>(onboardingNotifierProvider, (
      previous,
      next,
    ) {
      // 간편시작 완료 시 메인 화면으로 이동
      if (next.onboardingProcessComplete &&
          previous?.onboardingProcessComplete == false) {
        // simpleStartApp() 호출 완료 후 바로 메인 화면으로 이동하도록 변경
        // mounted 체크는 Navigator.pushReplacement 내부에서 처리되므로 불필요할 수 있으나,
        // 비동기 콜백에서 호출될 경우 안전을 위해 추가하는 것이 좋음.
        // 단, ConsumerWidget의 build 메소드 내에서는 context가 항상 유효하다고 가정 가능.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
      // 에러 메시지 표시 (간편시작 중 오류 발생 시)
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return; // 위젯이 마운트 해제되지 않았는지 다시 확인

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      }
    }, fireImmediately: true); // 최초 빌드 시에도 리스너 실행
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 리스너 등록 (간편시작 완료 시 네비게이션 처리 위함)
    _listenToCompletion(context, ref);

    // 간편시작 버튼의 로딩 상태 감시
    final isSaving = ref.watch(
      onboardingNotifierProvider.select((state) => state.isSaving),
    );
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 (기존 OnboardingScreen의 로고와 동일)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 340.0,
                    bottom: 60.0,
                  ), // 하단 여백 추가
                  child: Image.asset(
                    'assets/images/welogo.png',
                    height: 120,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const SizedBox(height: 60),
                  ),
                ),

                const Spacer(), // 로고와 버튼 사이 공간
                // 시작 버튼
                ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : () {
                            // 저장 중(간편시작 진행 중)일 때는 비활성화
                            // 정보 입력 화면으로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const OnboardingInfoInputScreen(),
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
                  child: const Text('시작하기'),
                ),
                const SizedBox(height: 12),

                // 간편시작 버튼
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () {
                            // 간편시작 로직 호출
                            notifier.simpleStartApp();
                          },
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
                      isSaving
                          ? const SizedBox(
                            // 간편시작 진행 중 로딩 표시
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.grey,
                            ),
                          )
                          : const Text('간편시작'),
                ),

                const SizedBox(height: 40), // 하단 여백
              ],
            ),
          ),
        ),
      ),
    );
  }
}
