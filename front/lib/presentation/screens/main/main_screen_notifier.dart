import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

// 상태 클래스 import
import 'main_screen_state.dart';

// 서비스 및 모델, 유틸리티 import
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/data_mapper.dart';
import '../../../core/utils/preferences_service.dart';
import '../../../data/models/added_person.dart';
import '../../../data/models/api/common_models.dart';
import '../../../data/models/api/coordinates_response.dart';
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

// API 호출 파라미터를 묶기 위한 레코드 타입 정의 (Dart 3 이상)
typedef _ApiParams =
    ({double latitude, double longitude, int? age, List<String>? userTypes});

// API 호출 결과를 묶기 위한 레코드 타입 정의
typedef _ApiRawResults =
    ({
      WeatherDetailResponse? weather,
      HealthIndexResponse? healthIndex,
      SingleRegionUvResponse? uv,
      SingleRegionFineDustResponse? fineDust,
      Map<String, EnvMapApiResponse?> envMaps,
      Map<String, MapApiResponse?> shelterMaps,
      List<dynamic> errors, // 실패한 API 결과나 Exception 저장
    });

// 매핑된 UI 데이터와 컨트롤러를 묶기 위한 레코드 타입 정의
typedef _ProcessedData =
    ({
      CurrentWeather? weatherUI,
      FeelsLikeData? feelsLikeUI,
      List<HealthIndex> healthIndicesUI,
      Map<String, WebViewController?> envMapControllers,
      Map<String, WebViewController?> shelterMapControllers,
      String? errorMessage,
    });

// Notifier 클래스 정의
class MainScreenNotifier extends StateNotifier<MainScreenState> {
  final LocationService _locationService;
  final ApiService _apiService;
  final PreferencesService _prefsService;

  // 지도 타입 상수 (Notifier 내부에서도 사용)
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

  MainScreenNotifier(
    this._locationService,
    this._apiService,
    this._prefsService,
  ) : super(const MainScreenState()) {
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([_loadAddedPeople(), _loadVisibleIndicesFromPrefs()]);
    await loadDataForSelectedPerson();
  }

  Future<void> _loadAddedPeople() async {
    state = state.copyWith(isLoadingPeople: true);
    final people = await _prefsService.getAddedPeople();
    state = state.copyWith(addedPeopleList: people, isLoadingPeople: false);
    print("Loaded ${people.length} added people.");
  }

  Future<void> _loadVisibleIndicesFromPrefs() async {
    final savedIndices = await _prefsService.getVisibleIndices();
    final initialVisible = savedIndices ?? availableHealthIndices.toSet();
    state = state.copyWith(visibleIndices: initialVisible);
    print("Visible indices loaded: $initialVisible");
  }

  Future<void> reloadVisibleIndices() async {
    await _loadVisibleIndicesFromPrefs();
  }

  Future<void> refreshAddedPeople() async {
    await _loadAddedPeople();
  }

  void setSelectedPersonId(String personId) {
    if (personId != state.selectedPersonId) {
      state = state.copyWith(selectedPersonId: personId);
      loadDataForSelectedPerson(refresh: true);
    }
  }

  void setSelectedEnvMapType(String mapType) {
    state = state.copyWith(selectedEnvMapType: mapType);
  }

  void setSelectedDisasterType(String mapType) {
    state = state.copyWith(selectedDisasterType: mapType);
  }

  // --- 데이터 로드 메인 함수 (이제 내부 로직 호출 역할) ---
  Future<void> loadDataForSelectedPerson({bool refresh = false}) async {
    // 1. 로딩 상태 및 오류 메시지 초기화
    if (!refresh) {
      state = state.copyWith(isLoading: true);
    }
    state = state.copyWith(errorMessage: null, clearErrorMessage: true);

    try {
      // 2. API 호출 파라미터 결정
      final params = await _determineApiParams();

      // 3. 결정된 파라미터로 병렬 API 호출
      final apiResults = await _fetchApiDataInParallel(params);

      // 4. API 결과 처리 및 UI 데이터/컨트롤러 생성
      final processedData = _processApiResults(apiResults);

      // 5. 최종 상태 업데이트
      state = state.copyWith(
        isLoading: false,
        errorMessage: processedData.errorMessage, // 처리된 에러 메시지 사용
        clearErrorMessage: processedData.errorMessage == null,
        weatherDataUI: processedData.weatherUI,
        feelsLikeDataUI: processedData.feelsLikeUI,
        healthIndicesUI: processedData.healthIndicesUI,
        envMapControllers: processedData.envMapControllers,
        shelterMapControllers: processedData.shelterMapControllers,
        lastLoadedLatitude: params.latitude, // 사용된 좌표 저장
        lastLoadedLongitude: params.longitude,
      );
      print("Data loaded for selected person.");
    } catch (e, stacktrace) {
      // _determineApiParams 등에서 발생할 수 있는 예외 처리
      print('Error loading data preparation: $e\n$stacktrace');
      state = state.copyWith(errorMessage: '데이터 준비 중 오류: $e', isLoading: false);
    }
  }

  // --- Helper 함수들 ---

  /// 1. API 호출에 필요한 파라미터(위경도, 나이, 타입) 결정
  Future<_ApiParams> _determineApiParams() async {
    double? latitude;
    double? longitude;
    int? age;
    List<String>? userTypes;

    if (state.selectedPersonId == myInfoId) {
      try {
        final position = await _locationService.determinePosition();
        latitude = position.latitude;
        longitude = position.longitude;
        age = await _prefsService.getUserAge();
        userTypes = await _prefsService.getUserTypes() ?? [];
        print('Determined params for: MY INFO');
      } catch (e) {
        print('Failed to load location/settings for MY INFO: $e');
        throw Exception(
          "내 정보를 위한 위치/설정 로드 실패: $e",
        ); // 여기서 예외 발생시켜 loadDataForSelectedPerson에서 처리
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
        print('Determined params for: ${selectedPerson.name}');
      } else {
        throw Exception("선택된 사람의 위치 정보가 유효하지 않습니다.");
      }
    }

    // 위경도 null 체크 강화
    if (latitude == null || longitude == null) {
      throw Exception("위치 정보를 가져올 수 없습니다.");
    }

    return (
      latitude: latitude,
      longitude: longitude,
      age: age,
      userTypes: userTypes,
    );
  }

  /// 2. 결정된 파라미터로 필요한 API 병렬 호출
  Future<_ApiRawResults> _fetchApiDataInParallel(_ApiParams params) async {
    List<Future<dynamic>> apiFutures = [
      _apiService.fetchWeather(params.latitude, params.longitude),
      _apiService.fetchHealthIndex(
        params.latitude,
        params.longitude,
        age: params.age,
        disease: params.userTypes,
      ),
      _apiService.fetchUv(params.latitude, params.longitude),
      _apiService.fetchFineDust(params.latitude, params.longitude),
      ..._envMapTypes.keys.map((type) => _apiService.fetchEnvMap(type)),
      ..._disasterTypes.keys.map(
        (type) => _apiService.fetchShelterMap(
          params.latitude,
          params.longitude,
          type,
        ),
      ),
    ];

    // Future.wait는 첫번째 에러 발생 시 즉시 에러를 반환 (eagerError: true 기본값)
    // 모든 Future가 완료되고 결과를 받으려면 (성공/실패 포함) Completer 등을 사용하거나,
    // 각 Future를 try-catch로 감싸서 null 또는 에러 객체를 반환하도록 ApiService 수정 필요.
    // 여기서는 일단 eagerError: false 사용하여 모든 Future가 완료될 때까지 기다림.
    final results = await Future.wait(apiFutures, eagerError: false);

    // 결과 파싱 (순서 주의!)
    int currentIndex = 0;
    final weatherResult = results[currentIndex++] as WeatherDetailResponse?;
    final healthIndexResult = results[currentIndex++] as HealthIndexResponse?;
    final uvResult = results[currentIndex++] as SingleRegionUvResponse?;
    final fineDustResult =
        results[currentIndex++] as SingleRegionFineDustResponse?;

    final envMapResults = <String, EnvMapApiResponse?>{};
    for (var type in _envMapTypes.keys) {
      envMapResults[type] = results[currentIndex++] as EnvMapApiResponse?;
    }

    final shelterMapResults = <String, MapApiResponse?>{};
    for (var type in _disasterTypes.keys) {
      shelterMapResults[type] = results[currentIndex++] as MapApiResponse?;
    }

    // 오류 집계 (Exception 또는 null인 경우)
    final errors = results.where((r) => r == null || r is Exception).toList();

    return (
      weather: weatherResult,
      healthIndex: healthIndexResult,
      uv: uvResult,
      fineDust: fineDustResult,
      envMaps: envMapResults,
      shelterMaps: shelterMapResults,
      errors: errors,
    );
  }

  /// 3. API 결과 처리 및 UI 데이터/컨트롤러 생성
  _ProcessedData _processApiResults(_ApiRawResults rawResults) {
    CurrentWeather? weatherDataUI;
    FeelsLikeData? feelsLikeDataUI;
    List<HealthIndex> healthIndicesUI = [];

    // 데이터 매핑 (주요 데이터 없으면 일부만 표시될 수 있음)
    if (rawResults.weather != null && rawResults.healthIndex != null) {
      weatherDataUI = DataMapper.mapWeatherResponseToUI(
        rawResults.weather!,
        rawResults.healthIndex!.region, // RegionInfo 전달
      );
      feelsLikeDataUI = DataMapper.mapFeelsLikeResponseToUI(
        rawResults.healthIndex!,
      );
      // HealthIndex 매핑 시 UV, FineDust 데이터도 함께 전달
      healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
        rawResults.healthIndex, // Nullable 전달
        rawResults.uv, // Nullable 전달
        rawResults.fineDust, // Nullable 전달
      );
    } else {
      // 날씨 또는 건강지수 핵심 데이터 로드 실패 시, 다른 데이터라도 매핑 시도
      // 예: UV, 미세먼지만이라도 표시하기 위함 (DataMapper 수정 필요할 수 있음)
      healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
        rawResults.healthIndex,
        rawResults.uv,
        rawResults.fineDust,
      );
      print(
        "Warning: Core weather or health index data is missing. Mapping partial data.",
      );
    }

    // WebView 컨트롤러 초기화
    final newEnvMapControllers = <String, WebViewController?>{};
    final newShelterMapControllers = <String, WebViewController?>{};
    _initializeWebViews(
      rawResults.envMaps,
      rawResults.shelterMaps,
      newEnvMapControllers,
      newShelterMapControllers,
    );

    // 오류 메시지 생성
    final String? finalErrorMessage = _handleApiErrors(rawResults.errors);

    return (
      weatherUI: weatherDataUI,
      feelsLikeUI: feelsLikeDataUI,
      healthIndicesUI: healthIndicesUI,
      envMapControllers: newEnvMapControllers,
      shelterMapControllers: newShelterMapControllers,
      errorMessage: finalErrorMessage,
    );
  }

  /// 4. API 호출 중 발생한 오류 목록을 최종 에러 메시지 문자열로 변환
  String? _handleApiErrors(List<dynamic> errors) {
    if (errors.isEmpty) return null;

    // TODO: 오류 메시지를 좀 더 사용자 친화적으로 만들거나, 특정 API 실패 정보를 명확히 표시
    return errors
        .map((e) {
          if (e is Exception) {
            // Exception 종류에 따라 다른 메시지 반환 가능
            return e.toString();
          } else if (e == null) {
            return '알 수 없는 API 응답 (null)';
          } else {
            return e.toString(); // 예상치 못한 타입
          }
        })
        .join('\n'); // 여러 오류 발생 시 줄바꿈으로 구분
  }

  /// WebView 컨트롤러 초기화 (기존 로직과 동일)
  void _initializeWebViews(
    Map<String, EnvMapApiResponse?> apiEnvMapData,
    Map<String, MapApiResponse?> apiShelterMapDataMap,
    Map<String, WebViewController?> envControllersTarget,
    Map<String, WebViewController?> shelterControllersTarget,
  ) {
    apiEnvMapData.forEach((type, mapData) {
      if (mapData?.envMapHtml != null && mapData!.envMapHtml!.isNotEmpty) {
        // HTML 비어있는지 체크 추가
        try {
          envControllersTarget[type] =
              WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadHtmlString(
                  mapData.envMapHtml!,
                  baseUrl: null,
                ); // baseUrl 필요시 설정
        } catch (e) {
          print("Error initializing Env WebView for $type: $e");
          envControllersTarget[type] = null;
        }
      } else {
        envControllersTarget[type] = null;
      }
    });
    apiShelterMapDataMap.forEach((type, mapData) {
      if (mapData?.shelterMapHtml != null &&
          mapData!.shelterMapHtml!.isNotEmpty) {
        try {
          shelterControllersTarget[type] =
              WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadHtmlString(mapData.shelterMapHtml!, baseUrl: null);
        } catch (e) {
          print("Error initializing Shelter WebView for $type: $e");
          shelterControllersTarget[type] = null;
        }
      } else {
        shelterControllersTarget[type] = null;
      }
    });
  }
} // End of Notifier class

// --- Provider 정의 (기존 코드 유지) ---
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

final mainScreenNotifierProvider =
    StateNotifierProvider<MainScreenNotifier, MainScreenState>((ref) {
      return MainScreenNotifier(
        ref.read(locationServiceProvider),
        ref.read(apiServiceProvider),
        ref.read(preferencesServiceProvider),
      );
    });
