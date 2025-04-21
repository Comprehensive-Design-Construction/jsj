import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/response/env_map_response.dart';
import '../services/api_service.dart';
import 'map_cache_provider.dart'; // 지도 캐시 프로바이더 import
import 'health_index_provider.dart'; // apiService 프로바이더를 가져오기 위해 import (또는 별도 정의)

part 'env_map_provider.g.dart';

/// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
@riverpod
Future<EnvMapResponse> environmentMap(
  EnvironmentMapRef ref,
  String envType,
) async {
  final api = ref.watch(apiServiceProvider); // ApiService 인스턴스 가져오기
  final cacheNotifier = ref.read(
    mapCacheProvider.notifier,
  ); // 캐시 상태 변경 위한 Notifier
  final cacheState = ref.watch(mapCacheProvider); // 캐시 상태 변화 감지 위한 watch

  // 캐시 키 생성 (예: 'env_fine_dust')
  final cacheKey = 'env_$envType';

  // 캐시에 데이터가 있으면 바로 사용하지는 않고, 최신 데이터를 가져오되
  // UI에서는 캐시된 HTML을 우선적으로 보여줄 수 있도록 함.
  // (API 응답 구조가 캐시된 데이터만으로 충분하다면 캐시된 객체를 바로 반환 가능)
  if (cacheState.containsKey(cacheKey)) {
    print("환경 지도 캐시 확인됨: $envType (데이터는 새로 가져옴)");
  }

  print("환경 지도 API 요청: $envType");
  try {
    // API 호출하여 최신 데이터 가져오기
    final response = await api.getEnvMap(envType: envType);

    // 응답에 HTML 컨텐츠가 있으면 캐시에 저장
    if (response.envMapHtml != null && response.envMapHtml!.isNotEmpty) {
      cacheNotifier.addMap(cacheKey, response.envMapHtml!);
    }

    return response; // 최신 응답 반환
  } catch (e) {
    print("환경 지도 로딩 중 오류 ($envType): $e");
    // 오류 발생 시 사용자에게 알릴 수 있도록 rethrow 또는 에러 상태 포함 응답 반환
    rethrow; // 호출한 쪽에서 에러 처리하도록 다시 던짐
  }
}
