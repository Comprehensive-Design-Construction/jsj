import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 상태 및 Notifier Provider import
import 'main_screen_notifier.dart';
import 'main_screen_state.dart';

// 서비스, 모델, 유틸리티, 위젯 import (경로 확인!)
import '../../../core/constants/app_constants.dart';
// import '../../core/utils/data_mapper.dart'; // DataMapper는 Notifier에서 사용
import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/ui/current_weather.dart';
import '../../../data/models/ui/feels_like_data.dart';
import '../../../data/models/ui/health_index.dart';
import '../../widgets/main_screen/weather_info_card.dart';
import '../../widgets/main_screen/feels_like_card.dart';
import '../../widgets/main_screen/health_index_card.dart';
import '../../widgets/main_screen/health_index_info_dialog.dart';
import '../menu/menu_screen.dart';
import '../add_person/add_person_screen.dart';

// ConsumerWidget으로 변경
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  static const Map<String, String> _envMapTypes = {
    'fine_dust': '미세먼지',
    'uv': '자외선',
    'flood_trace': '침수흔적도',
  };
  // 재난 유형 목록 (API 명세 기반)
  static const Map<String, String> _disasterTypes = {
    'EARTHQUAKE': '지진',
    'COLD_WAVE': '한파',
    'HEAT_WAVE': '폭염',
    'FINE_DUST': '미세먼지',
    'FLOOD': '홍수',
  };

  // BottomNavigationBar 탭 처리 로직 (Notifier로 옮겨도 좋음)
  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    final currentSelectedIndex =
        ref
            .read(mainScreenNotifierProvider)
            .selectedPersonId; // 예시로 현재 선택된 ID 읽기 (Notifier 상태구조에 따라 달라짐)
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    if (index == 3) {
      // 메뉴 탭
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      ).then((_) {
        print("Returned from MenuScreen, reloading visible indices...");
        notifier.reloadVisibleIndices(); // Notifier의 함수 호출
      });
    } else if (index != /* ref.read(mainScreenProvider).selectedIndex */ 0) {
      // TODO: selectedIndex 상태 관리 필요
      print("Tab $index selected (Not implemented yet)");
      // notifier.setSelectedIndex(index); // 예시: Notifier에서 인덱스 관리 시
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 감시 (state 객체에 모든 UI 데이터 포함됨)
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier); // 함수 호출용

    // UI 모델 변수 (state에서 직접 가져옴)
    final CurrentWeather? currentWeatherUI = state.weatherDataUI;
    final FeelsLikeData? feelsLikeDataUI = state.feelsLikeDataUI;
    final List<HealthIndex> healthIndicesUI = state.healthIndicesUI;

    // 현재 선택된 사람 이름
    String currentPersonName = "내 정보";
    if (state.selectedPersonId != MainScreenState().selectedPersonId) {
      currentPersonName =
          state.addedPeopleList
              .firstWhere(
                (p) => p.id == state.selectedPersonId,
                orElse: () => AddedPerson(id: '', name: '알 수 없음'),
              )
              .name;
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildPersonSelectorDropdown(context, ref),
        actions: [
          // 사람 추가 버튼 (AppBar에 배치)
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, size: 24),
            tooltip: '사람 추가',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPersonScreen()),
              ).then((added) {
                if (added == true) {
                  // 사람 추가 성공 시 목록 새로고침 및 UI 갱신
                  notifier.refreshAddedPeople();
                }
              });
            },
          ),
          IconButton(
            // 기존 새로고침 버튼
            icon: const Icon(Icons.refresh),
            onPressed:
                state.isLoading
                    ? null
                    : () => notifier.loadDataForSelectedPerson(refresh: true),
            tooltip: '데이터 새로고침',
          ),
        ],
      ),
      // ------------------------------------
      body: _buildBody(context, ref, state, currentPersonName), // 매핑된 데이터 전달
      bottomNavigationBar: BottomNavigationBar(
        // 테마는 AppTheme에서 적용됨
        currentIndex: 0, // 임시시
        onTap: (index) => _onItemTapped(context, ref, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: '탐색',
          ), // TODO: 실제 기능에 맞는 아이콘/라벨
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: '메뉴'),
        ],
      ),
    );
  }

  // --- AppBar 사용자 선택 드롭다운 빌더 (추가) ---
  Widget _buildPersonSelectorDropdown(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider); // 현재 상태 감시
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    List<DropdownMenuItem<String>> dropdownItems = [];

    // 1. "내 정보" 항목 추가
    dropdownItems.add(
      DropdownMenuItem(
        value: MainScreenState().selectedPersonId, // 고유 ID 사용
        child: Row(
          children: [
            Icon(
              Icons.person_pin_circle_outlined,
              size: 20,
              color: Colors.blueAccent,
            ), // 아이콘 추가
            SizedBox(width: 8),
            Text("내 정보", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    // 2. 추가된 사람 목록 추가
    for (var person in state.addedPeopleList) {
      dropdownItems.add(
        DropdownMenuItem(
          value: person.id, // 사람의 고유 ID 사용
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.grey[700],
              ), // 아이콘 추가
              SizedBox(width: 8),
              Text(person.name), // 사람 이름 표시
            ],
          ),
        ),
      );
    }

    // (선택사항) 구분선 및 추가 버튼 추가
    dropdownItems.add(
      DropdownMenuItem(enabled: false, child: Divider(height: 0)),
    );
    dropdownItems.add(
      DropdownMenuItem(value: 'ADD_PERSON', child: Text('+ 사람 추가...')),
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: state.selectedPersonId,
        isDense: true, // AppBar 높이에 맞게 좀 더 컴팩트하게
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.grey[700],
        ), // 드롭다운 아이콘
        // AppBar 텍스트 스타일과 유사하게 맞춤
        style: Theme.of(
          context,
        ).appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
        dropdownColor: Colors.white,
        items: dropdownItems,
        onChanged:
            state.isLoadingPeople ||
                    state
                        .isLoading // 사람 목록 로딩 중이거나 데이터 로딩 중 변경 불가
                ? null
                : (String? newValue) {
                  if (newValue != null && newValue != state.selectedPersonId) {
                    notifier.setSelectedPersonId(newValue);
                  }
                },
      ),
    );
  }

  // 화면 본문 빌드 함수 (매핑된 데이터 받도록 수정)
  Widget _buildBody(
    BuildContext context, // context 받기
    WidgetRef ref, // ref 받기
    MainScreenState state, // 현재 상태 받기
    String currentPersonName, // 현재 선택된 사람 이름 받기
  ) {
    // UI 모델 변수 (state에서 직접 가져옴)
    final CurrentWeather? currentWeatherUI = state.weatherDataUI;
    final FeelsLikeData? feelsLikeDataUI = state.feelsLikeDataUI;
    final List<HealthIndex> healthIndicesUI = state.healthIndicesUI;

    if (state.isLoading && currentWeatherUI == null) {
      // 초기 로딩 또는 데이터 없을 때
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && currentWeatherUI == null) {
      // 완전 로딩 실패
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('데이터 로드 실패', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => ref
                        .read(mainScreenNotifierProvider.notifier)
                        .loadDataForSelectedPerson(refresh: true),
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 데이터가 있거나 부분 로딩 중
    return RefreshIndicator(
      onRefresh:
          () => ref
              .read(mainScreenNotifierProvider.notifier)
              .loadDataForSelectedPerson(refresh: true),
      child: Stack(
        // 로딩 오버레이를 위해 Stack 사용
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 선택된 사람 표시 ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "$currentPersonName님의 현재 정보",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

                // --- 위치 정보 ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        state.selectedPersonId ==
                                MainScreenState().selectedPersonId
                            ? Icons.my_location
                            : Icons.location_city_outlined,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.selectedPersonId ==
                                MainScreenState().selectedPersonId
                            ? (currentWeatherUI?.location ?? '위치 정보 로딩 중...')
                            : '${state.addedPeopleList.firstWhere((p) => p.id == state.selectedPersonId, orElse: () => AddedPerson(id: '', name: '')).gu ?? ""} ${state.addedPeopleList.firstWhere((p) => p.id == state.selectedPersonId, orElse: () => AddedPerson(id: '', name: '')).dong ?? "지역 정보 없음"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      // 기본 위치 알림
                      if (state.selectedPersonId ==
                              MainScreenState().selectedPersonId &&
                          state.lastLoadedLatitude != null &&
                          state.lastLoadedLongitude != null &&
                          state.lastLoadedLatitude == defaultLatitude &&
                          state.lastLoadedLongitude == defaultLongitude)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(기본위치)',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // --- 날씨 카드 ---
                if (currentWeatherUI != null)
                  WeatherInfoCard(weatherData: currentWeatherUI)
                else
                  _buildDataErrorPlaceholder('날씨 정보를 불러올 수 없습니다.'),
                const SizedBox(height: 24),

                // --- 체감 온도 카드 ---
                _buildSectionTitle(context, '체감온도'), // context 전달
                const SizedBox(height: 10),
                if (feelsLikeDataUI != null)
                  FeelsLikeCard(feelsLikeData: feelsLikeDataUI)
                else
                  _buildDataErrorPlaceholder('체감온도 정보를 불러올 수 없습니다.'),
                const SizedBox(height: 24),

                // --- 건강 지수 ---
                _buildSectionTitle(context, '주요 건강 지수', showInfoIcon: true),
                const SizedBox(height: 10),
                _buildMajorHealthIndices(
                  context,
                  ref,
                  healthIndicesUI,
                ), // context, ref, 데이터 전달
                const SizedBox(height: 24),
                _buildSectionTitle(context, '전체 건강 지수', showInfoIcon: true),
                const SizedBox(height: 10),
                _buildAllHealthIndexList(
                  context,
                  ref,
                  healthIndicesUI,
                ), // context, ref, 데이터 전달
                const SizedBox(height: 24),

                // --- 환경 지도 ---
                _buildSectionTitle(context, '환경 지도'),
                const SizedBox(height: 10),
                _buildMapTypeDropdown(
                  context: context,
                  ref: ref,
                  mapTypes: _envMapTypes, // 상수 사용
                  selectedValueKey: 'selectedEnvMapType',
                  onChangedCallback:
                      (v) => ref
                          .read(mainScreenNotifierProvider.notifier)
                          .setSelectedEnvMapType(v!),
                ),
                const SizedBox(height: 10),
                _buildWebViewMap(
                  controller: state.envMapControllers[state.selectedEnvMapType],
                  placeholderIcon: Icons.public,
                  placeholderText:
                      '${_envMapTypes[state.selectedEnvMapType] ?? "환경"} 지도 로딩 중...',
                ),
                const SizedBox(height: 24),

                // --- 대피소 지도 ---
                _buildSectionTitle(context, '대피소 위치'),
                const SizedBox(height: 10),
                _buildMapTypeDropdown(
                  context: context,
                  ref: ref,
                  mapTypes: _disasterTypes, // 상수 사용
                  selectedValueKey: 'selectedDisasterType',
                  onChangedCallback:
                      (v) => ref
                          .read(mainScreenNotifierProvider.notifier)
                          .setSelectedDisasterType(v!),
                ),
                const SizedBox(height: 10),
                _buildWebViewMap(
                  controller:
                      state.shelterMapControllers[state.selectedDisasterType],
                  placeholderIcon: Icons.pin_drop_outlined,
                  placeholderText:
                      '${_disasterTypes[state.selectedDisasterType] ?? "대피소"} 지도 로딩 중...',
                ),
                const SizedBox(height: 16),

                // 부분 에러 메시지
                if (state.errorMessage != null && state.weatherDataUI != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      '일부 데이터 로딩 실패:\n${state.errorMessage}',
                      style: TextStyle(color: Colors.orange[800], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // 전체 화면 로딩 인디케이터 (API 호출 중일 때)
          if (state.isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // 주요 건강 지수 리스트 위젯 빌더 (상태에서 데이터 읽도록 수정)
  Widget _buildMajorHealthIndices(
    BuildContext context,
    WidgetRef ref,
    List<HealthIndex> allMappedIndices,
  ) {
    final state = ref.watch(mainScreenNotifierProvider); // 보이는 지수 Set 접근 위해 필요
    final visibleNames = state.visibleIndices;
    final List<HealthIndex> visibleIndices =
        allMappedIndices
            .where((index) => visibleNames.contains(index.name))
            .toList();
    final List<HealthIndex> filteredMajorIndices =
        visibleIndices
            .where((indexData) => defaultMajorIndices.contains(indexData.name))
            .toList();

    if (filteredMajorIndices.isEmpty) {
      return _buildDataErrorPlaceholder('표시할 주요 건강 지수가 없거나\n선택된 지수가 없습니다.');
    }

    return ListView.separated(
      /* ... 이전 코드와 동일 ... */
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredMajorIndices.length,
      itemBuilder: (context, index) {
        return HealthIndexCard(
          healthIndex: filteredMajorIndices[index],
          showProgressBar: true,
        ); // 프로그레스 바 표시
      },
      separatorBuilder: (context, index) => SizedBox(height: 12),
    );
  }

  // 전체 건강 지수 리스트 위젯 빌더 (매핑된 데이터 받도록 수정)
  Widget _buildAllHealthIndexList(
    BuildContext context,
    WidgetRef ref,
    List<HealthIndex> allMappedIndices,
  ) {
    final state = ref.watch(mainScreenNotifierProvider); // 보이는 지수 Set 접근 위해 필요
    final visibleNames = state.visibleIndices;
    final List<HealthIndex> filteredHealthIndices =
        allMappedIndices
            .where((index) => visibleNames.contains(index.name))
            .toList();

    if (filteredHealthIndices.isEmpty) {
      return _buildDataErrorPlaceholder('표시할 건강 지수가 선택되지 않았습니다.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredHealthIndices.length,
      itemBuilder: (context, index) {
        return HealthIndexCard(
          healthIndex: filteredHealthIndices[index],
          showProgressBar: false,
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  // 데이터 로드 실패 시 보여줄 플레이스홀더 위젯
  Widget _buildDataErrorPlaceholder(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  // 섹션 제목 위젯 빌더 (변경 없음)
  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool showInfoIcon = false,
  }) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (showInfoIcon) ...[
          SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: Colors.grey[500],
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 18,
            tooltip: '$title 설명 보기',
            onPressed: () {
              if (title == '주요 건강 지수') {
                showDialog(
                  context: context,
                  builder: (_) => const HealthIndexInfoDialog(),
                );
              } else {
                print('$title 정보 아이콘 탭됨');
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMapTypeDropdown({
    required BuildContext context, // context 추가
    required WidgetRef ref, // ref 추가
    required Map<String, String> mapTypes,
    required String
    selectedValueKey, // 상태 키 ('selectedEnvMapType' or 'selectedDisasterType')
    required Function(String?) onChangedCallback, // Notifier 함수 호출용 콜백
  }) {
    final String selectedValue =
        selectedValueKey == 'selectedEnvMapType'
            ? ref.watch(mainScreenNotifierProvider).selectedEnvMapType
            : ref.watch(mainScreenNotifierProvider).selectedDisasterType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        // 기본 밑줄 제거
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true, // 너비 최대로 확장
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: Colors.grey.shade700,
          ),
          elevation: 2, // 드롭다운 메뉴 그림자
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ), // 드롭다운 스타일
          dropdownColor: Colors.white, // 드롭다운 메뉴 배경색
          items:
              mapTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key, // API 값
                  child: Text(entry.value), // 사용자에게 보여줄 한글 이름
                );
              }).toList(),
          onChanged:
              ref.watch(mainScreenNotifierProvider).isLoading
                  ? null
                  : onChangedCallback, // 선택 시 호출될 콜백
        ),
      ),
    );
  }

  // WebView 지도 표시 위젯 빌더
  Widget _buildWebViewMap({
    required WebViewController? controller,
    required IconData placeholderIcon,
    required String placeholderText,
    double height = 250, // 기본 지도 높이
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 가로 세로 비율 유지
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // 로딩 중 배경색
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          // 내부 컨텐츠 모서리도 둥글게
          borderRadius: BorderRadius.circular(12),
          child:
              controller != null
                  ? WebViewWidget(controller: controller) // 컨트롤러 있으면 웹뷰 표시
                  : Center(
                    // 컨트롤러 없으면 플레이스홀더 표시
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          placeholderText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
