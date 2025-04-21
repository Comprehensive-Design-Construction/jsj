import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/request/user_input.dart'; // UserInput 모델 import

part 'user_profile_provider.g.dart';

// 사용자 프로필 상태를 관리하는 StateNotifierProvider (Riverpod Generator 사용)
@riverpod
class UserProfile extends _$UserProfile {
  @override
  UserInput build() {
    // 초기 상태: 나이 없고, 질병 목록 비어 있음
    // TODO: 앱 재시작 시 유지하려면 SharedPreferences 등에서 로드하는 로직 추가
    return const UserInput(age: null, disease: []);
  }

  /// 프로필 정보 업데이트 (나이 또는 질병 목록)
  void updateProfile({int? age, List<String>? disease}) {
    // 현재 상태를 기반으로 새로운 상태 객체 생성
    state = UserInput(
      age: age ?? state.age, // 업데이트할 값이 없으면 기존 값 유지
      disease: disease ?? state.disease,
    );
    // TODO: SharedPreferences 등에 변경된 정보 저장하는 로직 추가
    print("사용자 프로필 업데이트됨: $state");
  }

  /// 프로필 정보 초기화
  void clearProfile() {
    state = const UserInput(age: null, disease: []);
    // TODO: SharedPreferences 등에서도 정보 삭제하는 로직 추가
    print("사용자 프로필 초기화됨");
  }
}
