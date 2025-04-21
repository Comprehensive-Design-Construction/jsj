import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/response/health_indices_response.dart';
import '../services/api_service.dart';
import 'location_provider.dart'; // 위치 정보 프로바이더 의존성
import 'user_profile_provider.dart'; // 사용자 프로필 프로바이더 의존성

part 'health_index_provider.g.dart';

// ApiService 인스턴스를 제공하는 프로바이더
@riverpod
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

// 건강 지수 데이터를 비동기적으로 가져오는 프로바이더
// 위치나 사용자 프로필이 변경되면 자동으로 다시 데이터를 가져옴 (Riverpod의 watch 기능)
@riverpod
Future<HealthIndicesResponse> healthIndexData(HealthIndexDataRef ref) async {
  // currentPositionProvider와 userProfileProvider를 watch
  // 이들의 상태가 변경되면 healthIndexDataProvider는 자동으로 재실행됨
  final position = await ref.watch(currentPositionProvider.future);
  final userProfile = ref.watch(userProfileProvider);
  // apiServiceProvider를 통해 ApiService 인스턴스 얻기
  final api = ref.watch(apiServiceProvider);

  print(
    "Fetching health index data for ${position.latitude}, ${position.longitude} with profile $userProfile",
  );

  // ApiService의 함수 호출하여 데이터 요청
  return api.getHealthIndices(
    latitude: position.latitude,
    longitude: position.longitude,
    age: userProfile.age,
    disease: userProfile.disease,
  );
}
