import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 상태 및 Notifier Provider import
import 'main_screen_notifier.dart';
import 'main_screen_state.dart';

// 서비스, 모델, 유틸리티, 위젯 import
import '../../../core/constants/app_constants.dart';
import '../../../data/models/added_person.dart';
// UI 모델 import는 섹션 위젯에서 처리

// 섹션 위젯 import
import 'widgets/location_info_widget.dart';
import 'widgets/weather_section_widget.dart';
import 'widgets/feels_like_section_widget.dart';
import 'widgets/major_health_indices_widget.dart';
import 'widgets/all_health_indices_widget.dart';
import 'widgets/env_map_section_widget.dart';
import 'widgets/shelter_map_section_widget.dart';
import 'widgets/partial_error_widget.dart';
// 기존 위젯 import
import '../../widgets/main_screen/health_index_info_dialog.dart';
import '../../widgets/main_screen/person_selection_dialog.dart';
import '../menu/menu_screen.dart';
import '../add_person/add_person_screen.dart';

// --- ConsumerStatefulWidget으로 변경 ---
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  // 지도 타입 상수 정의 (기존 코드 유지)
  static const Map<String, String> _envMapTypes = {
    'fine_dust': '미세먼지',
    'uv': '자외선',
    'flood_trace': '침수흔적도',
  };
  static const Map<String, String> _disasterTypes = {
    'EARTHQUAKE': '지진',
    'COLD_WAVE': '한파',
    'HEAT_WAVE': '폭염',
    'FINE_DUST': '미세먼지',
    'FLOOD': '홍수',
  };

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

// --- ConsumerState 클래스 정의 ---
class _MainScreenState extends ConsumerState<MainScreen> {
  // 하단 네비게이션 바 선택 인덱스 상태
  int _selectedIndex = 0;

  // 스크롤 컨트롤러 및 섹션 이동을 위한 GlobalKey 정의
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _majorHealthSectionKey = GlobalKey(); // 주요 건강 지수 섹션 키
  final GlobalKey _environmentMapSectionKey = GlobalKey(); // 환경 지도 섹션 키
  final GlobalKey _shelterSectionKey = GlobalKey(); // 대피소 위치 섹션 키

  @override
  void dispose() {
    _scrollController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  // --- 하단 네비게이션 탭 처리 로직 (스크롤 기능 추가) ---
  void _onItemTapped(int index) {
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    // 특정 섹션으로 스크롤하는 로직
    GlobalKey? targetKey;
    if (index == 0 && _selectedIndex != 0) {
      // 홈 (맨 위로)
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else if (index == 1) {
      // 건강지수
      targetKey = _majorHealthSectionKey;
    } else if (index == 2) {
      // 환경 지도
      targetKey = _environmentMapSectionKey;
    } else if (index == 3) {
      // 대피소 위치
      targetKey = _shelterSectionKey;
    } else if (index == 4) {
      // 메뉴 (기존 index 3 -> 4로 변경됨)
      // 스크롤 없이 메뉴 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      ).then((_) {
        print("Returned from MenuScreen, reloading visible indices...");
        // MenuScreen에서 변경된 사항(보이는 지수)을 MainScreenNotifier가 다시 로드하도록 함
        notifier.reloadVisibleIndices();
      });
      // 메뉴 탭 시에는 _selectedIndex 업데이트하지 않고 바로 리턴 (선택사항)
      // 또는 메뉴 화면 이동 후 돌아왔을 때 이전 탭이 선택된 상태로 두려면 업데이트 X
      return; // 아래 setState 실행 방지
    }

    // 대상 키가 있으면 해당 위치로 스크롤
    if (targetKey != null) {
      final targetContext = targetKey.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.0, // 섹션 상단을 화면 상단에 맞춤
        );
      }
    }

    // 탭 인덱스 상태 업데이트 (메뉴 탭 제외)
    if (index != 4) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    // 현재 선택된 사람 이름 계산 (기존 코드 유지)
    String currentPersonName = "내 정보";
    if (state.selectedPersonId != myInfoId) {
      // myInfoId 직접 사용
      final person = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '알 수 없음'),
      );
      currentPersonName = person.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // 사용자 선택 드롭다운운
            Expanded(child: _buildPersonSelectorDropdown(context, ref)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: Image.asset(
                  'assets/images/welogo.png',
                  height: 28,
                  errorBuilder:
                      (context, error, StackTrace) => SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     // 새로고침 버튼
        //     icon: const Icon(Icons.refresh),
        //     onPressed:
        //         state.isLoading
        //             ? null
        //             : () => notifier.loadDataForSelectedPerson(refresh: true),
        //     tooltip: '데이터 새로고침',
        //   ),
        // ],
      ),
      // --- Body (스크롤 컨트롤러 연결 및 키 할당 필요) ---
      body: _buildBody(context, ref), // Build 함수 호출
      // --- 하단 네비게이션 바 (새 디자인 및 기능 적용) ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 5개 항목이므로 fixed 타입 사용
        currentIndex: _selectedIndex, // 상태 변수 사용
        onTap: _onItemTapped, // 수정된 탭 핸들러 사용
        selectedItemColor: Colors.blue.shade700, // 새 UI 색상
        unselectedItemColor: Colors.grey.shade600, // 새 UI 색상
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true, // 라벨 표시 (새 UI 기준)
        showUnselectedLabels: true, // 라벨 표시 (새 UI 기준)
        items: const [
          // 홈
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // 선택 시 채워진 아이콘
            label: '홈',
          ),
          // 건강지수
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined), // 새 아이콘
            activeIcon: Icon(Icons.show_chart),
            label: '건강지수',
          ),
          // 환경 지도
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: '환경 지도',
          ),
          // 대피소 위치
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined), // 새 아이콘
            activeIcon: Icon(Icons.warehouse),
            label: '대피소 위치',
          ),
          // 메뉴
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            activeIcon: Icon(Icons.menu_open_rounded), // 선택 시 다른 아이콘 (선택사항)
            label: '메뉴',
          ),
        ],
      ),
    );
  }

  // --- AppBar 사용자 선택 드롭다운 빌더 (기존 코드 유지) ---
  Widget _buildPersonSelectorDropdown(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    String currentPersonName = "내 정보";
    IconData currentPersonIcon = Icons.person_pin_circle_outlined;
    Color currentPersonIconColor = Colors.blueAccent;

    if (state.selectedPersonId != myInfoId) {
      final person = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '???'),
      );
      currentPersonName = person.name;
      currentPersonIcon = Icons.person_outline;
      currentPersonIconColor = Colors.deepPurpleAccent;
    }

    return InkWell(
      onTap:
          state.isLoadingPeople || state.isLoading
              ? null
              : () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return PersonSelectionDialog(
                      currentSelectedPersonId: state.selectedPersonId,
                      addedPeople: state.addedPeopleList,
                    );
                  },
                );
                if (result != null) {
                  if (result == 'ADD_NEW') {
                    if (context.mounted) {
                      final added = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPersonScreen(),
                        ),
                      );
                      if (added == true) {
                        await notifier.refreshAddedPeople();
                      }
                    }
                  } else {
                    notifier.setSelectedPersonId(result);
                  }
                }
              },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentPersonIcon, size: 22, color: currentPersonIconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                currentPersonName,
                style: Theme.of(context).appBarTheme.titleTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[700],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // --- 화면 본문 빌드 함수 (분리된 위젯 사용) ---
  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);

    // 초기 로딩 또는 완전 로딩 실패 처리 (기존 코드 유지)
    if (state.isLoading && state.weatherDataUI == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.weatherDataUI == null) {
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

    // 데이터가 있거나 부분 로딩 중일 때
    return RefreshIndicator(
      onRefresh:
          () => ref
              .read(mainScreenNotifierProvider.notifier)
              .loadDataForSelectedPerson(refresh: true),
      child: Stack(
        children: [
          // --- SingleChildScrollView에 컨트롤러 연결 ---
          SingleChildScrollView(
            controller: _scrollController, // 컨트롤러 연결
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // 선택된 사람 이름 표시 (기존과 동일)
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "${_getCurrentPersonName(ref)}님의 현재 정보",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const LocationInfoWidget(), // 위치 정보 위젯
                const WeatherSectionWidget(), // 날씨 섹션 위젯
                FeelsLikeSectionWidget(
                  // 체감 온도 섹션 위젯 (헬퍼 함수 전달)
                  buildSectionTitle: _buildSectionTitle,
                  buildDataErrorPlaceholder: _buildDataErrorPlaceholder,
                ),
                // --- 주요 건강 지수 섹션 (GlobalKey 할당) ---
                Container(
                  // 스크롤 대상으로 삼기 위해 Container 또는 다른 위젯으로 감싸고 Key 할당
                  key: _majorHealthSectionKey,
                  child: MajorHealthIndicesWidget(
                    buildSectionTitle: _buildSectionTitle,
                    buildDataErrorPlaceholder: _buildDataErrorPlaceholder,
                  ),
                ),
                AllHealthIndicesWidget(
                  // 전체 건강 지수 섹션 위젯
                  buildSectionTitle: _buildSectionTitle,
                  buildDataErrorPlaceholder: _buildDataErrorPlaceholder,
                ),
                // --- 환경 지도 섹션 (GlobalKey 할당) ---
                Container(
                  key: _environmentMapSectionKey,
                  child: EnvMapSectionWidget(
                    envMapTypes: MainScreen._envMapTypes, // static 상수 접근
                    buildSectionTitle: _buildSectionTitle,
                    buildMapTypeDropdown: _buildMapTypeDropdown,
                    buildWebViewMap: _buildWebViewMap,
                  ),
                ),
                // --- 대피소 위치 섹션 (GlobalKey 할당) ---
                Container(
                  key: _shelterSectionKey,
                  child: ShelterMapSectionWidget(
                    disasterTypes: MainScreen._disasterTypes, // static 상수 접근
                    buildSectionTitle: _buildSectionTitle,
                    buildMapTypeDropdown: _buildMapTypeDropdown,
                    buildWebViewMap: _buildWebViewMap,
                  ),
                ),
                const PartialErrorWidget(), // 부분 에러 메시지 위젯
              ],
            ),
          ),
          // 전체 화면 로딩 인디케이터 (기존 코드 유지)
          if (state.isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- Helper 함수들 (StatefulWidget -> StatelessWidget/ConsumerWidget으로 변경되면서 static 또는 별도 파일로 분리 권장) ---
  // 여기서는 일단 non-static 멤버 함수로 유지 (호출 시 context 필요)

  // 현재 선택된 사람 이름 가져오기 (build 함수 밖에서도 사용 가능하도록 분리)
  String _getCurrentPersonName(WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    if (state.selectedPersonId == myInfoId) {
      return "내 정보";
    } else {
      final person = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '알 수 없음'),
      );
      return person.name;
    }
  }

  // 데이터 로드 실패 시 보여줄 플레이스홀더 위젯
  Widget _buildDataErrorPlaceholder(String message) {
    // 이제 각 위젯에서 직접 구현하거나, 이 함수를 static 또는 유틸리티로 분리 필요
    // 여기서는 각 위젯으로 로직이 일부 이동되었음 (중복될 수 있음)
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
        textAlign: TextAlign.center, // 가운데 정렬 추가
      ),
    );
  }

  // 섹션 제목 위젯 빌더
  Widget _buildSectionTitle(
    BuildContext context, // BuildContext 추가
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
              // HealthIndexInfoDialog 표시 로직은 context가 필요하므로 여기서 처리
              if (title.contains('건강 지수')) {
                // '주요', '전체' 모두 포함하도록
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

  // 지도 타입 선택 드롭다운 위젯 빌더
  Widget _buildMapTypeDropdown({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, String> mapTypes,
    required String selectedValueKey,
    required Function(String?) onChangedCallback,
  }) {
    // selectedValue 가져오는 로직은 각 호출 위젯(EnvMapSectionWidget 등)에서 ref.watch로 처리하는 것이 더 좋음
    // 여기서는 일단 파라미터로 가정하지 않고, 키를 통해 상태 직접 접근
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
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: Colors.grey.shade700,
          ),
          elevation: 2,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
          dropdownColor: Colors.white,
          items:
              mapTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
          onChanged:
              ref.watch(mainScreenNotifierProvider).isLoading
                  ? null
                  : onChangedCallback,
        ),
      ),
    );
  }

  // WebView 지도 표시 위젯 빌더
  Widget _buildWebViewMap({
    required WebViewController? controller, // 타입 명시
    required IconData placeholderIcon,
    required String placeholderText,
    double height = 250,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              controller != null
                  ? WebViewWidget(controller: controller)
                  : Center(
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
