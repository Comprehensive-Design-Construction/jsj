// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 현재 장치의 위치 권한 상태를 확인하고 필요한 경우 권한을 요청합니다.
  /// 권한이 부여되면 true, 아니면 false를 반환합니다.
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 활성화 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // TODO: 사용자에게 위치 서비스를 켜도록 안내 (예: 앱 설정 열기)
      print("Location services are disabled. Please enable the services");
      // 또는 특정 예외 발생
      throw LocationServiceDisabledException();
      // return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied");
        // TODO: 사용자에게 권한 거부 메시지 표시
        throw LocationPermissionDeniedException();
        // return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우 설정으로 안내
      print(
        "Location permissions are permanently denied, we cannot request permissions.",
      );
      // TODO: 사용자에게 설정에서 권한 변경 안내
      throw LocationPermissionDeniedForeverException();
      // return false;
    }

    // 여기까지 왔다면 권한이 부여된 것
    return true;
  }

  /// 장치의 현재 위치를 가져옵니다.
  /// 위치 권한이 없거나 서비스를 사용할 수 없으면 예외를 발생시킵니다.
  Future<Position> getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      // 이 경우는 위에서 예외가 발생하므로 실제로는 도달하기 어려움
      throw Exception("Location permission not granted.");
    }

    try {
      // 정확도 높은 위치 가져오기 (필요에 따라 desiredAccuracy 조정)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Error getting current location: $e");
      // 다양한 예외 상황 처리 (예: 타임아웃)
      rethrow; // 호출한 곳에서 처리하도록 예외 다시 던지기
    }
  }
}

// 커스텀 예외 클래스 (선택적이지만 권장)
class LocationServiceDisabledException implements Exception {
  final String message = "Location services are disabled.";
}

class LocationPermissionDeniedException implements Exception {
  final String message = "Location permissions are denied.";
}

class LocationPermissionDeniedForeverException implements Exception {
  final String message = "Location permissions are permanently denied.";
}
