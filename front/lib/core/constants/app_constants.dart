import 'package:flutter/material.dart';

// 기본 위치 (서울 시청 근처) - 위치 권한 거부 시 사용
const double defaultLatitude = 37.5665;
const double defaultLongitude = 126.9780;

// --- API 관련 상수 ---
const String baseUrl = 'http://34.22.91.180:5000/api'; // 기본 API URL
const Duration apiTimeout = Duration(seconds: 15); // 일반 API 타임아웃
const Duration mapApiTimeout = Duration(seconds: 25); // 지도 API 타임아웃

// API 엔드포인트 경로
const String healthIndexEndpoint = '/index';
const String weatherEndpoint = '/weather';
const String fineDustEndpoint = '/environment/fine_dust';
const String uvEndpoint = '/environment/uv';
const String envMapEndpoint = '/env_map';
const String shelterMapEndpoint = '/map';
const String districtsEndpoint = '/districts';
const String dongsEndpoint = '/dongs';
const String coordinatesEndpoint = '/coordinates';
const String recommendationEndpoint = '/recommendation'; // 행동 요령 API 경로
// --------------------

// 색상 상수 (앱 전체에서 사용될 수 있는 색상)
const Color primaryColor = Colors.blueAccent;

// 앱에서 표시 가능한 건강 지수 이름 목록 (DataMapper 확인)
const List<String> availableHealthIndices = [
  '천식질환 지수',
  '심뇌혈관질환 지수',
  '감기가능 지수',
  '식중독 지수',
  '자외선 지수',
  '미세먼지 지수',
  // '꽃가루농도 지수(소나무)', // API 연동 여부에 따라 주석 처리
  // '대기정체 지수', // API 연동 여부에 따라 주석 처리
];

// 기본적으로 '주요 건강 지수'에 표시될 지수 목록 (MainScreen에서 사용)
const List<String> defaultMajorIndices = ['심뇌혈관질환 지수', '자외선 지수', '미세먼지 지수'];

// 사용 가능한 기저 질환 목록 (Preferences, 화면 등에서 사용)
const List<String> availableDiseases = [
  '당뇨병', // Diabetes (condition 7)
  '심뇌혈관질환', // Cardiovascular (condition 8)
  '호흡기 질환', // Respiratory (condition 9)
  // 필요시 다른 질환 추가
];

// --- 사용자 정보 관련 상수 ---
const String myInfoId = 'MY_INFO'; // '내 정보'를 나타내는 고유 ID
// --------------------------
