// lib/providers/shelter_map_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart'; // Position 사용 위해
import '../models/response/shelter_map_response.dart';
import '../services/api_service.dart';
import 'map_cache_provider.dart'; // 지도 캐시 프로바이더
import 'health_index_provider.dart'; // apiService 프로바이더 가져오기 위해
import 'location_provider.dart'; // 현재 위치 정보 가져오기 위해

part 'shelter_map_provider.g.dart';

/// 재난 유형과 위치 기반으로 대피소 지도 데이터를 가져오는 프로바이더 (Family 사용)
@riverpod
Future<ShelterMapResponse> shelterMap(
  ShelterMapRef ref,
  // family 파라미터: 재난 유형과 위치 정보를 담는 객체 또는 개별 전달
  // 여기서는 개별 전달 방식 사용
  String disasterType,
  // 위치 정보는 직접 파라미터로 받거나, 내부에서 locationProvider를 watch
  // 여기서는 내부에서 watch하는 방식 사용 (위치가 변경되어도 자동 갱신되도록)
) async {
  final api = ref.watch(apiServiceProvider);
  final cacheNotifier = ref.read(mapCacheProvider.notifier);
  final cacheState = ref.watch(mapCacheProvider);
  // 현재 위치 정보 가져오기 (비동기)
  final position = await ref.watch(currentPositionProvider.future);

  // 캐시 키 생성 (예: 'shelter_EARTHQUAKE')
  final cacheKey = 'shelter_$disasterType';

  // 캐시 확인 (UI에서 캐시 우선 표시 로직은 별도 구현)
  if (cacheState.containsKey(cacheKey)) {
    print("대피소 지도 캐시 확인됨: $disasterType (데이터는 새로 가져옴)");
  }

  print(
    "대피소 지도 API 요청: $disasterType at ${position.latitude}, ${position.longitude}",
  );
  try {
    final response = await api.getShelterMap(
      latitude: position.latitude,
      longitude: position.longitude,
      disasterType: disasterType,
      // radiusKm는 필요시 파라미터로 받거나 기본값 사용
    );

    // 응답 HTML 캐싱
    if (response.shelterMapHtml != null &&
        response.shelterMapHtml!.isNotEmpty) {
      cacheNotifier.addMap(cacheKey, response.shelterMapHtml!);
    }
    return response;
  } catch (e) {
    print("대피소 지도 로딩 중 오류 ($disasterType): $e");
    rethrow;
  }
}
