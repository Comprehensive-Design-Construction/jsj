import 'package:flutter/material.dart';

class AppTheme {
  // 이미지에서 영감을 받은 색상 정의
  static const Color primaryPurple = Color(0xFF6A11CB);
  static const Color accentBlue = Color(0xFF2575FC); // 보조색 또는 강조색으로 사용

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light, // 밝은 테마
    primaryColor: primaryPurple, // 기본 색상 (보라)
    hintColor: accentBlue, // 보조 색상 (파랑) - Input 등에서 활용
    scaffoldBackgroundColor: Colors.white, // 기본 화면 배경색
    appBarTheme: const AppBarTheme(
      // 앱 바 스타일
      backgroundColor: Colors.white, // 흰색 배경
      elevation: 0.5, // 약간의 그림자
      iconTheme: IconThemeData(color: Colors.black87), // 아이콘 색상
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ), // 제목 스타일
    ),
    textTheme: const TextTheme(
      // 기본 텍스트 스타일 정의
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      titleLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontSize: 16,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 24,
      ), // 지역 이름 등
      displaySmall: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 36,
      ), // 큰 숫자 (온도 등)
    ),
    cardTheme: CardTheme(
      // 카드 스타일
      elevation: 2, // 그림자 깊이
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // 둥근 모서리
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // 카드 간격
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      // 세그먼트 버튼 (지도/대피소 선택) 스타일
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            // 선택된 버튼 배경색 (연보라)
            return primaryPurple.withOpacity(0.15);
          }
          // 선택되지 않은 버튼 배경색 (회색)
          return Colors.grey[200];
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            // 선택된 버튼 텍스트/아이콘 색상 (진보라)
            return primaryPurple;
          }
          // 선택되지 않은 버튼 텍스트/아이콘 색상
          return Colors.black54;
        }),
        // 버튼 테두리 제거
        side: MaterialStateProperty.all(BorderSide.none),
        // 버튼 모양 (기본값 사용 또는 shape 지정 가능)
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // 주요 액션 버튼 스타일
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple, // 기본 배경색
        foregroundColor: Colors.white, // 텍스트/아이콘 색상
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      // 텍스트 버튼 스타일
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple, // 기본 텍스트 색상
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      // 텍스트 입력 필드 스타일
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryPurple, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
      floatingLabelStyle: const TextStyle(color: primaryPurple),
    ),
    // 기타 필요한 테마 속성 추가 (e.g., iconTheme, floatingActionButtonTheme)
  );

  // 다크 테마 정의 (선택 사항)
  // static final ThemeData darkTheme = ThemeData(...);
}
