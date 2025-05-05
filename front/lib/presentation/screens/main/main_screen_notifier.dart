import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart'; // 이제 직접 사용 안 함
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
// import '../../../data/services/location_service.dart'; // 이제 직접 사용 안 함

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
  // LocationService 제거
  // final LocationService _locationService;
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
    // this._locationService, // 제거
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

  /// 특정 사용자를 목록에서 삭제합니다. (ID 기준)
  Future<void> deletePerson(String personId) async {
    if (personId == myInfoId) {
      print("Cannot delete 'My Info'.");
      return;
    }
    try {
      await _prefsService.deletePerson(personId);
      print("Deleted person with ID: $personId");
      await refreshAddedPeople();
      if (state.selectedPersonId == personId) {
        print("Deleted person was selected. Switching to 'My Info'.");
        setSelectedPersonId(myInfoId);
      }
    } catch (e) {
      print("Error deleting person: $e");
      state = state.copyWith(errorMessage: "사용자 삭제 중 오류 발생: $e");
    }
  }

  // --- 데이터 로드 메인 함수 ---
  Future<void> loadDataForSelectedPerson({bool refresh = false}) async {
    if (!refresh) {
      state = state.copyWith(isLoading: true);
    }
    // 에러 메시지 초기화는 여기서 한 번만 수행
    state = state.copyWith(errorMessage: null, clearErrorMessage: true);

    try {
      final params = await _determineApiParams();
      final apiResults = await _fetchApiDataInParallel(params);
      final processedData = _processApiResults(apiResults);

      // 최종 상태 업데이트 (기존 errorMessage와 processedData.errorMessage 병합 또는 선택)
      // 여기서는 processedData.errorMessage 를 우선 사용
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            processedData.errorMessage ??
            state.errorMessage, // 기존 에러 유지 또는 새 에러 표시
        clearErrorMessage:
            processedData.errorMessage != null ||
            state.errorMessage == null, // 에러 메시지 유무에 따라 clear 설정
        weatherDataUI: processedData.weatherUI,
        feelsLikeDataUI: processedData.feelsLikeUI,
        healthIndicesUI: processedData.healthIndicesUI,
        envMapControllers: processedData.envMapControllers,
        shelterMapControllers: processedData.shelterMapControllers,
        lastLoadedLatitude: params.latitude,
        lastLoadedLongitude: params.longitude,
      );
      print("Data loaded for selected person.");
    } catch (e, stacktrace) {
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
    String? determinedErrorMessage; // 여기서 발생한 에러 메시지 임시 저장

    if (state.selectedPersonId == myInfoId) {
      try {
        // 저장된 '내 정보'의 구, 동 정보 가져오기
        final (myGu, myDong) = await _prefsService.getMyGuDong();

        if (myGu != null && myDong != null) {
          // 저장된 구/동 정보가 있으면 좌표 조회
          print('Using saved My Location: $myGu $myDong');
          try {
            final coords = await _apiService.fetchCoordinates(myGu, myDong);
            latitude = coords.latitude;
            longitude = coords.longitude;
          } catch (e) {
            print(
              'Failed to fetch coordinates for saved location ($myGu $myDong): $e. Using default.',
            );
            latitude = defaultLatitude;
            longitude = defaultLongitude;
            determinedErrorMessage =
                '저장된 지역($myGu $myDong)의 좌표를 찾을 수 없어 기본 위치로 조회합니다.'; // 에러 메시지 설정
          }
        } else {
          // 저장된 정보 없으면 기본값 사용 (예: 서울시청 좌표)
          print(
            'No saved My Location found. Using default location (Seoul City Hall).',
          );
          latitude = defaultLatitude; // app_constants.dart의 기본값
          longitude = defaultLongitude;
          // 사용자에게 지역 설정 유도 메시지 표시 (상태 업데이트는 loadDataForSelectedPerson 완료 후)
          determinedErrorMessage = '기본 지역이 설정되지 않았습니다. 메뉴 > 내 정보 수정에서 설정해주세요.';
        }

        // 사용자 정보(나이, 타입)는 기존대로 가져옴
        age = await _prefsService.getUserAge();
        userTypes = await _prefsService.getUserTypes() ?? [];
        print(
          'Determined params for: MY INFO (using specified or default location)',
        );
      } catch (e) {
        print('Error determining params for MY INFO: $e');
        // 예외 발생 시에도 기본값 사용 시도
        latitude ??= defaultLatitude;
        longitude ??= defaultLongitude;
        determinedErrorMessage = '내 정보 처리 중 오류 발생: $e'; // 에러 메시지 설정
      }
    } else {
      // 추가된 사람 선택 시 기존 로직 유지
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
        // 선택된 사람 정보 오류 시 에러 throw
        throw Exception("선택된 사람의 위치 정보가 유효하지 않습니다.");
      }
    }

    // 위경도 null 체크 강화 (모든 경로에서 위경도가 설정되도록 보장)
    if (latitude == null || longitude == null) {
      // 이 경우는 거의 발생하지 않아야 하지만, 방어 코드
      latitude = defaultLatitude;
      longitude = defaultLongitude;
      print(
        "Critical Error: Could not determine final coordinates, using default as last resort.",
      );
      determinedErrorMessage =
          determinedErrorMessage ?? '위치 정보를 최종 결정할 수 없어 기본 위치로 조회합니다.';
      // throw Exception("최종 위치 정보를 결정할 수 없습니다."); // 앱 중단 대신 기본값 사용
    }

    // _determineApiParams 에서 발생한 에러 메시지가 있으면 상태에 반영
    // loadDataForSelectedPerson 완료 시점에 반영되도록 Future.microtask 사용 고려 가능
    // 또는 여기서 바로 상태 업데이트 (주의: API 호출 전에 에러 메시지가 표시될 수 있음)
    if (determinedErrorMessage != null &&
        determinedErrorMessage != state.errorMessage) {
      // 비동기적으로 상태 업데이트 예약 (UI 빌드 사이클 간섭 방지)
      Future.microtask(
        () => state = state.copyWith(errorMessage: determinedErrorMessage),
      );
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
    WeatherDetailResponse? weatherResult;
    HealthIndexResponse? healthIndexResult;
    SingleRegionUvResponse? uvResult;
    SingleRegionFineDustResponse? fineDustResult;
    final envMapResults = <String, EnvMapApiResponse?>{};
    final shelterMapResults = <String, MapApiResponse?>{};
    final errors = <dynamic>[]; // 오류 저장 리스트

    // 각 API 호출을 개별 try-catch로 감싸서 실행
    try {
      weatherResult = await _apiService.fetchWeather(
        params.latitude,
        params.longitude,
      );
    } catch (e) {
      print('Failed to fetch weather: $e');
      errors.add(e); // 오류 리스트에 추가
    }

    try {
      healthIndexResult = await _apiService.fetchHealthIndex(
        params.latitude,
        params.longitude,
        age: params.age,
        disease: params.userTypes,
      );
    } catch (e) {
      print('Failed to fetch health index: $e');
      errors.add(e);
    }

    try {
      uvResult = await _apiService.fetchUv(params.latitude, params.longitude);
    } catch (e) {
      print('Failed to fetch UV: $e');
      errors.add(e);
    }

    try {
      fineDustResult = await _apiService.fetchFineDust(
        params.latitude,
        params.longitude,
      );
    } catch (e) {
      print('Failed to fetch fine dust: $e');
      errors.add(e);
    }

    // 환경 지도 병렬 호출 (기존 Future.wait 유지 또는 개별 호출)
    // 여기서는 병렬 호출 후 개별 결과 처리 예시
    final envMapFutures =
        _envMapTypes.keys.map((type) async {
          try {
            return MapEntry(type, await _apiService.fetchEnvMap(type));
          } catch (e) {
            print('Failed to fetch env map ($type): $e');
            errors.add(e);
            return MapEntry(type, null); // 에러 시 null 반환
          }
        }).toList();
    final envMapEntries = await Future.wait(envMapFutures);
    for (var entry in envMapEntries) {
      envMapResults[entry.key] = entry.value;
    }

    // 대피소 지도 병렬 호출
    final shelterMapFutures =
        _disasterTypes.keys.map((type) async {
          try {
            return MapEntry(
              type,
              await _apiService.fetchShelterMap(
                params.latitude,
                params.longitude,
                type,
              ),
            );
          } catch (e) {
            print('Failed to fetch shelter map ($type): $e');
            errors.add(e);
            return MapEntry(type, null);
          }
        }).toList();
    final shelterMapEntries = await Future.wait(shelterMapFutures);
    for (var entry in shelterMapEntries) {
      shelterMapResults[entry.key] = entry.value;
    }

    return (
      weather: weatherResult,
      healthIndex: healthIndexResult,
      uv: uvResult,
      fineDust: fineDustResult,
      envMaps: envMapResults,
      shelterMaps: shelterMapResults,
      errors: errors, // 수집된 오류 목록 반환
    );
  }

  /// 3. API 결과 처리 및 UI 데이터/컨트롤러 생성
  _ProcessedData _processApiResults(_ApiRawResults rawResults) {
    CurrentWeather? weatherDataUI;
    FeelsLikeData? feelsLikeDataUI;
    List<HealthIndex> healthIndicesUI = [];
    String? processingErrorMessage; // 여기서 발생한 에러 메시지

    // 데이터 매핑 (주요 데이터 없으면 일부만 표시될 수 있음)
    if (rawResults.weather != null && rawResults.healthIndex != null) {
      try {
        weatherDataUI = DataMapper.mapWeatherResponseToUI(
          rawResults.weather!,
          rawResults.healthIndex!.region, // RegionInfo 전달
        );
      } catch (e) {
        print("Error mapping weather data: $e");
        processingErrorMessage =
            (processingErrorMessage ?? "") + "날씨 정보 처리 오류\n";
      }
      try {
        feelsLikeDataUI = DataMapper.mapFeelsLikeResponseToUI(
          rawResults.healthIndex!,
        );
      } catch (e) {
        print("Error mapping feels like data: $e");
        processingErrorMessage =
            (processingErrorMessage ?? "") + "체감온도 정보 처리 오류\n";
      }
      try {
        // HealthIndex 매핑 시 UV, FineDust 데이터도 함께 전달
        healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
          rawResults.healthIndex, // Nullable 전달
          rawResults.uv, // Nullable 전달
          rawResults.fineDust, // Nullable 전달
        );
      } catch (e) {
        print("Error mapping health indices: $e");
        processingErrorMessage =
            (processingErrorMessage ?? "") + "건강지수 정보 처리 오류\n";
      }
    } else {
      // 날씨 또는 건강지수 핵심 데이터 로드 실패 시, 다른 데이터라도 매핑 시도
      try {
        healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
          rawResults.healthIndex,
          rawResults.uv,
          rawResults.fineDust,
        );
      } catch (e) {
        print("Error mapping partial health indices: $e");
        processingErrorMessage =
            (processingErrorMessage ?? "") + "부분 건강지수 정보 처리 오류\n";
      }
      print(
        "Warning: Core weather or health index data is missing. Mapping partial data.",
      );
      // 핵심 데이터 누락 시 에러 메시지 추가
      processingErrorMessage =
          (processingErrorMessage ?? "") + "날씨 또는 핵심 건강지수 로드 실패\n";
    }

    // WebView 컨트롤러 초기화
    final newEnvMapControllers = <String, WebViewController?>{};
    final newShelterMapControllers = <String, WebViewController?>{};
    try {
      _initializeWebViews(
        rawResults.envMaps,
        rawResults.shelterMaps,
        newEnvMapControllers,
        newShelterMapControllers,
      );
    } catch (e) {
      print("Error initializing webviews: $e");
      processingErrorMessage = (processingErrorMessage ?? "") + "지도 초기화 오류\n";
    }

    // API 호출 오류 메시지 결합
    final String? apiErrorMessage = _handleApiErrors(rawResults.errors);
    final String? finalErrorMessage =
        [apiErrorMessage, processingErrorMessage]
            .where((msg) => msg != null && msg.isNotEmpty)
            .join(); // null과 빈 문자열 제외하고 합침

    return (
      weatherUI: weatherDataUI,
      feelsLikeUI: feelsLikeDataUI,
      healthIndicesUI: healthIndicesUI,
      envMapControllers: newEnvMapControllers,
      shelterMapControllers: newShelterMapControllers,
      errorMessage: finalErrorMessage?.trim(), // 양 끝 공백 제거
    );
  }

  /// 4. API 호출 중 발생한 오류 목록(null 리스트)을 최종 에러 메시지 문자열로 변환
  String? _handleApiErrors(List<dynamic> errors) {
    if (errors.isEmpty) return null;

    // 각 에러 객체를 문자열로 변환하여 결합
    return errors
        .map((e) {
          if (e is Exception) {
            // Exception 종류에 따라 다른 메시지 반환 가능
            // 예: if (e is TimeoutException) return 'API 요청 시간 초과';
            return e.toString();
          } else {
            return e?.toString() ?? '알 수 없는 오류'; // 예상치 못한 타입 처리
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
                  baseUrl: null, // baseUrl 필요시 설정
                );
        } catch (e) {
          print("Error initializing Env WebView for $type: $e");
          envControllersTarget[type] = null;
        }
      } else {
        print("Env map HTML is null or empty for type: $type"); // 로그 추가
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
        print("Shelter map HTML is null or empty for type: $type"); // 로그 추가
        shelterControllersTarget[type] = null;
      }
    });
  }
} // End of Notifier class

// --- Provider 정의 ---
// LocationService Provider 제거
// final locationServiceProvider = Provider<LocationService>(
//   (ref) => LocationService(),
// );
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

final mainScreenNotifierProvider =
    StateNotifierProvider<MainScreenNotifier, MainScreenState>((ref) {
      return MainScreenNotifier(
        // ref.read(locationServiceProvider), // 제거
        ref.read(apiServiceProvider),
        ref.read(preferencesServiceProvider),
      );
    });
