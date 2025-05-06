import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart'; // availableHealthIndices 사용
import '../profile/edit_profile_screen.dart';
import 'menu_notifier.dart';
// import 'menu_state.dart'; // 사용 안 함

class MenuScreen extends ConsumerWidget {
  // StatelessWidget -> ConsumerWidget
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef 추가
    // 상태 구독
    final state = ref.watch(menuNotifierProvider);
    // Notifier는 콜백에서 사용하므로 read 사용 (빌드 시점에서는 필요 없음)
    // final notifier = ref.read(menuNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // 테마에서 가져오도록 개선 가능
      appBar: AppBar(
        backgroundColor: Colors.white, // 테마 사용 권장
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '메뉴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ), // 테마 사용 권장
      ),
      body:
          state
                  .isLoading // 로딩 상태 확인
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
                      '사용자 정보 변경',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ListTile(
                      title: Text(
                        '내 정보 수정하기',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // EditProfileScreen 이동 (결과 처리는 MainScreen에서 함)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

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
                          // 상태에서 보이는지 여부 확인
                          final bool isVisible = ref.watch(
                            menuNotifierProvider.select(
                              (s) => s.visibleIndices.contains(indexName),
                            ),
                          );

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
                                      () =>
                                      // Notifier 함수 호출
                                      ref
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
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
