import 'package:flutter/material.dart';

// 기본 위치 (서울 시청 근처) - 위치 권한 거부 시 사용
const double defaultLatitude = 37.5665;
const double defaultLongitude = 126.9780;

// 기본 API URL - 실제 IP로 변경 필수!
const String baseUrl = 'http://192.168.0.28:5000/api'; // <<<--- 여기를 수정하세요!

// 색상 상수 (앱 전체에서 사용될 수 있는 색상)
const Color primaryColor = Colors.blueAccent;

// 기타 상수
const Duration apiTimeout = Duration(seconds: 15);
