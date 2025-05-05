import 'package:flutter/material.dart';
// DataMapper의 통합 상태 클래스 import (경로 주의)
import '../../../core/utils/data_mapper.dart';

/// 주요 건강 지수 정보 표시 다이얼로그 위젯
class HealthIndexInfoDialog extends StatelessWidget {
  const HealthIndexInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 통합된 5단계 상태와 색상 사용 ---
    final Map<String, Color> unifiedRiskLevels = {
      UnifiedStatus.low: UnifiedStatus.colors[UnifiedStatus.low]!,
      UnifiedStatus.moderate: UnifiedStatus.colors[UnifiedStatus.moderate]!,
      UnifiedStatus.high: UnifiedStatus.colors[UnifiedStatus.high]!,
      UnifiedStatus.veryHigh: UnifiedStatus.colors[UnifiedStatus.veryHigh]!,
      UnifiedStatus.extreme: UnifiedStatus.colors[UnifiedStatus.extreme]!,
      // 필요시 '정보 없음'도 추가 가능
      UnifiedStatus.unknown: UnifiedStatus.colors[UnifiedStatus.unknown]!,
    };
    // --------------------------------

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '건강 지수 위험도 안내', // 제목 변경
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 20,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '닫기',
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 텍스트 (기존 유지 또는 수정)
            Text(
              '사용자의 기저질환 및 특성을 고려하여 관련된 건강 지수 위험도를 표시합니다.', // 문구 수정
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '위험도는 낮음, 보통, 높음, 매우 높음, 위험 5단계로 구분됩니다.', // 5단계 명시
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              '위험도 범례', // 제목 수정
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- 통합된 5단계 범례 표시 ---
            Column(
              children:
                  unifiedRiskLevels.entries.map((entry) {
                    // unifiedRiskLevels 사용
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: entry.value, // 통합 색상 사용
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.key, // 통합 상태 이름 사용 (예: '낮음', '보통'...)
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            // ---------------------------
          ],
        ),
      ),
    );
  }
}
