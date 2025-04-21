import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/response/env_map_response.dart';
import '../models/common/request_info.dart'; // RequestInfo import 추가
import '../services/api_service.dart';
import 'map_cache_provider.dart';
import 'health_index_provider.dart';

part 'env_map_provider.g.dart';

@Riverpod(keepAlive: true)
Future<EnvMapResponse> environmentMap(
  EnvironmentMapRef ref,
  String envType,
) async {
  final api = ref.watch(apiServiceProvider);
  // ref.watch로 캐시 상태 변경을 감지하고, ref.read로 최신 캐시 값을 읽음
  final cache = ref.read(mapCacheProvider);
  final cacheNotifier = ref.read(mapCacheProvider.notifier);
  final cacheKey = 'env_$envType';

  // --- 클라이언트 캐시 우선 확인 로직 추가 ---
  final cachedHtml = cache[cacheKey];
  if (cachedHtml != null && cachedHtml.isNotEmpty) {
    print("환경 지도 반환 (Client Cache Hit): $envType");
    // 캐시된 HTML을 사용하여 즉시 응답 객체 반환 (API 호출 없음)
    // 주의: requestInfo는 실제 요청 정보가 아닐 수 있음 (플레이스홀더 사용)
    final cachedRequestInfo = RequestInfo(
      envType: envType,
      forceRefresh: false,
      // 다른 RequestInfo 필드는 null 또는 기본값
    );
    // EnvMapResponse 객체를 직접 생성하여 반환 (Future로 감쌀 필요 없음)
    return EnvMapResponse(
      requestInfo: cachedRequestInfo,
      envMapHtml: cachedHtml,
      envType: envType, // 요청된 envType 사용
      lastUpdated: null, // 캐시에는 lastUpdated 정보가 없음
      error: null,
    );
  }
  // -----------------------------------------

  // 캐시 미스: API 호출 진행
  print("환경 지도 API 요청 (Client Cache Miss): $envType");
  try {
    final response = await api.getEnvMap(envType: envType);

    // 유효한 HTML 응답을 캐시에 저장
    if (response.envMapHtml != null && response.envMapHtml!.isNotEmpty) {
      // 여기서 state 업데이트 전에 위젯이 dispose되면 에러 발생 가능하므로
      // ref.read가 아닌 cacheNotifier 사용이 더 안전
      cacheNotifier.addMap(cacheKey, response.envMapHtml!);
    }
    return response; // API 응답 반환
  } catch (e) {
    print("환경 지도 로딩 중 오류 ($envType): $e");
    rethrow;
  }
}
