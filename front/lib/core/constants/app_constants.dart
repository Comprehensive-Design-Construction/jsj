import 'package:flutter/material.dart';

// 기본 위치 (서울 시청 근처) - 위치 권한 거부 시 사용
const double defaultLatitude = 37.5665;
const double defaultLongitude = 126.9780;

// 기본 API URL - 실제 IP로 변경 필수!
const String baseUrl = 'http://192.168.0.106:5000/api'; // <<<--- 여기를 수정하세요!

// 색상 상수 (앱 전체에서 사용될 수 있는 색상)
const Color primaryColor = Colors.blueAccent;

// 기타 상수
const Duration apiTimeout = Duration(seconds: 15);

// 앱에서 표시 가능한 건강 지수 이름 목록 (DataMapper 확인)
const List<String> availableHealthIndices = [
  '천식질환 지수',
  '심뇌혈관질환 지수',
  '감기가능 지수',
  '식중독 지수',
  '자외선 지수',
  '미세먼지 지수',
  '꽃가루농도 지수(소나무)', // API 연동 안된 지수 포함 여부 결정 필요
  '대기정체 지수', // API 연동 안된 지수 포함 여부 결정 필요
];
