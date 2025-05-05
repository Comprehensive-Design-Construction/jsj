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
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([_loadAddedPeople(), _loadVisibleIndicesFromPrefs()]);
    await loadDataForSelectedPerson();
    if (mounted) {
      await loadDataForSelectedPerson();
    }
  }

  Future<void> _loadAddedPeople() async {
    state = state.copyWith(isLoadingPeople: true);
    final people = await _prefsService.getAddedPeople();
    state = state.copyWith(addedPeopleList: people, isLoadingPeople: false);
    print("Loaded ${people.length} added people.");
  }

  Future<void> _loadVisibleIndicesFromPrefs() async {
    try {
      // 안전을 위해 try-catch 블록 추가
      final savedIndices = await _prefsService.getVisibleIndices();

      // <<<--- await 이후 Notifier가 여전히 mounted 상태인지 확인 --->>>
      if (!mounted) {
        // Notifier가 이미 dispose 되었다면 아무 작업도 하지 않고 함수 종료
        print(
          "Warning: MainScreenNotifier disposed before updating visible indices.",
        );
        return;
      }
      // <<<---------------------------------------------------->>>

      final initialVisible = savedIndices ?? availableHealthIndices.toSet();

      // 상태 업데이트 직전에 한 번 더 확인 (선택 사항이지만 더 안전)
      if (!mounted) return;

      // mounted 상태임이 확인되었으므로 안전하게 상태 업데이트
      state = state.copyWith(visibleIndices: initialVisible);
      print("Visible indices loaded: $initialVisible");
    } catch (e) {
      // SharedPreferences 로드 중 발생할 수 있는 오류 처리
      print("Error loading visible indices from preferences: $e");
      // 오류 발생 시에도 mounted 상태인지 확인 후 에러 상태 업데이트 가능
      if (mounted) {
        state = state.copyWith(errorMessage: "표시 지수 로드 중 오류 발생: $e");
        // 또는 오류 시 기본값으로 설정
        // state = state.copyWith(visibleIndices: availableHealthIndices.toSet());
      }
    }
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
    // 함수 시작 시점에서도 mounted 확인 (선택적이지만 안전)
    if (!mounted) return;

    // 상태 업데이트 전 mounted 확인
    if (!refresh) {
      if (!mounted) return; // 추가된 체크
      state = state.copyWith(isLoading: true);
    }
    if (!mounted) return; // 추가된 체크
    state = state.copyWith(errorMessage: null, clearErrorMessage: true);

    try {
      final params = await _determineApiParams();
      // await 이후 mounted 확인
      if (!mounted) return;

      final apiResults = await _fetchApiDataInParallel(params);
      // await 이후 mounted 확인
      if (!mounted) return;

      final _ProcessedData processedData = await _processApiResults(
        apiResults,
        params,
      );
      // await 이후 mounted 확인
      if (!mounted) return;

      // 최종 상태 업데이트 전 mounted 확인
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
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
      print("Data loaded for selected person.");
    } catch (e, stacktrace) {
      print('Error during data loading process: $e\n$stacktrace');
      // 에러 상태 업데이트 전 mounted 확인
      if (mounted) {
        state = state.copyWith(
          errorMessage: '데이터 로드 중 오류 발생: $e',
          isLoading: false,
        );
      }
    } finally {
      // 필요시 로딩 상태 정리 (이미 try 블록에서 처리되지만, 만약을 위해 추가 가능)
      // if (mounted && state.isLoading) {
      //   state = state.copyWith(isLoading: false);
      // }
    }
  }

  // --- Helper 함수들 ---

  /// 1. API 호출에 필요한 파라미터(위경도, 나이, 타입) 결정
  Future<_ApiParams> _determineApiParams() async {
    double? latitude;
    double? longitude;
    int? age;
    List<String>? userDiseases;
    String? userType;
    String? determinedErrorMessage;

    if (state.selectedPersonId == myInfoId) {
      try {
        // --- '내 정보' 처리 로직 ---
        final (myGu, myDong) = await _prefsService.getMyGuDong();
        if (myGu != null && myDong != null) {
          try {
            final coords = await _apiService.fetchCoordinates(myGu, myDong);
            latitude = coords.latitude;
            longitude = coords.longitude;
          } catch (e) {
            latitude = defaultLatitude;
            longitude = defaultLongitude;
            determinedErrorMessage =
                '저장된 지역($myGu $myDong)의 좌표를 찾을 수 없어 기본 위치로 조회합니다.';
          }
        } else {
          latitude = defaultLatitude;
          longitude = defaultLongitude;
          determinedErrorMessage = '기본 지역이 설정되지 않았습니다. 메뉴 > 내 정보 수정에서 설정해주세요.';
        }
        // 사용자 정보 로드
        age = await _prefsService.getUserAge();
        userDiseases = await _prefsService.getUserDiseases() ?? [];
        userType = await _prefsService.getUserType();
        print('Determined params for: MY INFO');
      } catch (e) {
        // '내 정보' 처리 중 오류 발생 시 fallback
        print('Error determining params for MY INFO: $e');
        latitude ??= defaultLatitude;
        longitude ??= defaultLongitude;
        // 오류 발생 시에도 값 할당 시도 (null일 수 있음)
        age ??= await _prefsService.getUserAge();
        userDiseases ??= await _prefsService.getUserDiseases() ?? [];
        userType ??= await _prefsService.getUserType();
        determinedErrorMessage = '내 정보 처리 중 오류 발생: $e';
      }
    } else {
      // --- 추가된 사람 처리 로직 ---
      final selectedPerson = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: 'Unknown'), // ID가 없는 기본 객체 반환
      );

      // selectedPerson이 유효한지 (ID가 있고, 위치 정보가 있는지) 확인
      if (selectedPerson.id.isNotEmpty &&
          selectedPerson.latitude != null &&
          selectedPerson.longitude != null) {
        // 유효한 경우, 해당 정보 사용
        latitude = selectedPerson.latitude;
        longitude = selectedPerson.longitude;
        age = selectedPerson.age;
        userDiseases = selectedPerson.diseases ?? [];
        userType = selectedPerson.workingType;
        print('Determined params for: ${selectedPerson.name}');
      } else {
        // 유효하지 않은 경우 (리스트에 없거나, 정보 부족) -> '내 정보' 기준으로 Fallback
        print(
          "Warning: Could not find valid AddedPerson data for ID: ${state.selectedPersonId}. Falling back to My Info/Defaults.",
        );
        age = await _prefsService.getUserAge(); // 내 정보 나이
        userDiseases =
            await _prefsService.getUserDiseases() ?? []; // 내 정보 기저 질환
        userType = await _prefsService.getUserType(); // 내 정보 근무 유형
        latitude = defaultLatitude; // 기본 위치
        longitude = defaultLongitude;
        determinedErrorMessage = "선택된 사용자 정보를 찾을 수 없어 기본 정보로 조회합니다.";
        // <<< throw Exception(...) 라인 삭제됨 >>>
      }
    }

    // 최종 위경도 null 체크
    if (latitude == null || longitude == null) {
      latitude = defaultLatitude;
      longitude = defaultLongitude;
      print(
        "Critical Error: Could not determine final coordinates, using default as last resort.",
      );
      determinedErrorMessage =
          determinedErrorMessage ?? '위치 정보를 최종 결정할 수 없어 기본 위치로 조회합니다.';
    }

    // 에러 메시지 상태 업데이트 (안전하게)
    if (determinedErrorMessage != null &&
        determinedErrorMessage != state.errorMessage) {
      Future.microtask(() {
        // Notifier가 dispose되지 않았을 경우에만 상태 업데이트
        if (mounted) {
          state = state.copyWith(errorMessage: determinedErrorMessage);
        }
      });
    }

    // <<< 불필요한 diseaseParam 생성 로직 삭제됨 >>>
    // final List<String> diseaseParam = (userType != null && userType != '없음') ? [userType] : [];

    // 최종 반환 (레코드 필드 이름 확인: diseases, userType)
    return (
      latitude: latitude!, // 위에서 null 아님을 보장
      longitude: longitude!, // 위에서 null 아님을 보장
      age: age,
      diseases: userDiseases, // 실제 기저 질환 목록
      userType: userType, // 실제 근무 유형
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
        disease: params.diseases,
        userType: params.userType,
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
  Future<_ProcessedData> _processApiResults(
    _ApiRawResults rawResults,
    _ApiParams apiParams,
  ) async {
    CurrentWeather? weatherDataUI;
    FeelsLikeData? feelsLikeDataUI;
    List<HealthIndex> healthIndicesUI = [];
    String? processingErrorMessage; // 여기서 발생한 에러 메시지

    // --- 현재 선택된 사용자의 성별 정보 가져오기 ---
    String? selectedGender;
    if (state.selectedPersonId == myInfoId) {
      selectedGender = await _prefsService.getUserGender(); // 저장된 내 정보 성별 로드
      // 저장된 성별이 없으면 기본값(male) 사용
      selectedGender ??= Gender.male;
    } else {
      final selectedPerson = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: 'Unknown'), // 오류 처리 개선 필요
      );
      selectedGender =
          selectedPerson.gender ?? Gender.male; // 추가된 사람의 성별 또는 기본값
    }
    // ---------------------------------------

    // 데이터 매핑 (주요 데이터 없으면 일부만 표시될 수 있음)
    if (rawResults.weather != null && rawResults.healthIndex != null) {
      try {
        weatherDataUI = DataMapper.mapWeatherResponseToUI(
          rawResults.weather!,
          rawResults.healthIndex!.region, // RegionInfo 전달
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
