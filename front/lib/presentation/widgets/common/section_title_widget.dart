import 'package:flutter/material.dart';

import '../../screens/main/widgets/major_health_indices_widget.dart'; // HealthIndexInfoDialog 사용 위함 (경로 주의!)
import '../../widgets/main_screen/health_index_info_dialog.dart'; // HealthIndexInfoDialog 경로 수정

/// 섹션 제목을 표시하는 공용 위젯
class SectionTitleWidget extends StatelessWidget {
  final String title;
  final bool showInfoIcon;
  final VoidCallback? onInfoIconTap; // 정보 아이콘 탭 콜백

  const SectionTitleWidget({
    super.key,
    required this.title,
    this.showInfoIcon = false,
    this.onInfoIconTap, // 콜백 추가
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center, // 아이콘과 세로 정렬
      children: [
        // 제목 텍스트
        Text(title, style: Theme.of(context).textTheme.titleMedium),

        // 정보 아이콘 (조건부 표시)
        if (showInfoIcon) ...[
          SizedBox(width: 6), // 제목과 아이콘 사이 간격
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: Colors.grey[500],
              size: 18, // 크기 조정
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(), // 버튼 패딩 최소화
            splashRadius: 18, // 물결 효과 범위 조정
            tooltip: '$title 설명 보기',
            onPressed:
                onInfoIconTap ?? // 기본 동작 또는 커스텀 콜백 실행
                () {
                  // 기본 동작: 제목에 '건강 지수' 포함 시 정보 다이얼로그 표시
                  if (title.contains('건강 지수')) {
                    showDialog(
                      context: context,
                      builder: (_) => const HealthIndexInfoDialog(),
                    );
                  } else {
                    // 다른 종류의 정보 아이콘 탭 시 동작 (필요시 확장)
                    print('$title 정보 아이콘 기본 동작');
                  }
                },
          ),
        ],
      ],
    );
  }
}
