import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_data_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppDataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱 시작 시 초기 데이터 로드 요청
    // build 메소드 내에서 직접 호출하는 것은 권장되지 않으므로
    // HomeScreen의 initState 등에서 호출하도록 변경
    // Provider.of<AppDataProvider>(context, listen: false).loadInitialData();

    return MaterialApp(
      title: '안전 정보 앱', // 앱 이름 변경
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100], // 전체 배경색 설정
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Pretendard', // (선택) Pretendard 폰트 적용 (pubspec.yaml 설정 필요)
      ),
      home: const HomeScreen(),
    );
  }
}
