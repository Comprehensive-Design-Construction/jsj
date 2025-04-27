// lib/screens/shelter_map/widgets/shelter_map_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_constants.dart'; // availableDisasterTypes 사용
import '../../../providers/shelter_map_provider.dart'; // 대피소 지도 데이터 프로바이더
import '../../../providers/map_cache_provider.dart'; // 지도 캐시 프로바이더
import '../../../widgets/map_webview.dart'; // WebView 위젯
import '../../../screens/loading_error/loading_indicator.dart'; // 로딩 위젯
import '../../../screens/loading_error/error_message.dart'; // 에러 메시지 위젯
import '../../../models/response/shelter_map_response.dart';

/// 재난 유형 정의 Enum (API 값과 표시 이름 매핑)
enum DisasterType {
  coldWave("COLD_WAVE", "한파"),
  heatWave("HEAT_WAVE", "폭염"),
  fineDust("FINE_DUST", "미세먼지"),
  flood("FLOOD", "홍수"),
  earthquake("EARTHQUAKE", "지진");

  const DisasterType(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  // API 문자열 값으로 Enum 찾기 (없으면 기본값 반환)
  static DisasterType fromApiValue(String apiValue) {
    return DisasterType.values.firstWhere(
      (type) => type.apiValue == apiValue.toUpperCase(),
      orElse: () => DisasterType.earthquake,
    ); // 기본값: 지진
  }
}

/// 대피소 지도 선택 및 표시 섹션 위젯
class ShelterMapSection extends ConsumerStatefulWidget {
  const ShelterMapSection({super.key});

  @override
  ConsumerState<ShelterMapSection> createState() => _ShelterMapSectionState();
}

class _ShelterMapSectionState extends ConsumerState<ShelterMapSection> {
  // 현재 선택된 재난 유형 상태 변수 (기본값: 지진)
  DisasterType _selectedDisasterType = DisasterType.earthquake;

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시, 기본 선택된 유형 외 다른 유형 지도 미리 로드 시도
    _prefetchOtherMaps();
  }

  // 선택되지 않은 지도들을 백그라운드에서 미리 로드
  void _prefetchOtherMaps() {
    // 사용 가능한 모든 재난 유형 순회
    for (var type in DisasterType.values) {
      if (type != _selectedDisasterType) {
        final cacheKey = 'shelter_${type.apiValue}';
        // 캐시에 없으면 프리페치 시도
        if (!ref.read(mapCacheProvider).containsKey(cacheKey)) {
          print("대피소 지도 프리페치 시도: ${type.apiValue}");
          // shelterMapProvider 호출 (위치 정보는 프로바이더 내부에서 처리)
          ref.read(shelterMapProvider(type.apiValue).future).catchError((e) {
            print("대피소 지도 프리페치 실패 (${type.apiValue}): $e");
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 지도의 API 값
    final selectedApiValue = _selectedDisasterType.apiValue;
    // 캐시 프로바이더 상태 감시
    final cache = ref.watch(mapCacheProvider);
    // 캐시에서 현재 선택된 지도의 HTML 가져오기
    final mapHtmlFromCache = cache['shelter_$selectedApiValue'];

    // 현재 선택된 재난 유형에 대한 데이터 프로바이더 상태 감시
    final mapAsync = ref.watch(shelterMapProvider(selectedApiValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 재난 유형 선택 버튼 (SegmentedButton 사용)
        SegmentedButton<DisasterType>(
          segments:
              DisasterType.values.map((type) {
                return ButtonSegment<DisasterType>(
                  value: type,
                  label: Text(
                    type.displayName,
                    textAlign: TextAlign.center,
                  ), // 텍스트 중앙 정렬
                  tooltip: type.displayName, // 툴팁 추가
                );
              }).toList(),
          selected: {_selectedDisasterType},
          onSelectionChanged: (Set<DisasterType> newSelection) {
            if (newSelection.isNotEmpty) {
              setState(() {
                _selectedDisasterType = newSelection.first;
                print("선택된 대피소 유형: ${_selectedDisasterType.apiValue}");
                _prefetchOtherMaps(); // 다른 맵 다시 프리페치 시도
              });
            }
          },
          style: Theme.of(context).segmentedButtonTheme.style,
          multiSelectionEnabled: false, // 단일 선택만 가능하도록
          emptySelectionAllowed: false, // 빈 선택 불가능하도록
        ),
        const SizedBox(height: 12),

        // 지도 표시 영역
        _buildMapView(mapAsync, mapHtmlFromCache, selectedApiValue),

        const SizedBox(height: 16),
        // 간단한 안내 문구
        Text(
          "지도를 확대/축소하여 주변 대피소 위치를 확인하세요.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 지도 WebView 빌드 함수 (환경 지도와 로직 동일)
  Widget _buildMapView(
    AsyncValue<ShelterMapResponse> mapAsync,
    String? mapHtmlFromCache,
    String apiKey,
  ) {
    final cacheKey = 'shelter_$apiKey';

    // 1순위: 캐시된 HTML 사용
    if (mapHtmlFromCache != null && mapHtmlFromCache.isNotEmpty) {
      print("캐시된 대피소 지도 표시: $apiKey");
      return MapWebView(htmlContent: mapHtmlFromCache, mapKey: cacheKey);
    }

    // 2순위: 프로바이더 상태 기반 표시
    return mapAsync.when(
      loading:
          () => const AspectRatio(
            aspectRatio: 100 / 60,
            child: LoadingIndicator(),
          ),
      error: (err, stack) {
        print("대피소 지도 로딩 오류 ($apiKey): $err");
        return AspectRatio(
          aspectRatio: 100 / 60,
          child: ErrorMessage(
            message: '${_selectedDisasterType.displayName} 대피소 지도를 불러올 수 없습니다.',
            onRetry: () => ref.invalidate(shelterMapProvider(apiKey)),
          ),
        );
      },
      data: (mapData) {
        if (mapData.shelterMapHtml != null &&
            mapData.shelterMapHtml!.isNotEmpty) {
          print("Fetch된 대피소 지도 표시: $apiKey");
          final currentCacheHtml = ref.read(mapCacheProvider)[cacheKey];
          return MapWebView(
            htmlContent: currentCacheHtml ?? mapData.shelterMapHtml,
            mapKey: cacheKey,
          );
        } else {
          print("대피소 지도 데이터 없음 ($apiKey)");
          return AspectRatio(
            aspectRatio: 100 / 60,
            child: Center(
              child: Text(
                '${_selectedDisasterType.displayName} 대피소 지도 데이터 없음',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          );
        }
      },
    );
  }
}
