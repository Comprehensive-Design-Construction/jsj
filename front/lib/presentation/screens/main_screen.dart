import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 서비스, 모델, 유틸리티, 위젯 import (경로 수정)
import '../../core/constants/app_constants.dart';
import '../../core/utils/data_mapper.dart';
import '../../core/utils/preferences_service.dart';
import '../../data/models/api/common_models.dart';
import '../../data/models/api/health_index_response.dart';
import '../../data/models/api/weather_response.dart';
import '../../data/models/api/region_fine_dust_response.dart';
import '../../data/models/api/region_uv_response.dart';
import '../../data/models/api/env_map_response.dart';
import '../../data/models/api/map_api_response.dart';
import '../../data/models/ui/current_weather.dart';
import '../../data/models/ui/feels_like_data.dart';
import '../../data/models/ui/health_index.dart';
import '../../data/models/ui/user_profile.dart'; // 임시 사용자 이름용
import '../../data/services/location_service.dart';
import '../../data/services/api_service.dart';
import '../widgets/main_screen/weather_info_card.dart';
import '../widgets/main_screen/feels_like_card.dart';
import '../widgets/main_screen/health_index_card.dart';
import '../widgets/main_screen/health_index_info_dialog.dart';
import 'menu/menu_screen.dart';
// import '../widgets/common/loading_indicator.dart'; // 필요 시 공통 로딩 위젯
// import '../widgets/common/error_display.dart'; // 필요 시 공통 에러 위젯

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 서비스 인스턴스
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  // 상태 변수
  Position? _currentPosition;
  bool _isLoading = true; // 초기 로딩 상태 true
  String? _errorMessage;

  final PreferencesService _prefsService = PreferencesService();
  int? _userAge; // 로드된 사용자 나이
  List<String>? _userDiseaseTypes; // 로드된 사용자 특성/질병 리스트

  // --- API 응답 데이터 저장 ---
  UserProfile? _userProfile; // 사용자 프로필 (현재는 이름만, API 연동 X)
  WeatherDetailResponse? _apiWeatherData;
  HealthIndexResponse? _apiHealthIndexData;
  SingleRegionUvResponse? _apiUvData;
  SingleRegionFineDustResponse? _apiFineDustData;

  final Map<String, EnvMapApiResponse?> _apiEnvMapData = {
    'fine_dust': null,
    'uv': null,
    'flood_trace': null,
  };
  final Map<String, WebViewController?> _envMapControllers = {
    'fine_dust': null,
    'uv': null,
    'flood_trace': null,
  };

  String _selectedEnvMapType = 'fine_dust';

  final Map<String, MapApiResponse?> _apiShelterMapDataMap = {};
  final Map<String, WebViewController?> _shelterMapControllers = {};
  String _selectedDisasterType = 'EARTHQUAKE'; // 기본 재난 유형

  // 재난 유형 목록 (API 명세 기반)
  final Map<String, String> _disasterTypes = {
    'EARTHQUAKE': '지진',
    'COLD_WAVE': '한파',
    'HEAT_WAVE': '폭염',
    'FINE_DUST': '미세먼지',
    'FLOOD': '홍수',
  };
  // 환경 지도 유형 목록 (API 명세 기반)
  final Map<String, String> _envMapTypes = {
    'fine_dust': '미세먼지',
    'uv': '자외선',
    'flood_trace': '침수흔적도',
  };

  // 하단 네비게이션 인덱스
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // 초기 데이터 로드 함수 호출
    _loadVisibleIndicesFromPrefs();
  }

  Set<String> _savedVisibleIndices =
      availableHealthIndices.toSet(); // 보이는 지수 상태 변수 추가

  Future<void> _loadVisibleIndicesFromPrefs() async {
    final savedIndices = await _prefsService.getVisibleIndices();
    if (savedIndices != null && mounted) {
      setState(() {
        _savedVisibleIndices = savedIndices;
      });
    }
    print("Initial visible indices loaded: $_savedVisibleIndices");
  }

  // --- 데이터 로드 함수 (실제 API 호출) ---
  Future<void> _loadInitialData({bool refresh = false}) async {
    // 사용자 프로필 로드 (임시)
    _userProfile = UserProfile(name: "엘리엇"); // TODO: 실제 사용자 정보 연동

    if (!refresh) {
      // 새로고침이 아닐 때만 로딩 표시
      setState(() => _isLoading = true);
    }
    _errorMessage = null; // 오류 메시지 초기화

    try {
      // 로컬 저장소에서 사용자 정보 로드
      if (!refresh) {
        _userAge = await _prefsService.getUserAge();
        _userDiseaseTypes = await _prefsService.getUserTypes();
        print('Loaded User Info: age=$_userAge, types=$_userDiseaseTypes');
      }

      // 위치 정보 가져오기
      _currentPosition = await _locationService.determinePosition();
      print(
        'Using Location: Lat=${_currentPosition?.latitude}, Lon=${_currentPosition?.longitude}',
      );

      if (_currentPosition != null) {
        final lat = _currentPosition!.latitude;
        final lon = _currentPosition!.longitude;

        // --- API 호출 리스트 생성 ---
        List<Future<dynamic>> apiFutures = [
          _apiService.fetchWeather(lat, lon),
          _apiService.fetchHealthIndex(
            lat,
            lon,
            age: _userAge,
            disease: _userDiseaseTypes ?? [],
          ),
          _apiService.fetchUv(lat, lon),
          _apiService.fetchFineDust(lat, lon),
          // 환경 지도 API 호출 (모든 타입)
          ..._envMapTypes.keys.map((type) => _apiService.fetchEnvMap(type)),
          // 대피소 지도 API 호출 (모든 타입) - !!! 로딩 시간 길어질 수 있음 !!!
          ..._disasterTypes.keys.map(
            (type) => _apiService.fetchShelterMap(lat, lon, type),
          ),
        ];

        final results = await Future.wait(apiFutures, eagerError: false);

        // --- 결과 저장 (수정) ---
        int currentIndex = 0;
        _apiWeatherData = results[currentIndex++] as WeatherDetailResponse?;
        _apiHealthIndexData = results[currentIndex++] as HealthIndexResponse?;
        _apiUvData = results[currentIndex++] as SingleRegionUvResponse?;
        _apiFineDustData =
            results[currentIndex++] as SingleRegionFineDustResponse?;

        // 환경 지도 결과 저장
        for (var type in _envMapTypes.keys) {
          _apiEnvMapData[type] = results[currentIndex++] as EnvMapApiResponse?;
        }
        // 대피소 지도 결과 저장
        for (var type in _disasterTypes.keys) {
          _apiShelterMapDataMap[type] =
              results[currentIndex++] as MapApiResponse?;
        }
        // ------------------------

        // 오류 집계 (Future.wait에서 eagerError: false 사용 시 개별 확인)
        final errors = results.where((r) => r is Exception).toList();
        if (errors.isNotEmpty) {
          _errorMessage = errors.map((e) => e.toString()).join('\n');
          print("API Errors: $_errorMessage");
        }

        // WebView 컨트롤러 초기화 및 HTML 로드
        _initializeWebViews();
      } else {
        _errorMessage = '위치 정보를 가져올 수 없습니다.';
      }
    } catch (e, stacktrace) {
      // Future.wait(eagerError: true) 일 때 또는 위치 에러
      print('Error loading initial data: $e\n$stacktrace');
      _errorMessage = '데이터 로드 중 오류 발생: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // WebView 컨트롤러 초기화 함수
  void _initializeWebViews() {
    // 환경 지도 컨트롤러 초기화
    _envMapTypes.keys.forEach((type) {
      final mapData = _apiEnvMapData[type];
      if (mapData?.envMapHtml != null) {
        _envMapControllers[type] =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(mapData!.envMapHtml!, baseUrl: null);
      } else {
        _envMapControllers[type] = null;
      }
    });
    _disasterTypes.keys.forEach((type) {
      final mapData = _apiShelterMapDataMap[type];
      if (mapData?.shelterMapHtml != null) {
        _shelterMapControllers[type] =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(mapData!.shelterMapHtml!, baseUrl: null);
      } else {
        _shelterMapControllers[type] = null;
      }
    });
  }

  // 하단 네비게이션 탭 선택
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // TODO: 각 탭 인덱스에 따른 화면 전환 또는 기능 구현
      print('Tapped index: $index');
      if (index == 1) {
        /* 지도 관련 탭? */
      } else if (index == 2) {
        /* 다른 지도 또는 메뉴? */
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        ).then((_) {
          print("Returned from MenuScreen, reloading visible indices...");
          _loadVisibleIndicesAndUpdate();
        });
      }
    });
  }

  Future<void> _loadVisibleIndicesAndUpdate() async {
    final savedIndices = await _prefsService.getVisibleIndices();
    setState(() {
      _savedVisibleIndices = savedIndices ?? availableHealthIndices.toSet();
    });
    print("Visible indices reloaded: $_savedVisibleIndices");
  }

  @override
  Widget build(BuildContext context) {
    // --- 데이터 매핑 (빌드 시점에 수행) ---
    // 실제 API 응답 데이터를 UI 모델로 변환
    CurrentWeather? currentWeatherUI;
    FeelsLikeData? feelsLikeDataUI;
    List<HealthIndex> healthIndicesUI = []; // 기본 빈 리스트

    if (_apiWeatherData != null && _apiHealthIndexData != null) {
      // 날씨 정보 매핑 (RegionInfo는 HealthIndex 응답에서 가져옴)
      currentWeatherUI = DataMapper.mapWeatherResponseToUI(
        _apiWeatherData!,
        _apiHealthIndexData!.region, // HealthIndex 응답의 RegionInfo 사용
      );
      // 체감 온도 매핑
      feelsLikeDataUI = DataMapper.mapFeelsLikeResponseToUI(
        _apiHealthIndexData!,
      );

      // 건강 지수 리스트 매핑
      healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
        _apiHealthIndexData, // Nullable이지만 위에서 체크함
        _apiUvData,
        _apiFineDustData,
      );
    }
    // ---------------------------------

    return Scaffold(
      appBar: AppBar(
        title: Row(
          // AppBar 내용은 기존 코드와 유사하게 유지
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade50,
              child: Icon(
                Icons.person_rounded,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              _isLoading ? '...' : (_userProfile?.name ?? '사용자'),
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            Icon(
              Icons.expand_more,
              color: Colors.grey[600],
              size: 22,
            ), // TODO: 사용자 선택 기능?
            Spacer(),
            // 로고 이미지 로드 (경로 확인!)
            Image.asset(
              'assets/images/welogo.png',
              height: 30, // 높이 약간 줄임
              errorBuilder:
                  (context, error, stackTrace) =>
                      SizedBox(width: 40, height: 30),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading
                    ? null
                    : () =>
                        _loadInitialData(refresh: true), // 새로고침 시 refresh=true
            tooltip: '데이터 새로고침',
          ),
        ],
      ),
      body: _buildBody(
        currentWeatherUI,
        feelsLikeDataUI,
        healthIndicesUI,
      ), // 매핑된 데이터 전달
      bottomNavigationBar: BottomNavigationBar(
        // 테마는 AppTheme에서 적용됨
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          // 아이콘은 기존과 동일하게 유지
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

  // 화면 본문 빌드 함수 (매핑된 데이터 받도록 수정)
  Widget _buildBody(
    CurrentWeather? weatherData,
    FeelsLikeData? feelsLikeData,
    List<HealthIndex> healthIndices,
  ) {
    if (_isLoading) {
      // return LoadingIndicator(); // 공통 로딩 위젯 사용 시
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && weatherData == null) {
      // 데이터 로드 완전히 실패 시
      // return ErrorDisplay(message: _errorMessage!, onRetry: _loadInitialData); // 공통 에러 위젯 사용 시
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadInitialData(refresh: true),
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 부분적 에러는 _errorMessage를 통해 표시하고, 로드된 데이터는 보여줌
    // (StatefulWidget 특성상 setState 호출 시 build가 다시 실행됨)

    // 데이터가 있으면 UI 표시
    return RefreshIndicator(
      onRefresh: () => _loadInitialData(refresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // 패딩 조정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 위치 정보 표시
            if (_currentPosition != null) // 위치 정보 있을 때만 표시
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      weatherData?.location ?? '위치 로딩 중...', // 매핑된 위치 사용
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    // 기본 위치 사용 시 알림 (선택 사항)
                    if (_currentPosition!.latitude == defaultLatitude &&
                        _currentPosition!.longitude == defaultLongitude)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '(기본위치)',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

            // --- 날씨 정보 카드 ---
            if (weatherData != null)
              WeatherInfoCard(weatherData: weatherData)
            else
              _buildDataErrorPlaceholder(
                '날씨 정보를 불러올 수 없습니다.',
              ), // 데이터 없을 시 Placeholder
            const SizedBox(height: 24),

            // --- 체감 온도 섹션 ---
            _buildSectionTitle('체감온도'),
            const SizedBox(height: 10),
            if (feelsLikeData != null)
              FeelsLikeCard(feelsLikeData: feelsLikeData)
            else
              _buildDataErrorPlaceholder('체감온도 정보를 불러올 수 없습니다.'),
            const SizedBox(height: 24),

            // --- 주요 건강 지수 섹션 ---
            Row(
              // 섹션 제목과 아이콘을 Row로 묶음
              children: [
                Text(
                  '주요 건강 지수',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 6),
                // 정보 아이콘을 IconButton으로 감싸 탭 가능하게 만듦
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                  padding: EdgeInsets.zero, // 내부 여백 제거
                  constraints: BoxConstraints(), // 크기 제약 최소화
                  splashRadius: 18, // 물결 효과 범위
                  tooltip: '주요 건강 지수 설명 보기',
                  onPressed: () {
                    // 팝업 표시 함수 호출
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        // barrierDismissible: false, // 바깥 영역 탭해도 안닫히게 하려면
                        return const HealthIndexInfoDialog(); // 생성한 다이얼로그 위젯 반환
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMajorHealthIndices(healthIndices),
            const SizedBox(height: 24),

            // --- 전체 건강 지수 섹션 ---
            _buildSectionTitle('전체 건강 지수', showInfoIcon: true),
            const SizedBox(height: 10),
            _buildAllHealthIndexList(healthIndices), // 매핑된 리스트 전달
            const SizedBox(height: 24),

            // --- 환경 지도 섹션 (WebView) ---
            _buildSectionTitle('환경 지도'),
            const SizedBox(height: 10),
            _buildMapTypeDropdown(
              // 환경 지도 드롭다운 빌더 호출
              mapTypes: _envMapTypes,
              selectedValue: _selectedEnvMapType,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedEnvMapType = newValue);
                }
              },
            ),
            const SizedBox(height: 10),
            _buildWebViewMap(
              // 선택된 타입의 컨트롤러 전달
              controller: _envMapControllers[_selectedEnvMapType],
              placeholderIcon: Icons.public, // 예시 아이콘
              placeholderText:
                  '${_envMapTypes[_selectedEnvMapType] ?? "환경"} 지도를 불러오는 중...',
            ),
            const SizedBox(height: 24),

            // --- 대피소 위치 섹션 (WebView) ---
            _buildSectionTitle('대피소 위치'),
            const SizedBox(height: 10),
            _buildMapTypeDropdown(
              // 대피소 유형 드롭다운 빌더 호출
              mapTypes: _disasterTypes,
              selectedValue: _selectedDisasterType,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  // TODO: 여기서 API를 호출하는 것이 더 효율적일 수 있음 (현재는 pre-fetch 방식)
                  print("Shelter map type changed to: $newValue");
                  setState(() => _selectedDisasterType = newValue);
                }
              },
            ),
            const SizedBox(height: 10),
            _buildWebViewMap(
              // 선택된 타입의 컨트롤러 전달
              controller: _shelterMapControllers[_selectedDisasterType],
              placeholderIcon: Icons.pin_drop_outlined,
              placeholderText:
                  '${_disasterTypes[_selectedDisasterType] ?? "대피소"} 지도를 불러오는 중...',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
  Widget _buildSectionTitle(String title, {bool showInfoIcon = false}) {
    /* ... 이전 코드와 동일 ... */
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (showInfoIcon) ...[
          SizedBox(width: 6),
          Icon(Icons.info_outline_rounded, color: Colors.grey[500], size: 18),
        ],
      ],
    );
  }

  // 주요 건강 지수 리스트 위젯 빌더 (매핑된 데이터 받도록 수정)
  Widget _buildMajorHealthIndices(List<HealthIndex> indices) {
    // TODO: 사용자가 주요 지수를 선택하는 기능 구현 시 이 필터링 로직 변경 필요
    final List<String> majorDisplayNames = ['심뇌혈관질환 지수', '자외선 지수' /* ... */];
    final List<HealthIndex> filteredMajorIndices =
        indices.where((indexData) {
          return majorDisplayNames.contains(indexData.name);
        }).toList();

    if (filteredMajorIndices.isEmpty) {
      return _buildDataErrorPlaceholder('표시할 주요 건강 지수가 없습니다.'); // 플레이스홀더 사용
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
  Widget _buildAllHealthIndexList(List<HealthIndex> allMappedIndices) {
    // 1. 저장된 설정(_savedVisibleIndices) 기준으로 필터링
    final List<HealthIndex> filteredHealthIndices =
        allMappedIndices
            .where((index) => _savedVisibleIndices.contains(index.name))
            .toList();

    if (filteredHealthIndices.isEmpty) {
      return _buildDataErrorPlaceholder('표시할 건강 지수가 없습니다.');
    }

    // 2. 필터링된 리스트로 ListView 생성
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

  Widget _buildMapTypeDropdown({
    required Map<String, String> mapTypes, // {'api_value': '한글이름'} 형태의 맵
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
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
          onChanged: onChanged, // 선택 시 호출될 콜백
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
