import 'package:flutter/material.dart';
import 'package:front/presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/main_screen.dart'; // 경로 수정
import 'core/theme/app_theme.dart'; // 테마 import

class MyApp extends StatelessWidget {
  final bool onboardingComplete;
  const MyApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We Health App', // 앱 제목 변경
      theme: AppTheme.lightTheme, // 정의된 테마 사용
      // darkTheme: AppTheme.darkTheme, // 다크 모드 필요시
      // themeMode: ThemeMode.system, // 시스템 설정 따르기
      home: onboardingComplete ? const MainScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
