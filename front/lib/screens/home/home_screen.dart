// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/health_index_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/env_map_provider.dart'; // 새로고침용
import '../../providers/shelter_map_provider.dart'; // 새로고침용
import '../../providers/map_cache_provider.dart'; // 새로고침 시 캐시 무효화용
import '../../screens/loading_error/loading_indicator.dart';
import '../../screens/loading_error/error_message.dart';
import 'widgets/health_index_card.dart';
import 'widgets/env_map_section.dart';
import 'widgets/weather_display.dart'; // 실제 WeatherDisplay 위젯으로 변경
import '../profile/profile_screen.dart';
import '../shelter_map/shelter_map_screen.dart';
import '../../models/response/health_indices_response.dart';
import '../../models/common/alert_info.dart'; // AlertInfo 모델 import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // 상태/레벨에 따른 색상 반환 (HealthIndexCard와 로직 통일)
  Color _getStatusColor(
    String? status, {
    bool isLevel = false,
    int? level,
    int maxLevel = 4,
  }) {
    if (isLevel && level != null) {
      if (level <= maxLevel * 0.25) return Colors.red.shade700;
      if (level <= maxLevel * 0.5) return Colors.orange.shade700;
      if (level <= maxLevel * 0.75) return Colors.yellow.shade800;
      return Colors.green.shade600;
    } else {
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
          return Colors.grey;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentPositionProvider);
    final healthIndexAsync = ref.watch(healthIndexDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 건강 날씨'),
        actions: [
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
          ref.invalidate(currentPositionProvider);
          ref.invalidate(healthIndexDataProvider);
          // 지도 캐시도 비워서 새로고침 시 강제로 API 호출하도록 함
          ref.invalidate(mapCacheProvider);
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
            return healthIndexAsync.when(
              loading: () => const LoadingIndicator(),
              error:
                  (err, stack) => ErrorMessage(
                    message: '건강 지수 정보를 로드하는데 실패했습니다.\n$err',
                    onRetry: () => ref.invalidate(healthIndexDataProvider),
                  ),
              data: (healthData) {
                final indices = healthData.indices;
                final region = healthData.region;
                final weather = healthData.weather; // WeatherData 사용
                final alerts = healthData.alerts; // Alerts 사용

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 섹션 1: 지역 정보 & 실제 날씨 정보 표시
                    Text(
                      '${region.gu} ${region.region}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    // WeatherDisplay 위젯에 실제 WeatherData 전달
                    if (weather != null)
                      WeatherDisplay(weatherData: weather)
                    else
                      const WeatherDisplayPlaceholder(
                        condition: "unknown",
                      ), // 데이터 없을 경우 Placeholder
                    const SizedBox(height: 20),

                    // 섹션 1.5: 알림 정보 표시 (있을 경우)
                    if (alerts.isNotEmpty) ...[
                      // ...[]: 리스트 펼침 연산자
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

                    // 섹션 2: 주요 지수 카드 (체감 온도)
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

                    // 섹션 3: 세부 건강 지수 그리드 (이전과 동일, statusColor 전달 확인)
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

                    // 섹션 4: 환경 지도 (이전과 동일)
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
