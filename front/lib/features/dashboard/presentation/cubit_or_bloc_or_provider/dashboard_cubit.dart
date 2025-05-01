// lib/features/dashboard/presentation/cubit_or_bloc_or_provider/dashboard_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'dashboard_state.dart';
import '../../../../core/storage/user_profile_storage.dart';
import '../../../../services/location_service.dart'; // LocationService import
import '../../../../services/api_service.dart'; // ApiService import
import '../../../../models/user_profile.dart';
import '../../../../models/weather_data.dart'; // 모델 import
import '../../../../models/health_indices.dart'; // 모델 import
import 'dart:async'; // Future.wait 사용 위해

class DashboardCubit extends Cubit<DashboardState> {
  // 서비스 인스턴스 생성 (의존성 주입 프레임워크 사용 시 방식 변경 가능)
  final UserProfileStorage _profileStorage = UserProfileStorage();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  DashboardCubit() : super(DashboardLoading());

  Future<void> loadDashboardData() async {
    // 여러번 호출 방지 또는 새로고침 로직 추가 가능
    print("--- loadDashboardData ---");
    if (state is DashboardLoading && state != DashboardLoading())
      return; // 이미 로딩 중이면 무시

    emit(DashboardLoading()); // 로딩 상태 시작

    UserProfile? userProfile;
    Position? position;
    WeatherDetailResponse? weatherData;
    HealthIndexResponse? healthIndices;
    // TODO: 필요시 UV, 미세먼지 데이터 변수 추가

    try {
      // 1. 사용자 프로필 로드 (동시에 위치 정보 가져오기 시작 가능)
      final profileFuture = _profileStorage.loadUserProfile();
      final locationFuture = _locationService.getCurrentLocation();

      // 사용자 프로필 로드 완료 대기
      userProfile = await profileFuture;
      final int? age = userProfile?.age; // UserProfile 모델에 age getter 구현 가정
      final List<String> diseases = userProfile?.diseases ?? [];

      // 위치 정보 가져오기 완료 대기
      position = await locationFuture; // 위치 정보 가져오기 실패 시 예외 발생
      final double latitude = position.latitude;
      final double longitude = position.longitude;

      // 2. API 호출 (병렬 처리)
      print("Requesting Weather and Health Indices APIs..."); // 디버깅 로그
      final apiResults = await Future.wait([
        _apiService.getWeather(latitude, longitude),
        _apiService.getHealthIndices(latitude, longitude, age, diseases),
        // TODO: 필요시 _apiService.getRegionalUv, _apiService.getRegionalFineDust 호출 추가
      ]);

      // API 결과 확인 및 타입 캐스팅/모델 할당
      // Future.wait는 결과를 리스트로 반환
      if (apiResults[0] is WeatherDetailResponse) {
        weatherData = apiResults[0] as WeatherDetailResponse;
      } else {
        print("Weather data fetch returned unexpected type or error.");
        // 필요시 에러 처리
      }

      if (apiResults[1] is HealthIndexResponse) {
        healthIndices = apiResults[1] as HealthIndexResponse;
      } else {
        print("Health indices fetch returned unexpected type or error.");
        // 필요시 에러 처리
      }

      // TODO: '가장 위험한 지수' 식별 로직 (간단 버전)
      // - 현재는 정수 레벨(낮을수록 위험)만 비교
      // - 추후 문자열 등급 비교 및 우선순위 로직 추가 필요
      if (healthIndices?.indices != null) {
        _findHighestRiskIndex(healthIndices!.indices); // 상태 업데이트는 emit 내부에서
      }

      // 3. 성공 상태 전파
      print("Dashboard data loaded successfully."); // 디버깅 로그
      emit(
        DashboardLoadSuccess(
          userProfile: userProfile,
          weatherData: weatherData,
          healthIndices: healthIndices,
          // TODO: UV, 미세먼지 데이터, 최고 위험 지수 정보 전달
        ),
      );
    } on LocationServiceDisabledException catch (e) {
      print("Location service disabled: ${e.message}");
      emit(DashboardLoadFailure("위치 서비스가 비활성화되어 있습니다. 기기의 위치 설정을 확인해주세요."));
    } on LocationPermissionDeniedException catch (e) {
      print("Location permission denied: ${e.message}");
      emit(DashboardLoadFailure("위치 정보 접근 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요."));
    } on LocationPermissionDeniedForeverException catch (e) {
      print("Location permission denied forever: ${e.message}");
      emit(
        DashboardLoadFailure(
          "위치 정보 접근 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 직접 변경해야 합니다.",
        ),
      );
    } on ApiException catch (e) {
      // ApiService에서 발생시킨 예외 처리
      print("API Exception: ${e.message}");
      emit(DashboardLoadFailure("데이터를 불러오는 중 오류가 발생했습니다: ${e.message}"));
    } catch (e, stackTrace) {
      // 기타 예상치 못한 오류
      print("Unexpected error loading dashboard data: $e");
      print(stackTrace); // 스택 트레이스 출력 (디버깅용)
      emit(DashboardLoadFailure("알 수 없는 오류가 발생했습니다. 앱을 재시작하거나 나중에 다시 시도해주세요."));
    }
  }

  // 최고 위험 지수 식별 로직 (예시 - DashboardLoadSuccess 상태 내부에 포함시킬 수도 있음)
  void _findHighestRiskIndex(IndexCalculationResult indices) {
    int? highestRiskLevel = 5; // 가장 안전한 레벨로 초기화 (낮을수록 위험 가정)
    String? highestRiskIndexName; // 예시 이름 저장

    // 비교 가능한 정수 레벨들 (1: 매우높음 ~ 4: 낮음)
    final Map<String, int?> levelMap = {
      'ALI': indices.aliLevel,
      'Stroke': indices.strokeIndexLevel,
      'Cold': indices.coldIndexLevel,
      // TODO: 다른 지수들의 위험도 레벨(숫자) 추가 필요 (UV, FineDust, FoodPoisoning 등)
      // TODO: ApparentTempRiskStatus 문자열을 숫자로 변환하는 로직 필요
    };

    levelMap.forEach((name, level) {
      if (level != null && level < highestRiskLevel!) {
        highestRiskLevel = level;
        highestRiskIndexName = name;
      }
      // TODO: 동일 레벨 처리 (현재는 첫번째 것만 기록됨)
    });

    print(
      "Highest risk level found: $highestRiskLevel for index: $highestRiskIndexName",
    );
    // 이 정보를 DashboardLoadSuccess 상태에 추가하여 UI에서 사용할 수 있도록 함
    // 예: successState.copyWith(highestRiskIndexName: highestRiskIndexName)
  }
}
