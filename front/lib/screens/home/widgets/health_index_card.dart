import 'package:flutter/material.dart';
import '../../../widgets/placeholder_image.dart'; // 공통 Placeholder 위젯

/// 홈 화면의 세부 건강 지수를 표시하는 카드 위젯
class HealthIndexCard extends StatelessWidget {
  final String title; // 지수 이름 (예: "천식/폐질환")
  final double? score; // 지수 점수 (Optional)
  final int? level; // 지수 단계 (Optional, 예: 1~4)
  final int levelMax; // 단계 최대값 (색상 계산용)
  final String? statusText; // 단계 대신 표시할 상태 텍스트 (예: "경고")
  final String iconPlaceholder; // 아이콘 이미지 경로 (assets)
  final Color statusColor; // 상태에 따른 색상 (외부에서 계산하여 전달)

  const HealthIndexCard({
    super.key,
    required this.title,
    this.score,
    this.level,
    this.levelMax = 4, // 기본 최대 단계값
    this.statusText,
    required this.iconPlaceholder,
    required this.statusColor, // 상태 색상 필수 전달
  });

  @override
  Widget build(BuildContext context) {
    // 표시할 값 결정 (상태 텍스트 우선, 없으면 점수, 그것도 없으면 'N/A')
    String displayValue = statusText ?? score?.toStringAsFixed(1) ?? 'N/A';
    // 단계 텍스트 (레벨 값이 있을 경우)
    String levelText = (level != null && statusText == null) ? '단계 $level' : '';

    return Card(
      // 카드 배경색은 기본 테마 사용, 테두리로 상태 표시
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1), // 상태 색상 테두리
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 아이콘 Placeholder
            PlaceholderImage(imagePath: iconPlaceholder, size: 30),
            const SizedBox(width: 12),
            // 지수 이름 및 값/상태 표시 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 지수 이름
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 값 또는 상태 텍스트 (상태 색상 적용)
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.baseline, // baseline 정렬
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 18,
                        ), // 강조
                      ),
                      const SizedBox(width: 6),
                      // 단계 텍스트 (있을 경우, 작은 글씨로)
                      if (levelText.isNotEmpty)
                        Text(
                          levelText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: statusColor.withOpacity(0.8)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
