// lib/features/initial_setup/presentation/screens/initial_setup_screen.dart
import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart'; // UserProfile 모델
import '../../../../core/storage/user_profile_storage.dart'; // 저장소 유틸리티
import '../widgets/user_info_form.dart'; // 폼 위젯
import '../../../dashboard/presentation/screens/dashboard_screen.dart'; // 대시보드 화면

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final UserProfileStorage _storage = UserProfileStorage();
  bool _isSaving = false; // 저장 중 상태 표시용

  // "시작하기" 버튼 클릭 시 호출될 함수
  Future<void> _submitProfile(
    String? name,
    DateTime? dob,
    String? gender,
    List<String> diseases,
  ) async {
    if (_isSaving) return; // 중복 저장 방지

    setState(() {
      _isSaving = true;
    });

    // UserProfile 객체 생성
    final profile = UserProfile(
      name: name,
      dob: dob?.toIso8601String().substring(0, 10), // YYYY-MM-DD 형식으로 저장
      gender: gender,
      diseases: diseases,
    );

    try {
      final success = await _storage.saveUserProfile(profile);
      if (success && mounted) {
        // 저장 성공 및 위젯 마운트 확인
        _navigateToDashboard();
      } else if (mounted) {
        // 저장 실패 시 사용자에게 알림 (간단한 스낵바 예시)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보 저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // "간편 시작" 버튼 클릭 시 호출될 함수
  Future<void> _skipSetup() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    // 기본 프로필 (질병 목록만 빈 리스트로 저장)
    final profile = UserProfile(diseases: []);
    try {
      final success = await _storage.saveUserProfile(profile);
      if (success && mounted) {
        _navigateToDashboard();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정보 저장에 실패했습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 대시보드 화면으로 이동 (현재 화면 스택에서 제거하고 이동)
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      // pushReplacement로 뒤로가기 막기
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 정보 입력')),
      body: Stack(
        // 저장 중 로딩 표시를 위해 Stack 사용
        children: [
          // 사용자 정보 입력 폼
          UserInfoForm(onSubmit: _submitProfile, onSkip: _skipSetup),
          // 저장 중일 때 로딩 인디케이터 표시
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3), // 반투명 배경
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
