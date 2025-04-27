import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ProviderScope 사용 위해 import
import 'app.dart'; // MyApp 위젯 import

void main() {
  // Flutter 엔진과 위젯 바인딩 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // 앱 전체를 ProviderScope로 감싸 Riverpod 상태 관리 활성화
    const ProviderScope(child: MyApp()),
  );
}
