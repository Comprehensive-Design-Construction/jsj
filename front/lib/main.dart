// lib/main.dart
import 'package:flutter/material.dart';
import 'app.dart'; // 앱 루트 위젯 import
// import 'package:shared_preferences/shared_preferences.dart'; // 필요시 여기서 초기화 가능

void main() async {
  // main 함수에서 비동기 작업이 필요하면 WidgetsFlutterBinding 초기화
  // WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences 인스턴스 전역 관리 등 필요시 여기서 수행
  // SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(const MyApp()); // 앱 실행
}
