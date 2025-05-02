import 'package:flutter/material.dart';

/// 주요 건강 지수 정보 표시 다이얼로그 위젯
class HealthIndexInfoDialog extends StatelessWidget {
  const HealthIndexInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // 팝업 이미지의 색상 기준 적용 (추후 확인 및 통일 필요)
    final Map<String, Color> riskLevelColors = {
      '관심': Colors.blue,
      '주의': Colors.green,
      '경고': Colors.yellow.shade700, // 좀 더 잘보이게 shade700 사용
      '위험': Colors.red,
    };

    return AlertDialog(
      // 배경색 및 모양 설정 (선택 사항)
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      // 제목 영역 (패딩 조절)
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '주요 건강 지수란?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          // 닫기 버튼
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
            padding: EdgeInsets.zero, // 버튼 주변 여백 최소화
            constraints: BoxConstraints(), // 버튼 크기 최소화
            splashRadius: 20, // 물결 효과 범위
            onPressed: () => Navigator.of(context).pop(), // 팝업 닫기
            tooltip: '닫기',
          ),
        ],
      ),
      // 내용 영역 (패딩 및 스크롤 설정)
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      content: SingleChildScrollView(
        // 내용 길어질 경우 스크롤 가능하게
        child: Column(
          mainAxisSize: MainAxisSize.min, // 컬럼 크기를 내용에 맞게 조절
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 텍스트
            Text(
              '사용자의 기저질환을 기반으로 기저질환에 큰 영향을 미치는 건강 관련 지수를 우선하여 보여줍니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '해당 건강 지수에 취약한 집단은 가중치에 따라 더 높은 위험도가 부여됩니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24), // 섹션 간 간격
            // 위험 정도 범례 제목
            Text(
              '건강 지수 위험 정도',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ), // titleSmall 사용
            ),
            const SizedBox(height: 16),

            // 위험 정도 범례 (Row와 Column 사용)
            Column(
              children:
                  riskLevelColors.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          // 색상 선
                          Container(
                            width: 40, // 선 길이
                            height: 5, // 선 두께
                            decoration: BoxDecoration(
                              color: entry.value, // 맵의 색상 사용
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 상태 텍스트
                          Text(
                            entry.key, // 맵의 키 (상태 이름) 사용
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      // actions: [], // 필요시 하단에 버튼 추가 가능
    );
  }
}
