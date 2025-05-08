import 'package:equatable/equatable.dart'; // 상태 비교를 위한 패키지 (pubspec.yaml 추가 필요)
import 'package:flutter/material.dart'; // WebViewController 사용 위해 필요할 수 있음
// import 'package:geolocator/geolocator.dart'; // Position 타입
import 'package:webview_flutter/webview_flutter.dart'; // WebViewController

// UI 모델 import
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ui/current_weather.dart';
import '../../../data/models/ui/feels_like_data.dart';
import '../../../data/models/ui/health_index.dart';
import '../../../data/models/ui/hourly_weather_ui.dart'; // <<< 추가
import '../../../data/models/added_person.dart';

// 상태 클래스 (Equatable 상속하여 상태 변경 감지 용이하게)
@immutable // 불변 클래스임을 명시 (선택 사항)
class MainScreenState extends Equatable {
  // 로딩 및 에러 상태
  final bool isLoading;
  final bool isLoadingPeople;
  final String? errorMessage;

  // 사용자 및 사람 목록 상태
  final String selectedPersonId; // 'MY_INFO' 또는 AddedPerson.id
  final List<AddedPerson> addedPeopleList;
  final Set<String> visibleIndices; // 보이는 건강 지수 이름 Set

  // 마지막 로드 좌표 (기본 위치 확인용)
  final double? lastLoadedLatitude;
  final double? lastLoadedLongitude;

  // 표시될 데이터 (DataMapper를 통해 변환된 UI 모델)
  final CurrentWeather? weatherDataUI;
  final FeelsLikeData? feelsLikeDataUI;
  final List<HealthIndex> healthIndicesUI;
  final List<HourlyWeatherUI> hourlyWeatherDataUI; // <<< 추가

  // 지도 관련 상태
  final Map<String, WebViewController?> envMapControllers;
  final Map<String, WebViewController?> shelterMapControllers;
  final String selectedEnvMapType;
  final String selectedDisasterType;
  final bool didUserUseSimpleStart;

  // 생성자
  const MainScreenState({
    this.isLoading = true,
    this.isLoadingPeople = true,
    this.errorMessage,
    this.selectedPersonId = myInfoId, // 기본값 'MY_INFO'
    this.addedPeopleList = const [],
    this.visibleIndices = const {}, // 초기 빈 Set
    this.lastLoadedLatitude,
    this.lastLoadedLongitude,
    this.weatherDataUI,
    this.feelsLikeDataUI,
    this.healthIndicesUI = const [],
    this.hourlyWeatherDataUI = const [],
    this.envMapControllers = const {},
    this.shelterMapControllers = const {},
    this.selectedEnvMapType = 'fine_dust',
    this.selectedDisasterType = 'EARTHQUAKE',
    this.didUserUseSimpleStart = false, // 기본값 false
  });

  // 상태 복사 및 일부 값 변경을 위한 copyWith 메소드
  MainScreenState copyWith({
    bool? isLoading,
    bool? isLoadingPeople,
    String? errorMessage,
    bool clearErrorMessage = false, // 에러 메시지 명시적 초기화 옵션
    String? selectedPersonId,
    List<AddedPerson>? addedPeopleList,
    Set<String>? visibleIndices,
    double? lastLoadedLatitude,
    double? lastLoadedLongitude,
    CurrentWeather? weatherDataUI,
    FeelsLikeData? feelsLikeDataUI,
    List<HealthIndex>? healthIndicesUI,
    List<HourlyWeatherUI>? hourlyWeatherDataUI,
    Map<String, WebViewController?>? envMapControllers,
    Map<String, WebViewController?>? shelterMapControllers,
    String? selectedEnvMapType,
    String? selectedDisasterType,
    bool? didUserUseSimpleStart, // 추가
  }) {
    return MainScreenState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPeople: isLoadingPeople ?? this.isLoadingPeople,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      selectedPersonId: selectedPersonId ?? this.selectedPersonId,
      addedPeopleList: addedPeopleList ?? this.addedPeopleList,
      visibleIndices: visibleIndices ?? this.visibleIndices,
      lastLoadedLatitude: lastLoadedLatitude ?? this.lastLoadedLatitude,
      lastLoadedLongitude: lastLoadedLongitude ?? this.lastLoadedLongitude,
      weatherDataUI: weatherDataUI ?? this.weatherDataUI,
      feelsLikeDataUI: feelsLikeDataUI ?? this.feelsLikeDataUI,
      healthIndicesUI: healthIndicesUI ?? this.healthIndicesUI,
      hourlyWeatherDataUI:
          hourlyWeatherDataUI ?? this.hourlyWeatherDataUI, // <<< 추가
      envMapControllers: envMapControllers ?? this.envMapControllers,
      shelterMapControllers:
          shelterMapControllers ?? this.shelterMapControllers,
      selectedEnvMapType: selectedEnvMapType ?? this.selectedEnvMapType,
      selectedDisasterType: selectedDisasterType ?? this.selectedDisasterType,
      didUserUseSimpleStart:
          didUserUseSimpleStart ?? this.didUserUseSimpleStart, // 추가
    );
  }

  // Equatable을 위한 props 정의 (상태 비교에 사용)
  @override
  List<Object?> get props => [
    isLoading,
    isLoadingPeople,
    errorMessage,
    selectedPersonId,
    addedPeopleList,
    visibleIndices,
    lastLoadedLatitude,
    lastLoadedLongitude,
    weatherDataUI,
    feelsLikeDataUI,
    healthIndicesUI,
    hourlyWeatherDataUI,
    envMapControllers,
    shelterMapControllers,
    selectedEnvMapType,
    selectedDisasterType,
    didUserUseSimpleStart, // 추가
  ];
}
