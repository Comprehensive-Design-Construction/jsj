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
    ({
      double latitude,
      double longitude,
      int? age,
      List<String>? diseases,
      String? userType, // <<< 사용자 근무 유형 필드 다시 추가
    });

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
    print('[MainScreenNotifier] Created.');
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    print('[MainScreenNotifier] Initializing screen...');
    await Future.wait([_loadAddedPeople(), _loadVisibleIndicesFromPrefs()]);
    if (!mounted) return;
    print(
      '[MainScreenNotifier] Initial setup complete. Loading data for selected person.',
    );
    await loadDataForSelectedPerson(); // 이 호출 전후에 로그 추가
    print('[MainScreenNotifier] Initial data load complete.');
  }

  Future<void> _loadAddedPeople() async {
    // 상태 업데이트 전에 로딩 상태를 true로 설정 (선택적)
    // state = state.copyWith(isLoadingPeople: true);

    try {
      final people = await _prefsService.getAddedPeople();

      // `mounted` 확인: SharedPreferences 작업 후 Notifier가 활성 상태인지 확인
      if (!mounted) return;

      state = state.copyWith(addedPeopleList: people, isLoadingPeople: false);
      print("Loaded ${people.length} added people.");
    } catch (e) {
      print("Error loading added people: $e");
      // `mounted` 확인: 에러 발생 및 상태 업데이트 전 Notifier 활성 상태 확인
      if (!mounted) return;
      state = state.copyWith(
        isLoadingPeople: false,
        errorMessage: "등록된 사용자 목록 로드 실패: $e",
      );
    }
  }

  Future<void> _loadVisibleIndicesFromPrefs() async {
    try {
      final savedIndices = await _prefsService.getVisibleIndices();

      // `mounted` 확인: SharedPreferences 작업 후 Notifier가 활성 상태인지 확인
      if (!mounted) {
        print(
          "Warning: MainScreenNotifier disposed before updating visible indices.",
        );
        return;
      }

      final initialVisible = savedIndices ?? availableHealthIndices.toSet();

      // 상태 업데이트 직전에 한 번 더 확인 (더 안전)
      if (!mounted) return;
      state = state.copyWith(visibleIndices: initialVisible);
      print("Visible indices loaded: $initialVisible");
    } catch (e) {
      print("Error loading visible indices from preferences: $e");
      // `mounted` 확인: 에러 발생 및 상태 업데이트 전 Notifier 활성 상태 확인
      if (mounted) {
        state = state.copyWith(errorMessage: "표시 지수 로드 중 오류 발생: $e");
      }
    }
  }

  Future<void> reloadVisibleIndices() async {
    // 이 함수는 MenuScreen에서 돌아올 때 호출될 수 있으므로 로딩 상태 관리가 필요 없을 수 있음
    await _loadVisibleIndicesFromPrefs();
  }

  Future<void> refreshAddedPeople() async {
    await _loadAddedPeople();
  }

  void setSelectedPersonId(String personId) {
    if (personId != state.selectedPersonId) {
      state = state.copyWith(selectedPersonId: personId);
      // 선택된 사람이 변경되면 데이터 새로고침
      loadDataForSelectedPerson(refresh: true);
    }
  }

  void setSelectedEnvMapType(String mapType) {
    if (!mounted) return; // 상태 변경 전 확인
    state = state.copyWith(selectedEnvMapType: mapType);
  }

  void setSelectedDisasterType(String mapType) {
    if (!mounted) return; // 상태 변경 전 확인
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

      // `mounted` 확인: SharedPreferences 작업 후
      if (!mounted) return;

      print("Deleted person with ID: $personId");
      await refreshAddedPeople(); // 목록 갱신

      // `mounted` 확인: refreshAddedPeople (내부 await 포함) 후
      if (!mounted) return;

      // 삭제된 사용자가 현재 선택된 사용자였다면 '내 정보'로 전환
      if (state.selectedPersonId == personId) {
        print("Deleted person was selected. Switching to 'My Info'.");
        // setSelectedPersonId 내부에서 데이터 로딩 시작됨
        setSelectedPersonId(myInfoId);
      }
    } catch (e) {
      print("Error deleting person: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(errorMessage: "사용자 삭제 중 오류 발생: $e");
    }
  }

  // --- 데이터 로드 메인 함수 ---
  Future<void> loadDataForSelectedPerson({bool refresh = false}) async {
    if (!mounted) return;
    print(
      '[MainScreenNotifier] loadDataForSelectedPerson called (refresh: $refresh). selectedPersonId: ${state.selectedPersonId}',
    );
    if (!refresh) {
      state = state.copyWith(isLoading: true); // 이 부분 전후에 로그 추가
      print('[MainScreenNotifier] loadData: isLoading = true (not refresh)');
    }
    state = state.copyWith(errorMessage: null, clearErrorMessage: true);
    print('[MainScreenNotifier] loadData: Error message cleared.');

    try {
      print('[MainScreenNotifier] loadData: Determining API params...');
      final params = await _determineApiParams(); // 이 호출 전후에 로그 추가
      print('[MainScreenNotifier] loadData: API params determined: $params');
      if (!mounted) return;

      print('[MainScreenNotifier] loadData: Fetching API data in parallel...');
      final apiResults = await _fetchApiDataInParallel(
        params,
      ); // 이 호출 전후에 로그 추가
      print('[MainScreenNotifier] loadData: API data fetch complete.');
      if (!mounted) return;

      print('[MainScreenNotifier] loadData: Processing API results...');
      final _ProcessedData processedData = await _processApiResults(
        apiResults,
        params,
      ); // 이 호출 전후에 로그 추가
      print(
        '[MainScreenNotifier] loadData: API results processed. errorMessage: ${processedData.errorMessage}',
      );
      if (!mounted) return;

      print('[MainScreenNotifier] loadData: Final state update...');
      state = state.copyWith(
        isLoading: false, // 이 부분 전후에 로그 추가
        errorMessage: processedData.errorMessage ?? state.errorMessage,
        clearErrorMessage:
            processedData.errorMessage != null || state.errorMessage == null,
        weatherDataUI: processedData.weatherUI,
        feelsLikeDataUI: processedData.feelsLikeUI,
        healthIndicesUI: processedData.healthIndicesUI,
        envMapControllers: processedData.envMapControllers,
        shelterMapControllers: processedData.shelterMapControllers,
        lastLoadedLatitude: params.latitude,
        lastLoadedLongitude: params.longitude,
      );
      print(
        '[MainScreenNotifier] loadData: Final state updated. isLoading=false',
      );
    } catch (e, stacktrace) {
      print(
        '[MainScreenNotifier] Error during data loading process: $e\n$stacktrace',
      );
      if (mounted) {
        state = state.copyWith(
          errorMessage: '데이터 로드 중 오류 발생: $e',
          isLoading: false,
        ); // 이 부분 전후에 로그 추가
        print(
          '[MainScreenNotifier] loadData: Error state updated. isLoading=false',
        );
      }
    }
  }

  // --- Helper 함수들 ---

  /// 1. API 호출에 필요한 파라미터(위경도, 나이, 타입) 결정
  Future<_ApiParams> _determineApiParams() async {
    print('[MainScreenNotifier] _determineApiParams started.');

    double? latitude;
    double? longitude;
    int? age;
    List<String>? userDiseases;
    String? userType;
    String? determinedErrorMessage;

    if (state.selectedPersonId == myInfoId) {
      try {
        final (myGu, myDong) = await _prefsService.getMyGuDong();
        // <<< 로그 추가 >>>
        print(
          "[_determineApiParams] Loaded My Location: gu=$myGu, dong=$myDong",
        );
        print('[_determineApiParams] Calling getUserGender...');
        final savedGender = await _prefsService.getUserGender();
        print(
          '[_determineApiParams] Received from getUserGender: $savedGender',
        );

        if (myGu != null && myDong != null) {
          try {
            // <<< 로그 추가 >>>
            print(
              "[_determineApiParams] Fetching coordinates for My Location: $myGu, $myDong",
            );
            final coords = await _apiService.fetchCoordinates(myGu, myDong);
            latitude = coords.latitude;
            longitude = coords.longitude;
            // <<< 로그 추가 >>>
            print(
              "[_determineApiParams] Fetched coordinates: lat=$latitude, lon=$longitude",
            );
          } catch (e) {
            // <<< 로그 추가 >>>
            print(
              "[_determineApiParams] Failed to fetch coordinates for My Location: $e",
            );
            // <<< 중요: 여기서 바로 기본 좌표 설정 제거! >>>
            // latitude = defaultLatitude;
            // longitude = defaultLongitude;
            determinedErrorMessage =
                '저장된 지역($myGu $myDong)의 좌표 조회 실패'; // 오류 메시지만 설정
          }
        } else {
          // <<< 로그 추가 >>>
          print("[_determineApiParams] My Location (Gu/Dong) not set.");
          determinedErrorMessage = '기본 지역이 설정되지 않았습니다. 메뉴 > 내 정보 수정에서 설정해주세요.';
          // <<< 중요: 여기서 바로 기본 좌표 설정 제거! >>>
        }
        // ... (나이, 질병, 타입 로드 - 기존 코드 유지) ...
        age = await _prefsService.getUserAge();
        userDiseases = await _prefsService.getUserDiseases() ?? [];
        userType = await _prefsService.getUserType();
        print(
          '[_determineApiParams] Loaded user info (age, diseases, type): age=$age, diseases=$userDiseases, type=$userType',
        );
      } catch (e) {
        // getMyGuDong 등 다른 SharedPreferences 오류 처리
        print('Error determining params for MY INFO (outer try): $e');
        determinedErrorMessage = '내 정보 처리 중 오류 발생: $e';
        // 필요한 경우 여기서도 기본 사용자 정보 로드 시도 (기존 로직 유지)
      }
    } else {
      // 추가된 사용자 처리 로직 (기존과 동일, 필요시 유사 로그 추가)
      final selectedPerson = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: 'Unknown'),
      );

      if (selectedPerson.id.isNotEmpty &&
          selectedPerson.latitude != null && // <<< 추가된 사람은 좌표 직접 사용 >>>
          selectedPerson.longitude != null) {
        latitude = selectedPerson.latitude;
        longitude = selectedPerson.longitude;
        age = selectedPerson.age;
        userDiseases = selectedPerson.diseases ?? [];
        userType = selectedPerson.workingType;
        print(
          'Determined params for Added Person: ${selectedPerson.name} (using saved coords)',
        );
      } else {
        // 추가된 사람 정보가 부적절하거나 좌표가 없는 경우 Fallback (My Info/Defaults 사용)
        print(
          "Warning: Could not find valid AddedPerson data or coords for ID: ${state.selectedPersonId}. Falling back to My Info/Defaults.",
        );
        determinedErrorMessage = "선택된 사용자 정보를 찾을 수 없어 기본 정보로 조회합니다.";
        // My Info 기준 데이터 다시 로드 (age, diseases, userType) - 필요시 추가
        try {
          age = await _prefsService.getUserAge();
          userDiseases = await _prefsService.getUserDiseases() ?? [];
          userType = await _prefsService.getUserType();
        } catch (fallbackError) {
          print(
            "Error during AddedPerson fallback preference access: $fallbackError",
          );
        }
        // <<< 중요: 여기서 바로 기본 좌표 설정 제거! >>>
      }
    }

    // --- 최종 좌표 Fallback 로직 ---
    if (latitude == null || longitude == null) {
      // <<< 로그 추가 >>>
      print(
        "[_determineApiParams] Coordinates are null, triggering final fallback to default coordinates.",
      );
      latitude = defaultLatitude;
      longitude = defaultLongitude;
      // 오류 메시지 업데이트 (기존 메시지에 덧붙이거나 새로 설정)
      if (determinedErrorMessage == null || determinedErrorMessage.isEmpty) {
        determinedErrorMessage = '위치 좌표를 결정할 수 없어 기본 위치로 조회합니다.';
      } else if (!determinedErrorMessage.contains('기본 위치')) {
        // 기존 오류 메시지가 있고 '기본 위치' 언급이 없다면 추가
        determinedErrorMessage +=
            '\n기본 위치(${defaultLatitude.toStringAsFixed(4)}, ${defaultLongitude.toStringAsFixed(4)})로 조회합니다.';
      }
    }
    // --- --------------------- ---

    // 에러 메시지 상태 업데이트 (기존 microtask 방식 유지)
    if (determinedErrorMessage != null &&
        determinedErrorMessage != state.errorMessage) {
      Future.microtask(() {
        if (mounted) {
          // 여기에 mounted 체크 추가
          state = state.copyWith(errorMessage: determinedErrorMessage);
          print('[_determineApiParams] Microtask updated state with error.');
        } else {
          print(
            '[_determineApiParams] Microtask tried to update state but Notifier is not mounted.',
          );
        }
      });
    }

    return (
      latitude: latitude!, // 이제 non-null 보장
      longitude: longitude!, // 이제 non-null 보장
      age: age,
      diseases: userDiseases,
      userType: userType,
    );
  }

  /// 2. 결정된 파라미터로 필요한 API 병렬 호출
  Future<_ApiRawResults> _fetchApiDataInParallel(_ApiParams params) async {
    // 이 함수는 API 호출만 수행하고 상태를 변경하지 않으므로 mounted 체크 불필요
    WeatherDetailResponse? weatherResult;
    HealthIndexResponse? healthIndexResult;
    SingleRegionUvResponse? uvResult;
    SingleRegionFineDustResponse? fineDustResult;
    final envMapResults = <String, EnvMapApiResponse?>{};
    final shelterMapResults = <String, MapApiResponse?>{};
    final errors = <dynamic>[];

    // 병렬 호출 시작
    final futures = <Future>[
      // Weather
      Future(() async {
        try {
          weatherResult = await _apiService.fetchWeather(
            params.latitude,
            params.longitude,
          );
        } catch (e) {
          print('Failed to fetch weather: $e');
          errors.add(e);
        }
      }),
      // Health Index
      Future(() async {
        try {
          healthIndexResult = await _apiService.fetchHealthIndex(
            params.latitude,
            params.longitude,
            age: params.age,
            disease: params.diseases,
            userType: params.userType,
          );
        } catch (e) {
          print('Failed to fetch health index: $e');
          errors.add(e);
        }
      }),
      // UV
      Future(() async {
        try {
          uvResult = await _apiService.fetchUv(
            params.latitude,
            params.longitude,
          );
        } catch (e) {
          print('Failed to fetch UV: $e');
          errors.add(e);
        }
      }),
      // Fine Dust
      Future(() async {
        try {
          fineDustResult = await _apiService.fetchFineDust(
            params.latitude,
            params.longitude,
          );
        } catch (e) {
          print('Failed to fetch fine dust: $e');
          errors.add(e);
        }
      }),
      // Env Maps
      ..._envMapTypes.keys.map(
        (type) => Future(() async {
          try {
            envMapResults[type] = await _apiService.fetchEnvMap(type);
          } catch (e) {
            print('Failed to fetch env map ($type): $e');
            errors.add(e);
            envMapResults[type] = null;
          }
        }),
      ),
      // Shelter Maps
      ..._disasterTypes.keys.map(
        (type) => Future(() async {
          try {
            shelterMapResults[type] = await _apiService.fetchShelterMap(
              params.latitude,
              params.longitude,
              type,
            );
          } catch (e) {
            print('Failed to fetch shelter map ($type): $e');
            errors.add(e);
            shelterMapResults[type] = null;
          }
        }),
      ),
    ];

    // 모든 API 호출 완료 대기
    await Future.wait(futures);

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
  Future<_ProcessedData> _processApiResults(
    _ApiRawResults rawResults,
    _ApiParams apiParams,
  ) async {
    // 이 함수 내의 SharedPreferences 접근에 await이 있으므로 mounted 체크 필요

    CurrentWeather? weatherDataUI;
    FeelsLikeData? feelsLikeDataUI;
    List<HealthIndex> healthIndicesUI = [];
    String? processingErrorMessage;

    String? selectedGender;
    try {
      if (state.selectedPersonId == myInfoId) {
        selectedGender = await _prefsService.getUserGender();
        if (!mounted)
          throw Exception("Notifier disposed during result processing (1)");
        selectedGender ??= Gender.male;
      } else {
        // 추가된 사람 정보 접근 (상태에서 직접 접근 - await 없음)
        final selectedPerson = state.addedPeopleList.firstWhere(
          (p) => p.id == state.selectedPersonId,
          orElse:
              () => AddedPerson(id: '', name: 'Unknown', gender: Gender.male),
        );
        selectedGender = selectedPerson.gender ?? Gender.male;
      }
    } catch (e) {
      print("Error getting gender info: $e");
      selectedGender = Gender.male; // Fallback
      processingErrorMessage = (processingErrorMessage ?? "") + "성별 정보 로드 오류\n";
    }

    // 데이터 매핑 (주요 데이터 없으면 일부만 표시될 수 있음)
    if (rawResults.weather != null && rawResults.healthIndex != null) {
      try {
        weatherDataUI = DataMapper.mapWeatherResponseToUI(
          rawResults.weather!,
          rawResults.healthIndex!.region,
          selectedGender,
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
        healthIndicesUI = DataMapper.mapHealthIndicesResponseToUI(
          rawResults.healthIndex,
          rawResults.uv,
          rawResults.fineDust,
        );
      } catch (e) {
        print("Error mapping health indices: $e");
        processingErrorMessage =
            (processingErrorMessage ?? "") + "건강지수 정보 처리 오류\n";
      }
    } else {
      // 핵심 데이터 누락 시에도 부분 매핑 시도
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
      processingErrorMessage =
          (processingErrorMessage ?? "") + "날씨 또는 핵심 건강지수 로드 실패\n";
    }

    // WebView 컨트롤러 초기화 (동기 작업이므로 mounted 체크 불필요)
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
        [
          apiErrorMessage,
          processingErrorMessage,
        ].where((msg) => msg != null && msg.isNotEmpty).join();

    return (
      weatherUI: weatherDataUI,
      feelsLikeUI: feelsLikeDataUI,
      healthIndicesUI: healthIndicesUI,
      envMapControllers: newEnvMapControllers,
      shelterMapControllers: newShelterMapControllers,
      errorMessage: finalErrorMessage?.trim(),
    );
  }

  /// 4. API 호출 중 발생한 오류 목록을 최종 에러 메시지 문자열로 변환
  String? _handleApiErrors(List<dynamic> errors) {
    // 이 함수는 동기적이므로 mounted 체크 불필요
    if (errors.isEmpty) return null;
    return errors.map((e) => e?.toString() ?? '알 수 없는 API 오류').join('\n');
  }

  /// WebView 컨트롤러 초기화
  void _initializeWebViews(
    Map<String, EnvMapApiResponse?> apiEnvMapData,
    Map<String, MapApiResponse?> apiShelterMapDataMap,
    Map<String, WebViewController?> envControllersTarget,
    Map<String, WebViewController?> shelterControllersTarget,
  ) {
    // 이 함수는 동기적이므로 mounted 체크 불필요
    apiEnvMapData.forEach((type, mapData) {
      if (mapData?.envMapHtml != null && mapData!.envMapHtml!.isNotEmpty) {
        try {
          envControllersTarget[type] =
              WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadHtmlString(mapData.envMapHtml!, baseUrl: null);
        } catch (e) {
          print("Error initializing Env WebView for $type: $e");
          envControllersTarget[type] = null;
        }
      } else {
        print("Env map HTML is null or empty for type: $type");
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
        print("Shelter map HTML is null or empty for type: $type");
        shelterControllersTarget[type] = null;
      }
    });
  }
} // End of Notifier class

// --- Provider 정의 ---
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

final mainScreenNotifierProvider =
    StateNotifierProvider<MainScreenNotifier, MainScreenState>((ref) {
      return MainScreenNotifier(
        ref.read(apiServiceProvider),
        ref.read(preferencesServiceProvider),
      );
    });
