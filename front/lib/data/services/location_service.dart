// // import 'package:geolocator/geolocator.dart';
// import 'dart:async';
// import '../../core/constants/app_constants.dart'; // 상수 import

// class LocationService {
//   // 기본 위치 Position 객체 생성
//   static final Position _defaultPosition = Position(
//     latitude: defaultLatitude, // from app_constants.dart
//     longitude: defaultLongitude, // from app_constants.dart
//     timestamp: DateTime.now(),
//     accuracy: 0.0,
//     altitude: 0.0,
//     altitudeAccuracy: 0.0,
//     heading: 0.0,
//     headingAccuracy: 0.0,
//     speed: 0.0,
//     speedAccuracy: 0.0,
//   );

//   Future<Position> determinePosition() async {
//     // ... (이전과 동일한 권한 확인 및 위치 가져오기 로직) ...
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('위치 서비스 비활성화 -> 기본 위치(서울) 사용');
//       return _defaultPosition;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('위치 권한 거부 -> 기본 위치(서울) 사용');
//         return _defaultPosition;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       print('위치 권한 영구 거부 -> 기본 위치(서울) 사용');
//       return _defaultPosition;
//     }

//     try {
//       print('현재 위치 정보 가져오기 시도...');
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );
//     } on TimeoutException catch (_) {
//       print('현재 위치 정보 타임아웃 -> 기본 위치(서울) 사용');
//       return _defaultPosition;
//     } catch (e) {
//       print('현재 위치 정보 실패 -> 기본 위치(서울) 사용. 오류: $e');
//       return _defaultPosition;
//     }
//   }
// }
