// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit_or_bloc_or_provider/dashboard_cubit.dart';
import '../cubit_or_bloc_or_provider/dashboard_state.dart';
import '../widgets/weather_display.dart'; // 날씨 표시 위젯 (구현 필요)
import '../widgets/health_index_card.dart'; // 건강 지수 카드 위젯 (구현 필요)
import '../widgets/map_display_section.dart'; // 지도 섹션 위젯 (구현 필요)
import '../../../../models/health_indices.dart';
// import '../../../widgets/loading_indicator.dart'; // 공통 로딩 위젯
// import '../../../widgets/error_message.dart'; // 공통 에러 메시지 위젯

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit()..loadDashboardData(),
      child: Scaffold(
        appBar: AppBar(/* ... AppBar 구현 ... */),
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardLoadFailure) {
              // TODO: 에러 처리 UI 개선 (재시도 버튼 등)
              return Center(child: Text('오류: ${state.errorMessage}'));
            }
            if (state is DashboardLoadSuccess) {
              // --- 데이터 로드 성공 시 UI ---
              return RefreshIndicator(
                // 당겨서 새로고침 기능 추가
                onRefresh: () async {
                  context.read<DashboardCubit>().loadDashboardData();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. 상단 날씨 영역 (구현된 위젯 사용)
                    WeatherDisplay(weatherData: state.weatherData),
                    const SizedBox(height: 24), // 간격 조정
                    // 2. 중단 건강 지수 영역
                    Text(
                      '주요 건강 지수',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (state.healthIndices?.indices != null)
                      // Cubit에서 계산된 최고 위험 지수 정보 활용 (state에 추가했다고 가정)
                      // 예: final highestRiskName = state.highestRiskIndexName;
                      ..._buildHealthIndexCards(
                        state.healthIndices!.indices /*, highestRiskName*/,
                      )
                    else
                      const Text('건강 지수 정보를 표시할 수 없습니다.'), // 데이터 없을 때 메시지
                    const SizedBox(height: 24), // 간격 조정
                    // 3. 하단 지도 영역 (구현된 위젯 사용)
                    Text(
                      '지도 정보',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    MapDisplaySection(), // 지도 섹션 위젯
                  ],
                ),
              );
            }
            // 기본 상태
            return const Center(child: Text('데이터를 불러오는 중...'));
          },
        ),
        // TODO: 하단 네비게이션 바 구현
      ),
    );
  }
}

// 건강 지수 데이터를 기반으로 카드 위젯 리스트 생성 (예시)
List<Widget> _buildHealthIndexCards(
  IndexCalculationResult indices /*, String? highestRiskName */,
) {
  // TODO: "가장 위험한 지수" 로직 적용 (정렬 또는 isHighestRisk 플래그 전달)
  // TODO: "현재 값" 표시 방식 정의 (score? level? 특정 값?)
  // TODO: "사진" 매핑을 위한 pictureKey 결정

  final List<Widget> cards = [];

  // 체감 온도 카드
  cards.add(
    HealthIndexCard(
      title: "체감 온도",
      displayValue: indices.apparentTemperature?.toStringAsFixed(1) ?? 'N/A',
      // level: ???, // 위험도 레벨(int) 필요 시 추가
      riskLevelString: indices.apparentTempRiskStatus ?? '정보 없음',
      pictureKey: 'apparent_temp',
      // isHighestRisk: highestRiskName == 'ApparentTemp', // 최고 위험 지수 여부
    ),
  );

  // ALI 카드
  cards.add(
    HealthIndexCard(
      title: "천식/폐질환 지수",
      displayValue: indices.aliScore?.toStringAsFixed(2) ?? 'N/A', // 점수 표시?
      riskLevel: indices.aliLevel,
      riskLevelString: _mapLevelToString(
        indices.aliLevel,
      ), // 레벨 -> 문자열 변환 함수 필요
      pictureKey: 'ali',
      // isHighestRisk: highestRiskName == 'ALI',
    ),
  );

  // 뇌졸증(TI) 카드
  cards.add(
    HealthIndexCard(
      title: "뇌졸증 지수",
      displayValue: indices.strokeIndexScore?.toStringAsFixed(2) ?? 'N/A',
      riskLevel: indices.strokeIndexLevel,
      riskLevelString: _mapLevelToString(indices.strokeIndexLevel),
      pictureKey: 'stroke',
      // isHighestRisk: highestRiskName == 'Stroke',
    ),
  );

  // 감기(CI) 카드
  cards.add(
    HealthIndexCard(
      title: "감기 가능 지수",
      displayValue: indices.coldIndexScore?.toStringAsFixed(2) ?? 'N/A',
      riskLevel: indices.coldIndexLevel,
      riskLevelString: _mapLevelToString(indices.coldIndexLevel),
      pictureKey: 'cold',
      // isHighestRisk: highestRiskName == 'Cold',
    ),
  );

  // 식중독 카드
  cards.add(
    HealthIndexCard(
      title: "식중독 지수",
      displayValue: indices.foodPoisoningIndex ?? 'N/A', // 지수 값 표시
      // level: ???, // 식중독 위험도 level(int) 필요 시 추가
      riskLevelString: indices.foodPoisoningRisk ?? '정보 없음',
      pictureKey: 'poison',
      // isHighestRisk: highestRiskName == 'FoodPoisoning',
    ),
  );

  // TODO: 미세먼지, UV 지수 카드 추가 (ApiService 및 Cubit에서 데이터 가져오도록 수정 후)

  return cards; // 생성된 카드 리스트 반환
}

// 숫자 레벨을 문자열로 변환하는 헬퍼 함수 (예시)
String _mapLevelToString(int? level) {
  switch (level) {
    case 1:
      return "매우 높음"; // 또는 "위험" 등 통일된 표현 사용
    case 2:
      return "높음";
    case 3:
      return "보통";
    case 4:
      return "낮음";
    default:
      return "정보 없음";
  }
}
