import 'package:flutter/material.dart';

// !!! 중요: 백엔드 서버가 실행 중인 PC의 로컬 IP 주소로 변경하세요 !!!
const String backendUrl = 'http://192.168.0.106:5000'; // <-- 여기를 수정하세요!

// --- 고정 위치 설정 ---
const double fixedLatitude = 37.5665; // 예: 서울 시청
const double fixedLongitude = 126.9780;

// --- 재난 유형 Enum ---
enum ShelterType { HEAT_WAVE, COLD_WAVE, FINE_DUST, FLOOD, EARTHQUAKE }

// Enum을 API 파라미터 문자열 및 UI 표시 문자열로 변환하는 확장 메소드
extension ShelterTypeExtension on ShelterType {
  String get apiParam {
    // enum 값의 이름을 그대로 사용 (예: ShelterType.HEAT_WAVE -> "HEAT_WAVE")
    return name;
  }

  String get displayName {
    switch (this) {
      case ShelterType.HEAT_WAVE:
        return '폭염';
      case ShelterType.COLD_WAVE:
        return '한파';
      case ShelterType.FINE_DUST:
        return '미세먼지';
      case ShelterType.FLOOD:
        return '홍수';
      case ShelterType.EARTHQUAKE:
        return '지진';
      default:
        return '';
    }
  }
}

// UI 색상 등 기타 상수 추가 가능
const Color primaryColor = Colors.blueAccent;
const Color cardBackgroundColor = Colors.white;
const Color chipSelectedColor = Colors.blueAccent;
const Color chipUnselectedColor = Colors.grey;
