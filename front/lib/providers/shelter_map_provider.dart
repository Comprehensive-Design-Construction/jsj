import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/response/shelter_map_response.dart';
import '../models/common/request_info.dart'; // RequestInfo import
import '../services/api_service.dart';
import 'map_cache_provider.dart';
import 'health_index_provider.dart';
import 'location_provider.dart';

part 'shelter_map_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ShelterMapResponse> shelterMap(
  ShelterMapRef ref,
  String disasterType,
) async {
  final api = ref.watch(apiServiceProvider);
  final cache = ref.read(mapCacheProvider); // 캐시 읽기
  final cacheNotifier = ref.read(mapCacheProvider.notifier); // 캐시 쓰기
  final position = await ref.watch(currentPositionProvider.future); // 위치 정보 필요
  final cacheKey = 'shelter_$disasterType';

  // --- 클라이언트 캐시 우선 확인 로직 추가 ---
  final cachedHtml = cache[cacheKey];
  if (cachedHtml != null && cachedHtml.isNotEmpty) {
    print("대피소 지도 반환 (Client Cache Hit): $disasterType");
    // 캐시된 HTML 사용하여 응답 객체 반환
    final cachedRequestInfo = RequestInfo(
      disasterType: disasterType,
      reqLatitude: position.latitude,
      reqLongitude: position.longitude,
      // 다른 RequestInfo 필드는 null 또는 기본값
    );
    return ShelterMapResponse(
      requestInfo: cachedRequestInfo,
      shelterMapHtml: cachedHtml,
      error: null,
    );
  }
  // -----------------------------------------

  // 캐시 미스: API 호출 진행
  print(
    "대피소 지도 API 요청 (Client Cache Miss): $disasterType at ${position.latitude}, ${position.longitude}",
  );
  try {
    final response = await api.getShelterMap(
      latitude: position.latitude,
      longitude: position.longitude,
      disasterType: disasterType,
    );

    // 유효한 HTML 응답 캐싱
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
