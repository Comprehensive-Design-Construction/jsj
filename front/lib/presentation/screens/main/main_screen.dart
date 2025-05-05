import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 상태 및 Notifier Provider import
import 'main_screen_notifier.dart';
import 'main_screen_state.dart';

// 서비스, 모델, 유틸리티, 위젯 import
import '../../../core/constants/app_constants.dart';
import '../../../data/models/added_person.dart';

// 섹션 위젯 import (변경된 부분 없음)
import 'widgets/location_info_widget.dart';
import 'widgets/weather_section_widget.dart';
import 'widgets/feels_like_section_widget.dart';
import 'widgets/major_health_indices_widget.dart';
import 'widgets/all_health_indices_widget.dart';
import 'widgets/env_map_section_widget.dart';
import 'widgets/shelter_map_section_widget.dart';
import 'widgets/partial_error_widget.dart';

// 기존 위젯 및 화면 import
import '../../widgets/main_screen/person_selection_dialog.dart';
import '../menu/menu_screen.dart';
import '../add_person/add_person_screen.dart';
import '../profile/edit_profile_screen.dart';

// --- ConsumerStatefulWidget 정의 ---
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  // 지도 타입 상수 정의 (static 유지)
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
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _majorHealthSectionKey = GlobalKey();
  final GlobalKey _environmentMapSectionKey = GlobalKey();
  final GlobalKey _shelterSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    // --- 콜백 내에서는 ref.read 사용 ---
    final notifier = ref.read(mainScreenNotifierProvider.notifier);
    // ----------------------------------
    GlobalKey? targetKey;

    if (index == 0 && _selectedIndex != 0) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else if (index == 1) {
      targetKey = _majorHealthSectionKey;
    } else if (index == 2) {
      targetKey = _environmentMapSectionKey;
    } else if (index == 3) {
      targetKey = _shelterSectionKey;
    } else if (index == 4) {
      // 메뉴 화면 이동 및 결과 처리
      await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
      // --- 콜백 내에서는 ref.read 사용 ---
      // MenuScreen에서 돌아오면 visibleIndices 및 데이터 새로고침
      await ref
          .read(mainScreenNotifierProvider.notifier)
          .reloadVisibleIndices();
      if (!mounted) return;
      await ref
          .read(mainScreenNotifierProvider.notifier)
          .loadDataForSelectedPerson(refresh: true);
      // ----------------------------------
      return;
    }

    if (targetKey != null) {
      final targetContext = targetKey.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    }

    if (index != 4 && mounted) {
      // 메뉴 탭이 아니고, 위젯이 마운트된 상태일 때만 인덱스 업데이트
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 필요한 전체 상태 감시 ---
    final state = ref.watch(mainScreenNotifierProvider);
    // -------------------------
    // --- 특정 상태만 감시 예시 (필요시 사용) ---
    // final isLoading = ref.watch(mainScreenNotifierProvider.select((s) => s.isLoading));
    // final weatherDataUI = ref.watch(mainScreenNotifierProvider.select((s) => s.weatherDataUI));
    // -------------------------------------

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: _buildPersonSelectorDropdown(context, ref),
            ), // Dropdown은 내부에서 state 사용
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: Image.asset(
                  'assets/images/welogo.png',
                  height: 50,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(context, ref, state), // state를 명시적으로 전달 (선택 사항)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: '건강지수',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: '환경 지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse),
            label: '대피소 위치',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            activeIcon: Icon(Icons.menu_open_rounded),
            label: '메뉴',
          ),
        ],
      ),
    );
  }

  // AppBar 사용자 선택 드롭다운 빌더 (기존과 거의 동일, Dialog 호출 부분 변경 없음)
  Widget _buildPersonSelectorDropdown(BuildContext context, WidgetRef ref) {
    // --- 드롭다운 UI 구성에 필요한 상태만 watch ---
    final selectedPersonId = ref.watch(
      mainScreenNotifierProvider.select((s) => s.selectedPersonId),
    );
    final addedPeopleList = ref.watch(
      mainScreenNotifierProvider.select((s) => s.addedPeopleList),
    );
    final isLoading = ref.watch(
      mainScreenNotifierProvider.select((s) => s.isLoading),
    ); // 탭 가능 여부 결정용
    final isLoadingPeople = ref.watch(
      mainScreenNotifierProvider.select((s) => s.isLoadingPeople),
    ); // 탭 가능 여부 결정용
    // --------------------------------------

    String currentPersonName = "내 정보";
    IconData currentPersonIconData = Icons.person_rounded;
    Color currentPersonIconBgColor = Colors.deepPurple.shade300;

    if (selectedPersonId != myInfoId) {
      final person = addedPeopleList.firstWhere(
        (p) => p.id == selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '???'),
      );
      currentPersonName = person.name;
      currentPersonIconData = Icons.person_outline;
      currentPersonIconBgColor = Colors.deepPurpleAccent;
    }

    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap:
          isLoadingPeople || isLoading
              ? null
              : () async {
                // --- 콜백 내에서는 ref.read 사용 ---
                final notifier = ref.read(mainScreenNotifierProvider.notifier);
                final currentSelectedPersonId =
                    ref
                        .read(mainScreenNotifierProvider)
                        .selectedPersonId; // 현재 선택 ID 읽기
                final currentAddedPeople =
                    ref
                        .read(mainScreenNotifierProvider)
                        .addedPeopleList; // 현재 목록 읽기
                // ----------------------------------

                final result = await showGeneralDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel:
                      MaterialLocalizations.of(
                        context,
                      ).modalBarrierDismissLabel,
                  barrierColor: Colors.black.withOpacity(0.3),
                  transitionDuration: const Duration(milliseconds: 200),
                  pageBuilder: (buildContext, _, __) {
                    return Material(
                      type: MaterialType.transparency,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: appBarHeight + statusBarHeight + 4.0,
                            ),
                            child: PersonSelectionDialogContent(
                              // 읽어온 상태 전달
                              currentSelectedPersonId: currentSelectedPersonId,
                              addedPeople: currentAddedPeople,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(buildContext).pop(),
                              behavior: HitTestBehavior.opaque,
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
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.02),
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

                // 다이얼로그 결과 처리 (기존 로직 유지)
                if (result != null && mounted) {
                  // 결과 처리 전 mounted 확인
                  if (result == 'ADD_NEW') {
                    final added = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPersonScreen(),
                      ),
                    );
                    if (added == true && mounted) {
                      // Navigator 후 mounted 확인
                      await ref
                          .read(mainScreenNotifierProvider.notifier)
                          .refreshAddedPeople();
                    }
                  } else if (result.startsWith('DELETE:')) {
                    final personIdToDelete = result.split(':').last;
                    await ref
                        .read(mainScreenNotifierProvider.notifier)
                        .deletePerson(personIdToDelete);
                    if (mounted) {
                      // deletePerson 후 mounted 확인
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('사용자가 삭제되었습니다.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    ref
                        .read(mainScreenNotifierProvider.notifier)
                        .setSelectedPersonId(result);
                  }
                }
              },
      child: Padding(
        // 드롭다운 UI (기존과 동일)
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: currentPersonIconBgColor,
                  child: Icon(
                    currentPersonIconData,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                currentPersonName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 화면 본문 빌드 함수 (분리된 위젯 사용) ---
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MainScreenState state,
  ) {
    final state = ref.watch(mainScreenNotifierProvider);
    final notifier = ref.read(mainScreenNotifierProvider.notifier);

    // 초기 로딩 또는 완전 로딩 실패 처리
    if (state.isLoading && state.weatherDataUI == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.weatherDataUI == null) {
      // 전체 에러 화면 표시 (기존 코드 유지)
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
          SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocationInfoWidget(), // 내부에서 필요한 상태 watch
                const WeatherSectionWidget(), // 내부에서 필요한 상태 watch
                const FeelsLikeSectionWidget(), // 내부에서 필요한 상태 watch
                Container(
                  key: _majorHealthSectionKey,
                  child: const MajorHealthIndicesWidget(),
                ), // 내부에서 필요한 상태 watch
                const AllHealthIndicesWidget(), // 내부에서 필요한 상태 watch
                Container(
                  key: _environmentMapSectionKey,
                  child: EnvMapSectionWidget(
                    envMapTypes: MainScreen._envMapTypes,
                  ),
                ), // 내부에서 필요한 상태 watch
                Container(
                  key: _shelterSectionKey,
                  child: ShelterMapSectionWidget(
                    disasterTypes: MainScreen._disasterTypes,
                  ),
                ), // 내부에서 필요한 상태 watch
                const PartialErrorWidget(), // 내부에서 필요한 상태 watch
              ],
            ),
          ),
          // 전체 화면 로딩 인디케이터
          if (state.isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
