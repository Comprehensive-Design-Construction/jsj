// lib/app.dart (이전에 제안했던 코드 예시)
import 'package:flutter/material.dart';
import 'core/storage/user_profile_storage.dart'; // 사용자 프로필 저장소 import
import 'features/initial_setup/presentation/screens/initial_setup_screen.dart'; // 초기 설정 화면 import
import 'features/dashboard/presentation/screens/dashboard_screen.dart'; // 메인 대시보드 화면 import
// import 'core/theme/app_theme.dart'; // 테마 import

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UserProfileStorage _profileStorage = UserProfileStorage(); // 저장소 인스턴스
  bool _isLoading = true; // 로딩 상태
  bool _hasProfile = false; // 프로필 존재 여부 상태

  @override
  void initState() {
    super.initState();
    _checkUserProfile(); // 앱 시작 시 프로필 확인
  }

  // 로컬 저장소에서 사용자 프로필 존재 여부 확인
  Future<void> _checkUserProfile() async {
    // hasUserProfile()은 프로필 키가 저장소에 있는지 여부를 bool로 반환합니다.
    final hasProfile = await _profileStorage.hasUserProfile();
    if (mounted) {
      setState(() {
        _hasProfile = hasProfile; // 상태 업데이트
        _isLoading = false; // 로딩 완료
      });
      print("User profile exists: $hasProfile"); // 확인용 로그 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건강 날씨 앱 (가칭)',
      // theme: ...,
      home: _buildHomeScreen(), // 홈 화면 결정 로직 호출
    );
  }

  // 로딩 상태 및 프로필 유무에 따라 홈 화면 결정
  Widget _buildHomeScreen() {
    if (_isLoading) {
      // 로딩 중일 때
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      // 로딩 완료 후, 프로필 유무에 따라 다른 화면 표시
      if (_hasProfile) {
        print("Navigating to DashboardScreen"); // 확인용 로그
        return const DashboardScreen(); // 프로필 있으면 대시보드
      } else {
        print("Navigating to InitialSetupScreen"); // 확인용 로그
        return const InitialSetupScreen(); // 프로필 없으면 초기 설정 화면
      }
    }
  }
}
