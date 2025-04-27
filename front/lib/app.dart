import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart'; // 홈 화면 import
import 'theme/app_theme.dart'; // 앱 테마 import

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '날씨기반 건강 관리', // 앱 제목
      theme: AppTheme.lightTheme, // 정의된 라이트 테마 적용
      // darkTheme: AppTheme.darkTheme, // 다크 테마 (선택 사항)
      // themeMode: ThemeMode.system, // 시스템 설정 따르기 (선택 사항)
      home: const HomeScreen(), // 앱 시작 화면 지정
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      // TODO: 화면이 많아지면 Navigator 2.0 또는 go_router 등을 이용한 라우팅 설정 고려
    );
  }
}
