// lib/presentation/screens/index_detail/index_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'index_detail_notifier.dart';
import '../../../data/models/ui/health_index.dart';
import '../../../data/models/ui/feels_like_data.dart';
// 상태 바 위젯 등 필요한 위젯 import
import '../../widgets/index_detail/index_status_bar.dart'; // 예시 경로 (추후 생성 필요)
import '../../../core/constants/app_constants.dart'; // myInfoId 등 상수 사용

// MainScreenNotifier Provider import (현재 사용자 ID 가져오기 위함)
import '../main/main_screen_notifier.dart';

class IndexDetailPage extends ConsumerWidget {
  final dynamic indexData; // HealthIndex 또는 FeelsLikeData

  const IndexDetailPage({super.key, required this.indexData});

  // --- 지수별 설명 텍스트 (임시 Placeholder) ---
  // TODO: 이 내용을 별도 파일 또는 Map으로 관리
  String _getIndexDescription(String indexName) {
    switch (indexName) {
      case '체감온도':
        return '현재 날씨와 습도 등을 고려하여 사람이 실제로 느끼는 온도입니다. 건강 관리에 유의하세요.';
      case '미세먼지 지수':
        return '대기 중 미세먼지 농도를 나타내는 지수입니다. 호흡기 건강에 영향을 줄 수 있습니다.';
      case '심뇌혈관질환 지수':
        return '기온 등 기상조건에 따른 심뇌혈관질환 발생 가능성을 지수화한 것입니다. 위험군은 추운날씨 건강관리가 필요합니다.';
      case '천식질환 지수':
        return '대기오염 및 기상 조건 변화에 따른 천식 발작 가능성을 나타냅니다.';
      case '감기가능 지수':
        return '기온, 습도 등을 고려한 감기 발병 가능성을 나타냅니다.';
      case '식중독 지수':
        return '온도, 습도 등을 기반으로 식중독 발생 가능성을 예측합니다. 음식물 관리에 주의하세요.';
      case '자외선 지수':
        return '태양으로부터 오는 자외선의 강도를 나타냅니다. 피부 건강과 관련이 깊습니다.';
      // ... 다른 지수 설명 추가 ...
      default:
        return '$indexName 에 대한 상세 설명입니다. (내용 업데이트 예정)';
    }
  }

  // --- 지수별 최소/최대값 (상태 바 계산용) ---
  // TODO: 이 값을 상수 또는 설정에서 관리
  (double, double) _getIndexRange(String indexName) {
    switch (indexName) {
      case '체감온도':
        return (0.0, 45.0); // FeelsLikeCard의 범위 참고
      case '미세먼지 지수':
        return (0.0, 150.0); // HealthIndexCard의 예시 참고
      case '심뇌혈관질환 지수':
        return (0.0, 4.0); // HealthIndexCard의 예시 참고 (레벨 기준?)
      case '자외선 지수':
        return (0.0, 15.0); // HealthIndexCard의 예시 참고
      // ... 다른 지수 범위 추가 ...
      default:
        return (0.0, 100.0); // 기본 범위
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 필요한 상태만 watch 하도록 분리 ---
    // 현재 선택된 사용자 ID (Notifier 파라미터용)
    final selectedPersonId = ref.watch(
      mainScreenNotifierProvider.select((state) => state.selectedPersonId),
    );
    // 상세 정보 상태 (.family Provider 호출)
    final providerParams = (
      indexData: indexData,
      selectedPersonId: selectedPersonId,
    );
    final detailState = ref.watch(indexDetailNotifierProvider(providerParams));
    // -------------------------------------

    // indexData 타입에 따라 정보 추출 (기존과 동일)
    String title = '';
    IconData icon = Icons.help_outline;
    Color iconBgColor = Colors.grey;
    Color statusColor = Colors.grey;
    double currentValue = 0.0;
    String status = '';
    double minValue = 0.0;
    double maxValue = 100.0;

    if (indexData is HealthIndex) {
      title = indexData.name;
      icon = indexData.icon;
      iconBgColor = indexData.iconColor;
      currentValue = indexData.value;
      status = indexData.status;
      statusColor = indexData.statusColor;
      (minValue, maxValue) = _getIndexRange(title);
    } else if (indexData is FeelsLikeData) {
      title = '체감온도';
      icon = Icons.thermostat;
      iconBgColor = indexData.statusColor; // 체감온도는 상태색을 아이콘 배경으로 사용
      currentValue = indexData.temperature;
      status = indexData.status;
      statusColor = indexData.statusColor;
      (minValue, maxValue) = _getIndexRange(title);
    }
    // ... 다른 지수 타입 처리 ...

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 카드 (score2.dart 유사하게) ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          // 아이콘 배경
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: iconBgColor, // 추출한 아이콘 배경색
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 28,
                          ), // 추출한 아이콘
                        ),
                        const SizedBox(width: 12),
                        Column(
                          // 지수 이름, 현재 값
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title, // 추출한 제목
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentValue.toStringAsFixed(
                                1,
                              ), // 추출한 값 (소수점 1자리)
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Spacer(), // 화살표 제거
                      ],
                    ),
                    const SizedBox(height: 20),
                    // --- 일반화된 상태 바 위젯 ---
                    IndexStatusBar(
                      // <<< 새로 만들거나 score2.dart의 StrokeRiskBar 수정/일반화
                      currentValue: currentValue,
                      minValue: minValue,
                      maxValue: maxValue,
                      statusText: status, // 현재 상태 텍스트
                      statusColor: statusColor, // 상태에 맞는 색상
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 지수 설명 카드 ---
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title란?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getIndexDescription(title), // <<< 지수별 설명 함수 호출
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 행동 요령 카드 ---
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '행동 요령',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (detailState.isLoading)
                      const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) // 로딩 인디케이터
                    else if (detailState.errorMessage != null)
                      // 오류 메시지 표시
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              detailState.errorMessage!,
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      )
                    else
                      // API에서 받아온 행동 요령 텍스트 표시
                      // 개행 문자(\n)와 글머리 기호(▪️ 등)를 적절히 처리하여 보여주는 것이 좋음
                      // 예: Text(detailState.recommendation.replaceAll('▪️', '\n▪️ '), ...)
                      Text(
                        detailState.recommendation,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
