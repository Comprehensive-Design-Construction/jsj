import 'package:geolocator/geolocator.dart'; // 위치 정보 패키지
// 권한 요청 패키지
import '../constants/app_constants.dart'; // 기본 위치 정보 상수

class LocationService {
  /// 현재 위치 정보를 비동기적으로 가져옴
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 활성화 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('위치 서비스 비활성화됨. 기본 위치 사용.');
      // 사용자에게 위치 서비스 활성화를 유도하는 UI 표시 고려
      return _getDefaultPosition();
    }

    // 위치 권한 상태 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 거부된 경우, 권한 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('위치 권한 거부됨. 기본 위치 사용.');
        // 권한이 필요한 이유를 설명하는 UI 표시 고려
        return _getDefaultPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우
      print('위치 권한 영구적으로 거부됨. 기본 위치 사용.');
      // 사용자가 직접 앱 설정에서 권한을 변경하도록 안내하는 UI 표시
      _showSettingsDialog(); // 설정 안내 함수 호출 (UI 구현 필요)
      return _getDefaultPosition();
    }

    // 권한이 허용된 경우, 현재 위치 정보 가져오기 시도
    try {
      return await Geolocator.getCurrentPosition(
        // 원하는 정확도 설정 (medium이 배터리와 정확도 균형 적절)
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      // 위치 정보 가져오기 실패 시 (타임아웃 등)
      print("위치 정보 가져오기 오류: $e. 기본 위치 사용.");
      return _getDefaultPosition();
    }
  }

  /// 기본 위치 정보 반환 (상수 파일 값 사용)
  Position _getDefaultPosition() {
    return Position(
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// 사용자에게 앱 설정 화면으로 이동하여 권한을 변경하도록 안내하는 함수 (구현 필요)
  void _showSettingsDialog() {
    // TODO: AlertDialog 또는 다른 방법을 사용하여 사용자 안내 UI 구현
    print("TODO: 사용자가 설정에서 위치 권한을 켜도록 안내하는 다이얼로그 구현.");
    // 예시: permission_handler의 openAppSettings() 함수 사용 가능
    // openAppSettings();
  }
}
