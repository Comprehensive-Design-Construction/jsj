import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 상태 및 Notifier Provider import
import 'main_screen_notifier.dart';
import 'main_screen_state.dart';

// 서비스, 모델, 유틸리티, 위젯 import
import '../../../core/constants/app_constants.dart';
import '../../../data/models/added_person.dart';

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
// EditProfileScreen import 추가
import '../profile/edit_profile_screen.dart';

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
  void _onItemTapped(int index) async {
    // async 추가 (Navigator.push 결과 기다리기 위함)
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
      // 스크롤 없이 메뉴 화면으로 이동 + 결과 처리 로직 추가
      final result = await Navigator.push<bool?>(
        // 결과 타입 명시 (bool?)
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );

      print("Returned from MenuScreen with result: $result");
      // MenuScreen에서 변경된 사항(보이는 지수)을 MainScreenNotifier가 다시 로드하도록 함
      await notifier.reloadVisibleIndices(); // await 추가

      // EditProfileScreen에서 변경사항이 있었을 경우 (true 반환 시) 데이터 새로고침
      // MenuScreen을 통해 EditProfileScreen으로 갔다가 돌아온 경우를 처리하기 위함
      // MenuScreen 자체에서 pop 할 때 결과를 전달하거나, 다른 방식 사용 필요
      // 여기서는 MenuScreen에서 pop할 때 결과 전달이 안되므로, 다른 방법 고려
      // 예: MenuScreen에서 visibleIndices 변경 시 mainNotifierProvider를 직접 refresh? (주의)
      // **일단 MenuScreen에서 돌아오면 무조건 새로고침하는 방식으로 수정 (가장 간단)**
      // 또는 MenuScreen에서 pop 시 결과를 전달하도록 수정 필요
      print("Reloading data after returning from MenuScreen...");
      await notifier.loadDataForSelectedPerson(refresh: true); // await 추가

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
        // 배경색과 그림자 제거 (이미지와 유사하게)
        backgroundColor: Colors.grey[50], // 또는 Colors.grey[50] 등 원하는 밝은 색
        elevation: 0, // 그림자 제거
        title: Row(
          children: [
            // Expanded로 감싸서 왼쪽 정렬 효과 및 공간 확보
            Expanded(
              child: _buildPersonSelectorDropdown(context, ref), // 수정된 함수 호출
            ),
            // 오른쪽 앱 로고
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: Image.asset(
                  'assets/images/welogo.png', // 로고 경로 확인!
                  height: 24, // 이미지에 맞게 높이 조정
                  errorBuilder:
                      (context, error, stackTrace) => SizedBox.shrink(),
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

  // --- AppBar 사용자 선택 드롭다운 빌더 ---
  Widget _buildPersonSelectorDropdown(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    String currentPersonName = "내 정보";
    IconData currentPersonIconData = Icons.person_rounded;
    Color currentPersonIconBgColor = Colors.deepPurple.shade300;

    if (state.selectedPersonId != myInfoId) {
      final person = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '???'),
      );
      currentPersonName = person.name;
      currentPersonIconData = Icons.person_outline;
      currentPersonIconBgColor = Colors.deepPurpleAccent;
    }
    // 현재 선택된 사람 데이터 찾기 (Dialog에 전달하기 위함)
    final AddedPerson? currentPersonData =
        (state.selectedPersonId != myInfoId)
            ? state.addedPeopleList.firstWhere(
              (p) => p.id == state.selectedPersonId,
              orElse: () => AddedPerson(id: '', name: '알 수 없음'),
            )
            : null;
    // AppBar의 위치와 높이를 알기 위한 GlobalKey
    // (AppBar 자체에 key를 할당하거나, AppBar를 감싸는 위젯에 할당 필요)
    // 여기서는 AppBar 높이를 대략적으로 가정하여 위치 계산 (정확하지 않을 수 있음)
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap:
          state.isLoadingPeople || state.isLoading
              ? null
              : () async {
                print("AppBar title tapped. Opening Person Selection Dialog.");

                // --- showGeneralDialog 호출 (독립적인 창 효과) ---
                final result = await showGeneralDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel:
                      MaterialLocalizations.of(
                        context,
                      ).modalBarrierDismissLabel,
                  barrierColor: Colors.black.withOpacity(0.3), // 배경 어둡게 처리 개선
                  transitionDuration: const Duration(milliseconds: 200),

                  pageBuilder: (buildContext, animation, secondaryAnimation) {
                    return Material(
                      type: MaterialType.transparency,
                      child: Column(
                        // Column을 사용하여 상단에만 배치
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch, // 좌우 꽉 채우도록
                        children: [
                          // 다이얼로그 내용물 (AppBar 아래 + 여백 위치)
                          // Container 등으로 감싸서 좌우 마진을 줄 수도 있음
                          Padding(
                            padding: EdgeInsets.only(
                              top:
                                  appBarHeight +
                                  statusBarHeight +
                                  4.0, // AppBar 아래 + 약간의 간격
                              // left: 16.0, // 필요시 좌우 패딩 추가
                              // right: 16.0,
                            ),
                            child: PersonSelectionDialogContent(
                              currentSelectedPersonId: state.selectedPersonId,
                              addedPeople: state.addedPeopleList,
                            ),
                          ),
                          // 나머지 영역은 터치 시 닫히도록 Expanded + GestureDetector (선택 사항)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(buildContext).pop(),
                              behavior: HitTestBehavior.opaque, // 빈 영역 터치 감지
                            ),
                          ),
                        ],
                      ),
                    );
                  },

                  transitionBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    // 위에서 아래로 내려오는 애니메이션
                    return FadeTransition(
                      // Fade 효과 추가
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.02), // 시작 위치 조금 더 위로
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                );
                // ---------------------------

                print("Dialog closed with result: $result");

                // --- 다이얼로그 결과 처리 로직 ---
                if (result != null) {
                  if (result == 'ADD_NEW') {
                    // '+ 추가' 선택 시 AddPersonScreen으로 이동
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
                  } else if (result.startsWith('DELETE:')) {
                    final personIdToDelete = result.split(':').last;
                    await notifier.deletePerson(personIdToDelete);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('사용자가 삭제되었습니다.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // 특정 사람 ID 선택 시 Notifier 상태 업데이트
                    notifier.setSelectedPersonId(result);
                  }
                }
                // result가 null이면 사용자가 다이얼로그 밖을 탭하여 닫은 경우 (별도 처리 없음)
                // ------------------------------------
              },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none, // 점이 아바타 밖으로 나가도 보이도록
              children: [
                CircleAvatar(
                  radius: 20, // 이미지 크기에 맞게 조절
                  backgroundColor: currentPersonIconBgColor,
                  child: Icon(
                    currentPersonIconData,
                    size: 24, // 아이콘 크기 조절
                    color: Colors.white, // 아이콘 색상 흰색
                  ),
                ),
                // 온라인 상태 표시 점 (Positioned 사용)
                Positioned(
                  bottom: -2, // 위치 조정
                  right: -2, // 위치 조정
                  child: Container(
                    width: 10, // 점 크기
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400, // 녹색 점
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ), // 흰색 테두리
                    ),
                  ),
                ),
              ],
            ),
            // ------------------------------------
            const SizedBox(width: 10), // 아이콘과 이름 사이 간격
            // --- 이름 ---
            Flexible(
              child: Text(
                currentPersonName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  // 텍스트 스타일 조정
                  fontWeight: FontWeight.bold, // 볼드 처리
                  fontSize: 18, // 폰트 크기 조정
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // -----------
            const SizedBox(width: 4), // 이름과 화살표 사이 간격
            // --- 드롭다운 화살표 (CircleAvatar 배경 추가) ---
            CircleAvatar(
              radius: 12, // 원 크기
              backgroundColor: Colors.grey.shade200, // 회색 배경
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18, // 아이콘 크기
                color: Colors.grey.shade700, // 아이콘 색상
              ),
            ),
            // ------------------------------------
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
    // 에러 메시지가 있고, 날씨 데이터가 없을 때만 전체 에러 화면 표시
    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.weatherDataUI == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                '데이터 로드 중 오류 발생',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                // Padding(
                //   // 선택된 사람 이름 표시 (기존과 동일)
                //   padding: const EdgeInsets.only(bottom: 8.0),
                //   child: Text(
                //     "${_getCurrentPersonName(ref)}님의 현재 정보",
                //     style: Theme.of(context).textTheme.bodySmall,
                //   ),
                // ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
