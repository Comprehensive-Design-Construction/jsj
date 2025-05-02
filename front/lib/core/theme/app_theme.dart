import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.grey[50], // 앱 전체 배경색
      fontFamily: 'Pretendard', // 앱 전체 폰트 (폰트 파일 및 pubspec.yaml 설정 필요)
      // 텍스트 테마 정의 (일관된 스타일 적용 위함)
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ), // AppBar 제목 등
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ), // 섹션 제목 등
        bodyLarge: TextStyle(fontSize: 14, color: Colors.grey[800]), // 일반 본문
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
          height: 1.4, // 줄간격 추가 (본문 가독성 향상)
        ), // 약간 작은 본문
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ), // 버튼 텍스트 등
      ),
      // AppBar 테마 설정
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50], // AppBar 배경색
        elevation: 0.5, // 약간의 그림자
        iconTheme: IconThemeData(color: Colors.black87), // AppBar 아이콘 색상
        titleTextStyle: TextStyle(
          // 기본값 사용 시 테마 상속 받음, 필요시 재정의
          fontSize: 18, // AppBar 제목 크기 약간 조정 (기존 코드 20)
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Pretendard',
        ),
      ),
      // BottomNavigationBar 테마 (선택 사항)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, // 아이템 4개 이상일 때 고정 타입
        selectedItemColor: Colors.blueAccent, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey[500], // 선택되지 않은 아이템 색상
        selectedLabelStyle: TextStyle(fontSize: 11), // 선택된 라벨 스타일 (크기만 지정)
        unselectedLabelStyle: TextStyle(fontSize: 11), // 선택되지 않은 라벨 스타일
        showSelectedLabels: false, // 라벨 숨김 (아이콘만 표시)
        showUnselectedLabels: false,
        backgroundColor: Colors.white, // 배경색 지정
        elevation: 2.0, // 약간의 그림자
      ),
      // 버튼 테마 등 다른 테마 요소 추가 가능
      // 예: ElevatedButtonThemeData(...)
    );
  }

  // 필요시 다크 모드 테마도 정의 가능
  // static ThemeData get darkTheme { ... }
}
