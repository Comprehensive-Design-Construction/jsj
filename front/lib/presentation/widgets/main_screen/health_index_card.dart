import 'package:flutter/material.dart';
import '../../../data/models/ui/health_index.dart'; // 경로 수정

class HealthIndexCard extends StatelessWidget {
  final HealthIndex healthIndex;
  final bool showProgressBar;

  const HealthIndexCard({
    Key? key,
    required this.healthIndex,
    required this.showProgressBar,
  }) : super(key: key);

  // --- 프로그레스 바 계산 함수 (변경 없음) ---
  double _calculateProgress(BuildContext context, double value) {
    // TODO: 각 지수별 프로그레스 바 범위 논의 후 확정 필요 (현재는 이름 기반 임시 범위)
    double minValue = 0.0;
    double maxValue = 10.0; // 기본값
    // ... (기존의 이름 기반 범위 설정 로직 유지) ...
    if (healthIndex.name.contains('미세먼지')) {
      maxValue = 200;
    } else if (healthIndex.name == '자외선 지수') {
      maxValue = 15;
    }
    // ...

    double progress = ((value - minValue) / (maxValue - minValue)).clamp(
      0.0,
      1.0,
    );
    double trackWidth =
        MediaQuery.of(context).size.width - (16 * 2) - (16 * 2); // 카드 패딩 고려
    const double thumbRadius = 8.0;
    return (trackWidth * progress).clamp(0.0, trackWidth - thumbRadius * 2);
  }

  @override
  Widget build(BuildContext context) {
    // (HealthIndex 모델 경로 수정)
    // TODO: 카드 탭 또는 꺽쇠 아이콘 탭 시 동작 연결 (상세보기 화면)
    return Container(
      /* ... (기존 코드와 동일) ... */
      padding: EdgeInsets.fromLTRB(16, 12, 16, showProgressBar ? 12 : 16),
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
          // --- 상단: 아이콘, 이름/값, 상태 태그 ---
          Row(
            /* ... (기존 코드와 동일) ... */
            children: [
              Expanded(
                child: Row(
                  children: [
                    /* 아이콘 + 이름/값 */
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: healthIndex.iconColor,
                      child: Icon(
                        healthIndex.icon,
                        color: healthIndex.statusColor,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            healthIndex.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            healthIndex.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // 소수점 1자리 표시
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // 상태 태그 (탭 가능하게 InkWell 추가?)
              InkWell(
                // <<< 탭 가능하게 감싸기 (선택 사항)
                onTap: () {
                  /* TODO: 상세 보기 화면으로 이동 */
                  print('${healthIndex.name} 상세 보기');
                },
                borderRadius: BorderRadius.circular(20), // 탭 효과 영역
                child: Container(
                  /* 기존 상태 태그 Container */
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    /* ... 기존 태그 스타일 ... */
                    color: healthIndex.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: healthIndex.statusColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 16,
                        color: healthIndex.statusColor,
                      ),
                      Text(
                        healthIndex.status,
                        style: TextStyle(
                          color: healthIndex.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // --- 프로그레스 바 (조건부 렌더링) ---
          if (showProgressBar) ...[
            /* ... (기존 프로그레스 바 코드) ... */
            SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                /* ... */
                return Stack(/* ... */);
              },
            ),
          ],
        ],
      ),
    );
  }
}
