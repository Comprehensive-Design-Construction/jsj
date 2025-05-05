import 'package:flutter/material.dart';
import 'dart:math'; // clamp 사용 위해 유지
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ui/feels_like_data.dart';
import '../common/speech_bubble.dart'; // SpeechBubble은 IndexStatusBar 내부에서 사용
import '../../screens/index_detail/index_detail_screen.dart';
import '../../../core/utils/preferences_service.dart';
import '../../screens/main/main_screen_notifier.dart'; // provider 사용 위함
// --- IndexStatusBar import ---
import '../index_detail/index_status_bar.dart';
// ---------------------------

class FeelsLikeCard extends ConsumerWidget {
  final FeelsLikeData feelsLikeData;
  const FeelsLikeCard({Key? key, required this.feelsLikeData})
    : super(key: key);

  // --- _calculateHandleCenterX 함수 제거 ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 프로그레스 바 관련 상수 제거 ---

    // 체감 온도 범위 설정
    const double minValue = 0.0; // 예시 범위
    const double maxValue = 45.0; // 예시 범위

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 상단: 아이콘, 온도, '>' 아이콘 (기존과 동일) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: feelsLikeData.statusColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.thermostat,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // 온도 텍스트
              Expanded(
                child: Text(
                  '${feelsLikeData.temperature.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
              // '>' 아이콘 (탭 가능)
              InkWell(
                onTap: () async {
                  print('FeelsLikeCard arrow tapped!');
                  // try-catch 및 mounted 확인 추가
                  try {
                    // final prefsService = ref.read(preferencesServiceProvider); // 필요시 로드
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                IndexDetailPage(indexData: feelsLikeData),
                      ),
                    );
                  } catch (e) {
                    print("Error navigating to detail page: $e");
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
          const SizedBox(
            height: 20,
          ), // 상단과 프로그레스 바 사이 간격 (기존 40 -> 20으로 줄임, IndexStatusBar 높이 고려)
          // --- 프로그레스 바와 말풍선 (IndexStatusBar 사용) ---
          // --- LayoutBuilder 및 Stack 관련 코드 제거 ---
          IndexStatusBar(
            currentValue: feelsLikeData.temperature,
            minValue: minValue,
            maxValue: maxValue,
            statusText: feelsLikeData.status,
            statusColor: feelsLikeData.statusColor,
          ),

          // --- --------------------------------- ---
          const SizedBox(height: 15), // 프로그레스 바와 메시지 사이 간격 (기존과 동일)
          // --- 안내 메시지 (기존과 동일) ---
          Text(
            feelsLikeData.message1,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            feelsLikeData.message2,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20), // 하단 여백
          // --- 하단 버튼 (주석 처리된 상태 유지) ---
          // SizedBox(width: double.infinity, child: ElevatedButton(...)),
        ],
      ),
    );
  }
}
