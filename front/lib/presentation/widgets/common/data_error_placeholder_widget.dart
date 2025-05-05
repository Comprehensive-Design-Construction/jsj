import 'package:flutter/material.dart';

/// 데이터 로드 실패 또는 데이터 없음 시 표시하는 플레이스홀더 위젯
class DataErrorPlaceholderWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const DataErrorPlaceholderWidget({
    super.key,
    required this.message,
    this.icon = Icons.sentiment_dissatisfied_outlined, // 기본 아이콘
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // 배경색
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        // 아이콘과 텍스트를 세로로 배치
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 32, // 아이콘 크기 조정
          ),
          const SizedBox(height: 12), // 아이콘과 텍스트 간격
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
