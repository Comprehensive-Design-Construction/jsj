// lib/presentation/screens/menu/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front/presentation/screens/onboarding/welcome_screen.dart'; // WelcomeScreen import 추가
import '../../../core/constants/app_constants.dart';
import '../profile/edit_profile_screen.dart';
import 'menu_notifier.dart';
// PreferencesService Provider를 읽기 위해 import 추가
import '../../screens/main/main_screen_notifier.dart'; // preferencesServiceProvider가 정의된 파일

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  // 확인 다이얼로그를 표시하는 helper 함수
  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 바깥을 탭해도 닫히지 않도록 설정
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('동의 철회 및 앱 초기화'),
          content: const Text(
            '정말로 모든 개인정보 제공 동의를 철회하고 앱에 저장된 모든 데이터를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 앱을 처음부터 다시 설정해야 합니다.',
            style: TextStyle(height: 1.5), // 내용 가독성 향상
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false); // '아니오' 또는 '취소' 시 false 반환
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // 중요한 작업임을 강조
              ),
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // '예' 또는 '확인' 시 true 반환
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuNotifierProvider);
    // final prefsService = ref.read(preferencesServiceProvider); // 여기서 미리 읽어둘 수도 있음

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '메뉴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          menuState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // 사용자 정보 변경 섹션
                    Text(
                      '사용자 정보', // 섹션 제목 유지 또는 변경
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // 내 정보 수정하기 (기존 코드)
                    ListTile(
                      title: Text(
                        '내 정보 수정하기',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: true, // 간편시작 제거로 항상 활성화
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // --- 정보 제공 동의 철회 메뉴 추가 ---
                    ListTile(
                      title: Text(
                        '정보 제공 동의 철회 및 초기화', // 메뉴 이름
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.red[700], // 주의를 위한 색상
                        ),
                      ),
                      trailing: Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red[700],
                      ), // 아이콘 추가
                      onTap: () async {
                        // async 키워드 추가
                        // 확인 다이얼로그 표시
                        final bool? confirmation =
                            await _showConfirmationDialog(context);

                        // 사용자가 '확인'을 눌렀을 경우 (confirmation == true)
                        if (confirmation == true) {
                          print(
                            "[MenuScreen] User confirmed data clear and reset.",
                          );
                          try {
                            final prefsService = ref.read(
                              preferencesServiceProvider,
                            );

                            // 데이터 삭제 시도
                            await prefsService.clearAllPreferences();
                            print(
                              "[MenuScreen] Attempted to clear all preferences.",
                            );

                            // 삭제 확인 (디버깅용, 이전 답변의 개별 삭제 방식 사용 시 더 확실)
                            final peopleAfter =
                                await prefsService.getAddedPeople();
                            final onboardingCompleteAfter =
                                await prefsService.isOnboardingComplete();
                            print(
                              "[MenuScreen] Verification after clear: People count=${peopleAfter.length}, Onboarding complete=$onboardingCompleteAfter",
                            );

                            if (!context.mounted) return; // context 유효성 검사

                            // 데이터가 실제로 삭제되었는지 확인 (선택적이지만 권장)
                            if (peopleAfter.isNotEmpty ||
                                onboardingCompleteAfter) {
                              print(
                                "[MenuScreen] Verification FAILED: Data might not be fully cleared.",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '데이터 완전 삭제에 실패했을 수 있습니다. 앱 종료 후 다시 시도해주세요.',
                                  ),
                                  backgroundColor: Colors.orangeAccent,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                              // 실패해도 일단 종료 시도
                            } else {
                              print(
                                "[MenuScreen] Verification SUCCESS: Data appears cleared.",
                              );
                              // 성공 메시지 표시
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('모든 정보가 삭제되었습니다. 앱을 종료합니다.'),
                                  duration: Duration(
                                    seconds: 1,
                                  ), // 앱 종료 전 짧게 표시
                                ),
                              );
                            }

                            // --- 앱 종료 실행 ---
                            // 스낵바가 잠시 표시될 시간을 주고 앱 종료
                            await Future.delayed(
                              const Duration(milliseconds: 2100),
                            );
                            print(
                              "[MenuScreen] Exiting application via SystemNavigator.pop().",
                            );
                            SystemNavigator.pop(); // 앱 종료
                            // -------------------
                          } catch (e, s) {
                            print(
                              "[MenuScreen] Error during clearing preferences or exiting: $e",
                            );
                            print("[MenuScreen] Stacktrace: $s");
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('초기화 또는 앱 종료 중 오류 발생: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } else {
                          print(
                            "[MenuScreen] User cancelled data clear and app exit.",
                          );
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    // --------------------------------------
                    const Divider(height: 32), // 섹션 구분

                    Text(
                      '건강 지수 추가 / 제거',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableHealthIndices.length,
                        itemBuilder: (context, index) {
                          final String indexName =
                              availableHealthIndices[index];
                          final bool isVisible = ref.watch(
                            menuNotifierProvider.select(
                              (s) => s.visibleIndices.contains(indexName),
                            ),
                          );
                          // --- 기존 건강 지수 ListTile 코드 ---
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  indexName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isVisible
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.orangeAccent,
                                    size: 28,
                                  ),
                                  onPressed:
                                      () => ref
                                          .read(menuNotifierProvider.notifier)
                                          .toggleIndexVisibility(indexName),
                                  tooltip:
                                      isVisible
                                          ? '$indexName 숨기기'
                                          : '$indexName 보이기',
                                ),
                              ),
                            ),
                          );
                          // ---------------------------------
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
