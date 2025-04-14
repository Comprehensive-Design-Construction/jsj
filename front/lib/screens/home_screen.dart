import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../widgets/weather_summary_section.dart';
import '../widgets/index_section.dart';
import '../widgets/shelter_map_section.dart';
import '../constants/app_constants.dart'; // primaryColor 등 사용 위해

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯 트리가 빌드된 후 Provider에 접근하여 데이터 로드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppDataProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provider를 사용하여 데이터 상태 감시
    return Consumer<AppDataProvider>(
      builder: (context, appData, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '실시간 안전 정보',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white, // AppBar 배경색
            foregroundColor: Colors.black87, // AppBar 글자 및 아이콘 색상
            elevation: 1.0, // AppBar 그림자
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: primaryColor),
                onPressed:
                    appData.isLoadingInitialData ||
                            appData.isLoadingMaps.values.any(
                              (loading) => loading,
                            )
                        ? null // 로딩 중일 때 비활성화
                        : () => appData.refreshData(), // 새로고침 함수 호출
                tooltip: '새로고침',
              ),
            ],
          ),
          body: _buildBody(context, appData),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppDataProvider appData) {
    // 초기 데이터(날씨/지수) 로딩 중일 때
    if (appData.isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }

    // 초기 데이터 로딩 실패 시
    if (appData.errorMessage != null && appData.weatherData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 16),
              Text(
                "데이터를 불러오는데 실패했습니다.\n${appData.errorMessage}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("다시 시도"),
                onPressed: () => appData.refreshData(),
              ),
            ],
          ),
        ),
      );
    }

    // 데이터 로딩 완료 후 화면 구성
    return RefreshIndicator(
      onRefresh: () => appData.refreshData(), // 당겨서 새로고침
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // 1. 날씨 요약 섹션
          WeatherSummarySection(
            weatherData: appData.weatherData,
            position: appData.currentPosition,
          ),
          const SizedBox(height: 24),

          // 2. 위험 지수 섹션
          IndexSection(indexData: appData.indexData),
          const SizedBox(height: 24),

          // 3. 대피소 지도 섹션
          ShelterMapSection(), // Provider 통해 데이터 접근하므로 파라미터 필요 없음
          // 4. 알림 섹션 (필요시 추가)
          // if (appData.alerts != null && appData.alerts!.isNotEmpty) ...[]
        ],
      ),
    );
  }
}
