import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

part 'location_provider.g.dart'; // Riverpod Generator가 생성할 파일

// LocationService 인스턴스를 제공하는 프로바이더
@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

// 앱 시작 시 현재 위치를 비동기적으로 가져오는 프로바이더
// .future를 통해 Future 결과에 접근 가능
@riverpod
Future<Position> currentPosition(CurrentPositionRef ref) async {
  // locationServiceProvider를 통해 LocationService 인스턴스를 얻음
  final locationService = ref.watch(locationServiceProvider);
  // getCurrentLocation 함수 호출하여 위치 정보 반환
  return locationService.getCurrentLocation();
}
