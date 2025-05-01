// lib/features/dashboard/presentation/cubit_or_bloc_or_provider/dashboard_state.dart
import 'package:equatable/equatable.dart'; // 상태 비교를 위한 equatable 패키지 (선택적)
import '../../../../models/user_profile.dart'; // 사용자 프로필 모델
import '../../../../models/weather_data.dart'; // 날씨 모델 (API 응답 기반으로 생성 필요)
import '../../../../models/health_indices.dart'; // 건강 지수 모델 (API 응답 기반으로 생성 필요)

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

// 초기 상태 또는 로딩 중 상태
class DashboardLoading extends DashboardState {}

// 데이터 로드 성공 상태
class DashboardLoadSuccess extends DashboardState {
  final UserProfile? userProfile; // 로드된 사용자 프로필
  final WeatherDetailResponse? weatherData; // 로드된 날씨 데이터 (이전 단계 스키마)
  final HealthIndexResponse? healthIndices; // 로드된 건강 지수 데이터 (이전 단계 스키마)
  // TODO: 필요시 UV, 미세먼지 데이터 등 추가
  // TODO: '가장 위험한 지수' 정보 추가

  const DashboardLoadSuccess({
    this.userProfile,
    this.weatherData,
    this.healthIndices,
  });

  @override
  List<Object?> get props => [userProfile, weatherData, healthIndices];
}

// 데이터 로드 실패 상태
class DashboardLoadFailure extends DashboardState {
  final String errorMessage;

  const DashboardLoadFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
