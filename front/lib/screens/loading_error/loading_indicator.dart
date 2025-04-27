// lib/screens/loading_error/loading_indicator.dart
import 'package:flutter/material.dart';

/// 간단한 중앙 정렬 로딩 인디케이터 위젯
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(), // 기본 원형 로딩 표시기
    );
  }
}
