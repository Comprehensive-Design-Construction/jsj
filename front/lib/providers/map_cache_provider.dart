import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_cache_provider.g.dart';

/// 지도 HTML 컨텐츠를 위한 간단한 인메모리 캐시 프로바이더
/// key: 'env_fine_dust', 'shelter_EARTHQUAKE' 등
/// value: 지도 HTML 문자열
@Riverpod(keepAlive: true) // 앱이 살아있는 동안 캐시 유지
class MapCache extends _$MapCache {
  @override
  Map<String, String> build() {
    // 초기 캐시는 비어 있음
    return {};
  }

  /// 캐시에 지도 HTML 추가 또는 업데이트
  void addMap(String key, String html) {
    // 불변성을 유지하기 위해 새로운 Map 객체를 생성하여 state 업데이트
    state = {...state, key: html};
    print("지도 캐시됨: $key");
  }

  /// 캐시에서 지도 HTML 가져오기 (없으면 null 반환)
  String? getMap(String key) {
    return state[key];
  }

  /// 해당 키의 캐시가 존재하는지 확인
  bool hasMap(String key) {
    return state.containsKey(key);
  }
}
