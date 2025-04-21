import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/env_map_provider.dart'; // 환경 지도 데이터 프로바이더
import '../../../providers/map_cache_provider.dart'; // 지도 캐시 프로바이더
import '../../../widgets/map_webview.dart'; // WebView 위젯
import '../../../screens/loading_error/loading_indicator.dart'; // 로딩 위젯
import '../../../screens/loading_error/error_message.dart'; // 에러 메시지 위젯
import '../../../models/response/env_map_response.dart';

// 환경 지도 유형 정의 Enum
enum EnvMapType { fineDust, uv }

// EnvMapType Enum 확장 함수 (API 값, 표시 이름 반환)
extension EnvMapTypeExtension on EnvMapType {
  String get apiValue {
    switch (this) {
      case EnvMapType.fineDust:
        return 'fine_dust';
      case EnvMapType.uv:
        return 'uv';
    }
  }

  String get displayName {
    switch (this) {
      case EnvMapType.fineDust:
        return '미세먼지';
      case EnvMapType.uv:
        return '자외선';
    }
  }

  // 필요시 아이콘 추가
  // IconData get icon { ... }
}

/// 환경 지도 선택 및 표시 섹션 위젯 (StatefulWidget으로 상태 관리)
class EnvMapSection extends ConsumerStatefulWidget {
  const EnvMapSection({super.key});

  @override
  ConsumerState<EnvMapSection> createState() => _EnvMapSectionState();
}

class _EnvMapSectionState extends ConsumerState<EnvMapSection> {
  // 현재 선택된 지도 유형 상태 변수 (기본값: 미세먼지)
  EnvMapType _selectedMapType = EnvMapType.fineDust;

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시, 기본 선택된 지도 외 다른 지도들 미리 로드 시도
    _prefetchOtherMaps();
  }

  // 선택되지 않은 지도들을 백그라운드에서 미리 로드하는 함수
  void _prefetchOtherMaps() {
    // 사용 가능한 모든 지도 유형 순회
    for (var type in EnvMapType.values) {
      // 현재 선택된 유형이 아니면
      if (type != _selectedMapType) {
        final cacheKey = 'env_${type.apiValue}';
        // 캐시에 없고, 현재 로딩 중이지 않은 경우에만 프리페치 시도
        // (정확한 로딩 상태 확인은 provider 상태를 참조해야 하나, 여기서는 캐시 유무로 간략화)
        if (!ref.read(mapCacheProvider).containsKey(cacheKey)) {
          print("환경 지도 프리페치 시도: ${type.apiValue}");
          // 비동기 호출 실행 (await 하지 않음 - 백그라운드 실행)
          // 오류 발생 시 로그만 출력 (사용자에게 직접적인 영향 X)
          ref.read(environmentMapProvider(type.apiValue).future).catchError((
            e,
          ) {
            print("환경 지도 프리페치 실패 (${type.apiValue}): $e");
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 지도의 API 값
    final selectedApiValue = _selectedMapType.apiValue;
    // 캐시 프로바이더 상태 감시
    final cache = ref.watch(mapCacheProvider);
    // 캐시에서 현재 선택된 지도의 HTML 가져오기
    final mapHtmlFromCache = cache['env_$selectedApiValue'];

    // 현재 선택된 지도 유형에 대한 데이터 프로바이더 상태 감시
    // .family(selectedApiValue) 형태로 특정 파라미터에 대한 상태 추적
    final mapAsync = ref.watch(environmentMapProvider(selectedApiValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // 자식 위젯 가로 폭 채우기
      children: [
        // 지도 선택 버튼 (SegmentedButton 사용)
        SegmentedButton<EnvMapType>(
          // 각 버튼 세그먼트 정의
          segments:
              EnvMapType.values.map((type) {
                return ButtonSegment<EnvMapType>(
                  value: type, // 버튼 값 (Enum)
                  label: Text(type.displayName), // 버튼 텍스트
                  // icon: Icon(type.icon), // 필요시 아이콘 추가
                );
              }).toList(),
          // 현재 선택된 버튼 값 (Set 형태)
          selected: {_selectedMapType},
          // 선택 변경 시 호출될 콜백 함수
          onSelectionChanged: (Set<EnvMapType> newSelection) {
            if (newSelection.isNotEmpty) {
              // 상태 업데이트하여 UI 리빌드 트리거
              setState(() {
                _selectedMapType = newSelection.first;
                print("선택된 환경 지도: ${_selectedMapType.apiValue}");
                // 선택 변경 시 자동으로 해당 타입의 프로바이더(mapAsync)가
                // 재실행/업데이트되므로 여기서 직접 fetch할 필요 없음.
                // 필요하다면 여기서 다른 지도 프리페치 로직 다시 호출 가능
                _prefetchOtherMaps(); // 다른 맵 다시 프리페치 시도
              });
            }
          },
          // 테마에서 정의된 스타일 적용
          style: Theme.of(context).segmentedButtonTheme.style,
          showSelectedIcon: false, // 선택 표시 아이콘 숨김 (선택 사항)
        ),
        const SizedBox(height: 12), // 버튼과 지도 사이 간격
        // 지도 표시 영역 (캐시 또는 프로바이더 상태에 따라 분기)
        _buildMapView(mapAsync, mapHtmlFromCache, selectedApiValue),
      ],
    );
  }

  /// 지도 WebView를 빌드하는 함수 (상태에 따라 분기 처리)
  Widget _buildMapView(
    AsyncValue<EnvMapResponse> mapAsync,
    String? mapHtmlFromCache,
    String apiKey,
  ) {
    final cacheKey = 'env_$apiKey'; // 캐시 키 일관성 유지

    // 1순위: 캐시에 유효한 HTML이 있으면 즉시 표시
    if (mapHtmlFromCache != null && mapHtmlFromCache.isNotEmpty) {
      print("캐시된 환경 지도 표시: $apiKey");
      return MapWebView(htmlContent: mapHtmlFromCache, mapKey: cacheKey);
    }

    // 2순위: 캐시가 없으면 프로바이더의 상태에 따라 표시
    return mapAsync.when(
      // 로딩 중: AspectRatio로 높이 유지하며 로딩 인디케이터 표시
      loading:
          () => const AspectRatio(
            aspectRatio: 100 / 60,
            child: LoadingIndicator(),
          ),
      // 오류 발생 시: 에러 메시지 표시 및 재시도 버튼
      error: (err, stack) {
        print("환경 지도 로딩 오류 ($apiKey): $err");
        return AspectRatio(
          aspectRatio: 100 / 60,
          child: ErrorMessage(
            message: '${_selectedMapType.displayName} 지도를 불러올 수 없습니다.',
            onRetry: () {
              // 특정 지도 유형에 대한 프로바이더만 invalidate하여 재시도
              ref.invalidate(environmentMapProvider(apiKey));
            },
          ),
        );
      },
      // 데이터 로딩 성공 시
      data: (mapData) {
        // API 응답에 유효한 HTML이 있는지 확인
        if (mapData.envMapHtml != null && mapData.envMapHtml!.isNotEmpty) {
          print("Fetch된 환경 지도 표시: $apiKey");
          // 데이터 로딩 성공 시 캐시가 업데이트되었을 수 있으므로, 캐시를 한번 더 확인
          final currentCacheHtml = ref.read(mapCacheProvider)[cacheKey];
          return MapWebView(
            // 캐시가 방금 업데이트되었다면 캐시 우선 사용, 아니면 API 응답 사용
            htmlContent: currentCacheHtml ?? mapData.envMapHtml,
            mapKey: cacheKey,
          );
        } else {
          // API는 성공했으나 HTML 데이터가 없는 경우
          print("환경 지도 데이터 없음 ($apiKey)");
          return AspectRatio(
            aspectRatio: 100 / 60,
            child: Center(
              child: Text(
                '${_selectedMapType.displayName} 지도 데이터 없음',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          );
        }
      },
    );
  }
}
