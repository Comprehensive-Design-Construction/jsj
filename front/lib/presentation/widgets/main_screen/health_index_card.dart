import 'package:flutter/material.dart';
import 'dart:math'; // clamp 사용 위해 유지
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ui/health_index.dart';
import '../common/speech_bubble.dart'; // SpeechBubble은 IndexStatusBar 내부에서 사용
import '../../screens/index_detail/index_detail_screen.dart';
import '../../../core/utils/preferences_service.dart';
import '../../screens/main/main_screen_notifier.dart'; // provider 사용 위함
// --- IndexStatusBar import ---
import '../index_detail/index_status_bar.dart';
// ---------------------------

class HealthIndexCard extends ConsumerWidget {
  final HealthIndex healthIndex;
  final bool showProgressBar; // 프로그레스 바 표시 여부

  const HealthIndexCard({
    Key? key,
    required this.healthIndex,
    required this.showProgressBar,
  }) : super(key: key);

  // --- 지수별 최소/최대값 결정 로직 ---
  // TODO: 이 로직은 DataMapper 또는 별도 유틸리티로 이동 고려
  (double, double) _getIndexRange(String indexName) {
    double minValue = 0.0;
    double maxValue = 100.0; // 기본 범위

    // 기존 _calculateHandleCenterX 내부 로직 참고
    if (indexName == '자외선 지수')
      maxValue = 15.0;
    else if (indexName.contains('꽃가루'))
      maxValue = 100.0; // 예시
    else if (indexName == '미세먼지 지수')
      maxValue = 150.0; // 예시
    else if (indexName == '심뇌혈관질환 지수')
      maxValue = 4.0; // 예시
    else if (indexName == '대기정체 지수')
      maxValue = 100.0; // 예시
    else if (indexName == '식중독 지수')
      maxValue = 100.0; // 예시
    else if (indexName == '감기가능 지수')
      maxValue = 4.0; // 예시
    else if (indexName == '천식질환 지수')
      maxValue = 4.0; // 예시
    // ... 다른 지수 범위 추가 ...

    return (minValue, maxValue);
  }

  // --- _calculateHandleCenterX 함수 제거 ---
  // --- buildProgressBarUI 함수 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 프로그레스 바 관련 상수 제거 ---

    // 지수 범위 결정
    final (minValue, maxValue) = _getIndexRange(healthIndex.name);

    return Container(
      // 카드 패딩 조정 (IndexStatusBar 높이 고려)
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        showProgressBar ? 12 : 16,
      ), // 기존 패딩 유지 또는 미세 조정
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 상단: 아이콘, 이름/값, 상태 박스 또는 '>' 아이콘 (기존과 동일) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: 아이콘 + 이름/값
              Expanded(
                child: Row(
                  children: [
                    // 아이콘
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: healthIndex.iconColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        healthIndex.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 이름 & 값
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            healthIndex.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            // 값 표시 (소수점 처리)
                            healthIndex.value.toStringAsFixed(
                              healthIndex.value.truncateToDouble() ==
                                      healthIndex.value
                                  ? 0
                                  : 1,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 오른쪽: 상태 박스 (showProgressBar=false 일 때) 또는 간격
              if (!showProgressBar)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: healthIndex.iconColor, // 아이콘 배경색과 동일하게
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    healthIndex.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              else
                const SizedBox(width: 8), // 프로그레스 바 표시 시 간격만
              // 맨 오른쪽: '>' 아이콘 (탭 가능)
              InkWell(
                onTap: () async {
                  print('${healthIndex.name} card arrow tapped');
                  // try-catch 블록 추가 (SharedPreferences 접근 오류 대비)
                  try {
                    final prefsService = ref.read(preferencesServiceProvider);
                    // 필요시 사용자 정보 로드 (현재는 IndexDetailPage에서 처리)
                    // final diseases = await prefsService.getUserDiseases();

                    // mounted 확인 추가
                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                IndexDetailPage(indexData: healthIndex),
                      ),
                    );
                  } catch (e) {
                    print("Error navigating to detail page: $e");
                    // 에러 발생 시 사용자에게 알림 (예: SnackBar)
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("상세 정보를 여는 중 오류 발생: $e"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          // --- 프로그레스 바 UI (IndexStatusBar 사용) ---
          if (showProgressBar) ...[
            const SizedBox(height: 20), // 상단 정보와 프로그레스 바 사이 간격
            // --- IndexStatusBar 사용 ---
            IndexStatusBar(
              currentValue: healthIndex.value,
              minValue: minValue,
              maxValue: maxValue,
              statusText: healthIndex.status,
              statusColor: healthIndex.statusColor,
            ),
            // --- ---------------- ---
            // 기존 SizedBox(height: 10) 제거 또는 IndexStatusBar 높이에 맞게 조정
            // IndexStatusBar 자체가 높이를 가지므로 추가 간격이 필요 없을 수 있음
            const SizedBox(height: 4), // 하단 간격 약간 추가
          ],
        ],
      ),
    );
  }
}
