import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async'; // Future.wait 사용

// 상태 클래스 import
import 'main_screen_state.dart';

// 서비스 및 모델, 유틸리티 import
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/data_mapper.dart';
import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/api/common_models.dart'; // RegionInfo 사용 위해
import '../../../data/models/api/coordinates_response.dart'; // 필요 시
import '../../../data/models/api/env_map_response.dart';
import '../../../data/models/api/health_index_response.dart';
import '../../../data/models/api/map_api_response.dart';
import '../../../data/models/api/region_fine_dust_response.dart';
import '../../../data/models/api/region_uv_response.dart';
import '../../../data/models/api/weather_response.dart';
import '../../../data/models/ui/current_weather.dart';
import '../../../data/models/ui/feels_like_data.dart';
import '../../../data/models/ui/health_index.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/location_service.dart';

// Notifier 클래스 정의
class MainScreenNotifier extends StateNotifier<MainScreenState> {
  final LocationService _locationService;
  final ApiService _apiService;
  final PreferencesService _prefsService;

  // 생성자에서 초기 상태 및 서비스 주입
  MainScreenNotifier(
    this._locationService,
    this._apiService,
    this._prefsService,
  ) : super(const MainScreenState()) {
    // 초기 상태 설정
    _initializeScreen(); // 생성 시 초기화 로직 실행
  }

  // 화면 초기화 (사람 목록 로드 + 초기 데이터 로드)
  Future<void> _initializeScreen() async {
    // 동시에 로드 시도
    await Future.wait([_loadAddedPeople(), _loadVisibleIndicesFromPrefs()]);
    // 사람 목록 로드가 완료된 후 초기 데이터 로드
    await loadDataForSelectedPerson();
  }

  // 저장된 사람 목록 불러오기
  Future<void> _loadAddedPeople() async {
    state = state.copyWith(isLoadingPeople: true); // 로딩 상태 시작
    final people = await _prefsService.getAddedPeople();
    state = state.copyWith(
      addedPeopleList: people,
      isLoadingPeople: false,
    ); // 로딩 완료 및 목록 업데이트
    print("Loaded ${people.length} added people.");
  }

  // 저장된 보이는 지수 목록 불러오기
  Future<void> _loadVisibleIndicesFromPrefs() async {
    final savedIndices = await _prefsService.getVisibleIndices();
    final initialVisible = savedIndices ?? availableHealthIndices.toSet();
    state = state.copyWith(visibleIndices: initialVisible); // 상태 업데이트
    print("Visible indices loaded: $initialVisible");
  }

  // MenuScreen에서 돌아왔을 때 호출될 함수
  Future<void> reloadVisibleIndices() async {
    await _loadVisibleIndicesFromPrefs();
    // 상태가 업데이트되었으므로 UI는 자동으로 갱신됨 (별도 setState 필요 없음)
  }

  Future<void> refreshAddedPeople() async {
    await _loadAddedPeople();
  }

  // 선택된 사람 변경
  void setSelectedPersonId(String personId) {
    if (personId != state.selectedPersonId) {
      state = state.copyWith(selectedPersonId: personId);
      // 사람 변경 시 데이터 새로 로드
      loadDataForSelectedPerson(refresh: true);
    }
  }

  // 선택된 환경 지도 타입 변경
  void setSelectedEnvMapType(String mapType) {
    state = state.copyWith(selectedEnvMapType: mapType);
    // WebView는 build 메소드에서 컨트롤러를 선택하므로 즉시 로딩 필요 없음
  }

  // 선택된 재난 지도 타입 변경
  void setSelectedDisasterType(String mapType) {
    state = state.copyWith(selectedDisasterType: mapType);
    // WebView는 build 메소드에서 컨트롤러를 선택하므로 즉시 로딩 필요 없음
    // TODO: 만약 '선택 시 로드' 방식으로 변경한다면 여기서 API 호출 필요
  }

  // --- 현재 선택된 사람의 데이터 로드 함수 ---
  Future<void> loadDataForSelectedPerson({bool refresh = false}) async {
    if (!refresh) {
      state = state.copyWith(isLoading: true);
    }
    state = state.copyWith(
      errorMessage: null,
      clearErrorMessage: true,
    ); // 오류 메시지 초기화

    double? latitude;
    double? longitude;
    int? age;
    List<String>? userTypes;

    // 파라미터 결정 로직 (기존과 동일)
    if (state.selectedPersonId == MainScreenState().selectedPersonId) {
      // 'MY_INFO'
      try {
        final position = await _locationService.determinePosition();
        latitude = position.latitude;
        longitude = position.longitude;
        age = await _prefsService.getUserAge();
        userTypes = await _prefsService.getUserTypes() ?? [];
        print('Loading data for: MY INFO');
      } catch (e) {
        /* ... 에러 처리 ... */
        state = state.copyWith(
          errorMessage: "내 정보를 위한 위치/설정 로드 실패",
          isLoading: false,
        );
        return;
      }
    } else {
      final selectedPerson = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: 'Unknown'),
      );
      if (selectedPerson.id.isNotEmpty &&
          selectedPerson.latitude != null &&
          selectedPerson.longitude != null) {
        latitude = selectedPerson.latitude;
        longitude = selectedPerson.longitude;
        age = selectedPerson.age;
        userTypes = selectedPerson.userTypes ?? [];
        print('Loading data for: ${selectedPerson.name}');
      } else {
        /* ... 에러 처리 ... */
        state = state.copyWith(
          errorMessage: "선택된 사람 위치 정보 없음",
          isLoading: false,
        );
        return;
      }
    }

    if (latitude == null || longitude == null) {
      /* ... 에러 처리 ... */
      state = state.copyWith(errorMessage: "위치 정보 없음", isLoading: false);
      return;
    }

    // 사용된 좌표 저장
    state = state.copyWith(
      lastLoadedLatitude: latitude,
      lastLoadedLongitude: longitude,
    );

    try {
      // API 호출 (기존과 동일)
      // --- API 호출 리스트 생성 ---
      final Map<String, String> envMapTypes = {
        'fine_dust': '미세먼지',
        'uv': '자외선',
        'flood_trace': '침수흔적도',
      };
      final Map<String, String> disasterTypes = {
        'EARTHQUAKE': '지진',
        'COLD_WAVE': '한파',
        'HEAT_WAVE': '폭염',
        'FINE_DUST': '미세먼지',
        'FLOOD': '홍수',
      };

      List<Future<dynamic>> apiFutures = [
        _apiService.fetchWeather(latitude, longitude),
        _apiService.fetchHealthIndex(
          latitude,
          longitude,
          age: age,
          disease: userTypes,
        ),
        _apiService.fetchUv(latitude, longitude),
        _apiService.fetchFineDust(latitude, longitude),
        ...envMapTypes.keys.map((type) => _apiService.fetchEnvMap(type)),
        ...disasterTypes.keys.map(
          (type) => _apiService.fetchShelterMap(latitude!, longitude!, type),
        ),
      ];
      // -----------------------------
      final results = await Future.wait(apiFutures, eagerError: false);

      // --- 결과 처리 및 상태 업데이트 ---
      int currentIndex = 0;
      final WeatherDetailResponse? apiWeatherData =
          results[currentIndex++] as WeatherDetailResponse?;
      final HealthIndexResponse? apiHealthIndexData =
          results[currentIndex++] as HealthIndexResponse?;
      final SingleRegionUvResponse? apiUvData =
          results[currentIndex++] as SingleRegionUvResponse?;
      final SingleRegionFineDustResponse? apiFineDustData =
          results[currentIndex++] as SingleRegionFineDustResponse?;

      final Map<String, EnvMapApiResponse?> apiEnvMapData = {};
      for (var type in envMapTypes.keys) {
        apiEnvMapData[type] = results[currentIndex++] as EnvMapApiResponse?;
      }

      final Map<String, MapApiResponse?> apiShelterMapDataMap = {};
      for (var type in disasterTypes.keys) {
        apiShelterMapDataMap[type] = results[currentIndex++] as MapApiResponse?;
      }

      // 데이터 매핑
      CurrentWeather? weatherDataUI;
      FeelsLikeData? feelsLikeDataUI;
      List<HealthIndex> healthIndicesUI = [];
      if (apiWeatherData != null && apiHealthIndexData != null) {
        weatherDataUI = DataMapper.mapWeatherResponseToUI(
          apiWeatherData,
          apiHealthIndexData.region,
        );
        feelsLikeDataUI = DataMapper.mapFeelsLikeResponseToUI(
          apiHealthIndexData,
        );
        healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
          apiHealthIndexData,
          apiUvData,
          apiFineDustData,
        );
      }

      // WebView 컨트롤러 초기화/업데이트 로직 (중요: 새 상태와 함께 전달)
      final newEnvMapControllers = <String, WebViewController?>{};
      final newShelterMapControllers = <String, WebViewController?>{};
      _initializeWebViews(
        apiEnvMapData,
        apiShelterMapDataMap,
        newEnvMapControllers,
        newShelterMapControllers,
      );

      // 오류 집계
      final errors = results.where((r) => r is Exception || r == null).toList();
      final String? finalErrorMessage =
          errors.isNotEmpty
              ? errors
                  .map((e) => e?.toString() ?? 'Unknown API Error')
                  .join('\n')
              : null;

      // 최종 상태 업데이트
      state = state.copyWith(
        isLoading: false,
        errorMessage: finalErrorMessage,
        clearErrorMessage: finalErrorMessage == null, // 에러 없으면 이전 에러 클리어
        weatherDataUI: weatherDataUI,
        feelsLikeDataUI: feelsLikeDataUI,
        healthIndicesUI: healthIndicesUI,
        envMapControllers: newEnvMapControllers, // 업데이트된 컨트롤러 맵 전달
        shelterMapControllers: newShelterMapControllers, // 업데이트된 컨트롤러 맵 전달
      );
      print("Data loaded for selected person.");
      // -----------------------------
    } catch (e, stacktrace) {
      print('Error loading data: $e\n$stacktrace');
      state = state.copyWith(errorMessage: '데이터 로드 중 오류: $e', isLoading: false);
    }
  }

  // WebView 컨트롤러 초기화 (내부 로직으로 변경)
  void _initializeWebViews(
    Map<String, EnvMapApiResponse?> apiEnvMapData,
    Map<String, MapApiResponse?> apiShelterMapDataMap,
    Map<String, WebViewController?> envControllersTarget, // 결과를 저장할 맵
    Map<String, WebViewController?> shelterControllersTarget, // 결과를 저장할 맵
  ) {
    apiEnvMapData.forEach((type, mapData) {
      if (mapData?.envMapHtml != null) {
        envControllersTarget[type] =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(mapData!.envMapHtml!, baseUrl: null);
      } else {
        envControllersTarget[type] = null;
      }
    });
    apiShelterMapDataMap.forEach((type, mapData) {
      if (mapData?.shelterMapHtml != null) {
        shelterControllersTarget[type] =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(mapData!.shelterMapHtml!, baseUrl: null);
      } else {
        shelterControllersTarget[type] = null;
      }
    });
  }
} // End of Notifier class

// --- Provider 정의 ---

// 서비스 Provider들 (싱글톤처럼 사용)
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

// MainScreen 상태 관리를 위한 StateNotifierProvider
final mainScreenNotifierProvider =
    StateNotifierProvider<MainScreenNotifier, MainScreenState>((ref) {
      // ref.watch를 사용하면 다른 Provider의 상태 변경 시 이 Provider도 다시 생성될 수 있음
      // 여기서는 각 서비스가 변경되지 않는 싱글톤이므로 ref.read 또는 ref.watch 사용 가능
      return MainScreenNotifier(
        ref.read(locationServiceProvider),
        ref.read(apiServiceProvider),
        ref.read(preferencesServiceProvider),
      );
    });
