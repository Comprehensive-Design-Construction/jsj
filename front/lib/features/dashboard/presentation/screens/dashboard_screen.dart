// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메인 대시보드'),
        // TODO: 사용자 이름, 로고 등 표시
      ),
      body: const Center(
        child: Text('날씨, 건강 지수, 지도 등이 여기에 표시됩니다.'),
        // TODO: 대시보드 위젯 구현 및 배치
      ),
      // TODO: 하단 네비게이션 바 구현
    );
  }
}
