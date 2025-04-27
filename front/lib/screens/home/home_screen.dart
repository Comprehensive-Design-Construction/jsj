// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/health_index_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/shelter_map_provider.dart'; // ShelterMap Provider import
import '../../providers/map_cache_provider.dart';
import '../../screens/loading_error/loading_indicator.dart';
import '../../screens/loading_error/error_message.dart';
import 'widgets/health_index_card.dart';
import 'widgets/env_map_section.dart';
import 'widgets/weather_display.dart';
import '../profile/profile_screen.dart';
import '../shelter_map/shelter_map_screen.dart';
import '../../models/response/health_indices_response.dart';
import '../../models/common/alert_info.dart';
import '../../constants/app_constants.dart'; // AppConstants import for disaster types
// ShelterMapSection에서 사용하던 DisasterType enum import (경로 확인 필요)
import '../shelter_map/widgets/shelter_map_section.dart' show DisasterType;

// ConsumerWidget -> ConsumerStatefulWidget으로 변경
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _shelterMapPreloadingInitiated = false; // 프리로딩 시작 플래그

  // 상태/레벨에 따른 색상 반환 (기존 로직과 동일)
  Color _getStatusColor(
    String? status, {
    bool isLevel = false,
    int? level,
    int maxLevel = 4,
  }) {
    // ... 기존 _getStatusColor 함수 내용 ...
    if (isLevel && level != null) {
      // 레벨 기반 색상 결정 (예시)
      if (level <= maxLevel * 0.25) return Colors.red.shade700; // 위험
      if (level <= maxLevel * 0.5) return Colors.orange.shade700; // 경고
      if (level <= maxLevel * 0.75) return Colors.yellow.shade800; // 주의
      return Colors.green.shade600; // 관심/안전
    } else {
      // 상태 텍스트 기반 색상 결정
      switch (status?.toLowerCase()) {
        case '안전':
        case '낮음':
        case '관심':
          return Colors.green.shade600;
        case '주의':
          return Colors.yellow.shade800;
        case '경고':
          return Colors.orange.shade700;
        case '위험':
        case '매우높음':
          return Colors.red.shade700;
        default:
          return Colors.grey; // 알 수 없거나 N/A
      }
    }
  }

  // 대피소 지도 프리로딩 함수
  void _initiateShelterMapPreloading() {
    // 이미 시작했으면 다시 실행하지 않음
    if (_shelterMapPreloadingInitiated) return;

    // 위치 정보가 아직 로드되지 않았으면 실행하지 않음
    final locationAsync = ref.read(currentPositionProvider);
    if (!locationAsync.hasValue) return;

    setState(() {
      _shelterMapPreloadingInitiated = true; // 플래그 설정
    });

    print("Initiating shelter map preloading...");
    // AppConstants 또는 DisasterType enum 사용
    // 예시: DisasterType enum 사용
    for (var type in DisasterType.values) {
      final apiValue = type.apiValue;
      print("  Preloading shelter map for: $apiValue");
      // .future를 읽어 프로바이더 실행, 완료나 오류는 백그라운드 처리
      ref
          .read(shelterMapProvider(apiValue).future)
          .then((_) {
            print("  Successfully preloaded shelter map: $apiValue");
          })
          .catchError((e, s) {
            // 프리로딩 실패는 사용자 경험에 치명적이지 않으므로 로그만 남김
            print("  Preloading failed for shelter map $apiValue: $e");
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위치 정보 상태 감시
    final locationAsync = ref.watch(currentPositionProvider);
    // 건강 지수 상태 감시
    final healthIndexAsync = ref.watch(healthIndexDataProvider);

    // 위치 정보가 성공적으로 로드되면 프리로딩 시작 시도
    ref.listen<AsyncValue<dynamic>>(currentPositionProvider, (_, next) {
      if (next.hasValue && !_shelterMapPreloadingInitiated) {
        // listen 콜백 내에서 setState 호출은 안전하지 않으므로,
        // 다음 프레임에 실행되도록 예약하거나 다른 방식 사용.
        // 여기서는 간단히 함수 호출만 시도 (플래그는 내부에서 관리)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initiateShelterMapPreloading();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 건강 날씨'),
        actions: [
          // ... 기존 AppBar actions ...
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '건강 정보 입력',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '대피소 지도',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShelterMapScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 새로고침 시 프리로딩 플래그 초기화도 고려 가능
          // setState(() { _shelterMapPreloadingInitiated = false; });
          ref.invalidate(currentPositionProvider);
          ref.invalidate(healthIndexDataProvider);
          ref.invalidate(mapCacheProvider); // 지도 캐시 무효화
          // 모든 shelterMapProvider family 멤버 무효화 (주의: 성능 영향 가능)
          // AppConstants.availableDisasterTypes.forEach((type) => ref.invalidate(shelterMapProvider(type)));
          print("데이터 새로고침 중...");
        },
        child: locationAsync.when(
          loading: () => const LoadingIndicator(),
          error:
              (err, stack) => ErrorMessage(
                message: '위치 정보를 가져올 수 없습니다.\n$err',
                onRetry: () => ref.invalidate(currentPositionProvider),
              ),
          data: (position) {
            // 위치 로딩 성공 시 UI 빌드 시작
            // _initiateShelterMapPreloading(); // build 메소드 직접 호출보다 listen 사용 권장

            return healthIndexAsync.when(
              loading: () => const LoadingIndicator(),
              error:
                  (err, stack) => ErrorMessage(
                    message: '건강 지수 정보를 로드하는데 실패했습니다.\n$err',
                    onRetry: () => ref.invalidate(healthIndexDataProvider),
                  ),
              data: (healthData) {
                // ... 기존 healthData 처리 및 ListView UI 구성 ...
                final indices = healthData.indices;
                final region = healthData.region;
                final weather = healthData.weather;
                final alerts = healthData.alerts;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // ... 기존 섹션 1 (지역, 날씨) ...
                    Text(
                      '${region.gu} ${region.region}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (weather != null)
                      WeatherDisplay(weatherData: weather)
                    else
                      const WeatherDisplayPlaceholder(condition: "unknown"),
                    const SizedBox(height: 20),

                    // ... 기존 섹션 1.5 (알림) ...
                    if (alerts.isNotEmpty) ...[
                      Text(
                        "주의 알림",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              alerts
                                  .map(
                                    (alert) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange.shade700,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "[${alert.type}] ${alert.message}",
                                              style: TextStyle(
                                                color: Colors.orange.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ... 기존 섹션 2 (체감 온도) ...
                    Card(
                      color: _getStatusColor(
                        indices.apparentTempRiskStatus,
                      ).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _getStatusColor(
                            indices.apparentTempRiskStatus,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 20.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "현재 체감온도",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    indices.apparentTemperature != null
                                        ? '${indices.apparentTemperature?.toStringAsFixed(1)}°C'
                                        : 'N/A',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall?.copyWith(
                                      color: _getStatusColor(
                                        indices.apparentTempRiskStatus,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  indices.apparentTempRiskStatus,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                indices.apparentTempRiskStatus ?? '정보 없음',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ... 기존 섹션 3 (세부 지수) ...
                    Text(
                      "세부 건강 지수",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        HealthIndexCard(
                          title: "천식/폐질환",
                          score: indices.aliScore,
                          level: indices.aliLevel,
                          levelMax: 4,
                          iconPlaceholder:
                              'assets/images/placeholder_icon_ali.png',
                          statusColor: _getStatusColor(
                            null,
                            isLevel: true,
                            level: indices.aliLevel,
                            maxLevel: 4,
                          ),
                        ),
                        HealthIndexCard(
                          title: "뇌졸중",
                          score: indices.strokeIndexScore,
                          level: indices.strokeIndexLevel,
                          levelMax: 4,
                          iconPlaceholder:
                              'assets/images/placeholder_icon_stroke.png',
                          statusColor: _getStatusColor(
                            null,
                            isLevel: true,
                            level: indices.strokeIndexLevel,
                            maxLevel: 4,
                          ),
                        ),
                        HealthIndexCard(
                          title: "감기",
                          score: indices.coldIndexScore,
                          level: indices.coldIndexLevel,
                          levelMax: 4,
                          iconPlaceholder:
                              'assets/images/placeholder_icon_cold.png',
                          statusColor: _getStatusColor(
                            null,
                            isLevel: true,
                            level: indices.coldIndexLevel,
                            maxLevel: 4,
                          ),
                        ),
                        HealthIndexCard(
                          title: "식중독",
                          score: indices.foodPoisoningIndex,
                          statusText: indices.foodPoisoningRisk,
                          iconPlaceholder:
                              'assets/images/placeholder_icon_food.png',
                          statusColor: _getStatusColor(
                            indices.foodPoisoningRisk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ... 기존 섹션 4 (환경 지도) ...
                    Text(
                      "환경 지도",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const EnvMapSection(),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
