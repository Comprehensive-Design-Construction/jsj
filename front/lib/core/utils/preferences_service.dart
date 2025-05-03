import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/added_person.dart';

class PreferencesService {
  // SharedPreferences 키 정의
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _userAgeKey = 'user_age';
  static const String _userTypesKey = 'user_types'; // 사용자 특성 (disease 파라미터용)
  static const String _visibleIndicesKey = 'visible_health_indices';
  static const String _addedPeopleKey = 'added_people_list'; // 추가된 사람 목록 키

  // SharedPreferences 인스턴스 가져오기
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // 온보딩 완료 여부 확인
  Future<bool> isOnboardingComplete() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  // 온보딩 완료 처리
  Future<void> setOnboardingComplete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  // 사용자 정보 저장 (나이, 특성 리스트)
  Future<void> saveUserInfo({int? age, List<String>? userTypes}) async {
    final prefs = await _getPrefs();
    if (age != null) {
      await prefs.setInt(_userAgeKey, age);
    } else {
      await prefs.remove(_userAgeKey); // null이면 삭제
    }
    if (userTypes != null) {
      await prefs.setStringList(_userTypesKey, userTypes);
    } else {
      await prefs.remove(_userTypesKey); // null이면 삭제
    }
    print('Saved User Info: age=$age, types=$userTypes'); // 저장 확인 로그
  }

  // 사용자 나이 불러오기
  Future<int?> getUserAge() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_userAgeKey); // 저장된 값 없으면 null 반환
  }

  // 사용자 특성 리스트 불러오기 (disease 파라미터용)
  Future<List<String>?> getUserTypes() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_userTypesKey); // 저장된 값 없으면 null 반환
  }

  // (참고) 모든 저장된 정보 삭제 (테스트용)
  Future<void> clearAllPreferences() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    print("All preferences cleared.");
  }

  // 보이는 건강 지수 목록 저장/로드
  Future<void> saveVisibleIndices(Set<String> visibleIndices) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_visibleIndicesKey, visibleIndices.toList());
    print("저장된 보이는 지수: ${visibleIndices.toList()}");
  }

  /// 저장된 보이는 건강 지수 이름 목록(Set)을 불러옵니다.
  /// 저장된 값이 없으면 null을 반환합니다.
  Future<Set<String>?> getVisibleIndices() async {
    final prefs = await _getPrefs();
    final List<String>? list = prefs.getStringList(_visibleIndicesKey);
    if (list != null) {
      // List를 Set으로 변환하여 반환
      return list.toSet();
    }
    return null; // 저장된 값 없음
  }

  /// 추가된 사람 목록 전체를 불러옵니다.
  Future<List<AddedPerson>> getAddedPeople() async {
    final prefs = await _getPrefs();
    final List<String>? jsonStringList = prefs.getStringList(_addedPeopleKey);

    if (jsonStringList == null) {
      return []; // 저장된 목록 없으면 빈 리스트 반환
    }

    try {
      // JSON 문자열 리스트를 AddedPerson 객체 리스트로 변환
      return jsonStringList
          .map((jsonString) => AddedPerson.fromJson(jsonDecode(jsonString)))
          .toList();
    } catch (e) {
      print("Error decoding added people list: $e");
      return []; // 디코딩 오류 시 빈 리스트 반환
    }
  }

  /// 추가된 사람 목록 전체를 저장합니다. (기존 목록 덮어쓰기)
  Future<void> saveAddedPeople(List<AddedPerson> people) async {
    final prefs = await _getPrefs();
    // AddedPerson 객체 리스트를 JSON 문자열 리스트로 변환
    final List<String> jsonStringList =
        people.map((person) => jsonEncode(person.toJson())).toList();
    await prefs.setStringList(_addedPeopleKey, jsonStringList);
    print("Saved Added People: ${people.length} items");
  }

  /// 새 사람을 목록에 추가합니다.
  Future<void> addPerson(AddedPerson person) async {
    final List<AddedPerson> currentList = await getAddedPeople();
    // ID 중복 체크 (선택 사항)
    if (currentList.any((p) => p.id == person.id)) {
      print("Person with ID ${person.id} already exists. Not adding.");
      return; // 또는 업데이트 로직
    }
    currentList.add(person);
    await saveAddedPeople(currentList);
  }

  /// 특정 사람 정보를 업데이트합니다. (ID 기준)
  Future<void> updatePerson(AddedPerson updatedPerson) async {
    final List<AddedPerson> currentList = await getAddedPeople();
    final index = currentList.indexWhere((p) => p.id == updatedPerson.id);
    if (index != -1) {
      currentList[index] = updatedPerson;
      await saveAddedPeople(currentList);
      print("Updated person: ${updatedPerson.name}");
    } else {
      print("Person with ID ${updatedPerson.id} not found for update.");
    }
  }

  /// 특정 사람을 목록에서 삭제합니다. (ID 기준)
  Future<void> deletePerson(String personId) async {
    final List<AddedPerson> currentList = await getAddedPeople();
    final initialLength = currentList.length;
    currentList.removeWhere((p) => p.id == personId);
    if (currentList.length < initialLength) {
      await saveAddedPeople(currentList);
      print("Deleted person with ID: $personId");
    } else {
      print("Person with ID $personId not found for deletion.");
    }
  }

  // --------------------------------------
}
