import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/added_person.dart';

class PreferencesService {
  // SharedPreferences 키 정의
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _userAgeKey = 'user_age';
  static const String _userTypeKey = 'user_type';
  static const String _userGenderKey = 'user_gender'; // <<< 내 정보 성별 키 추가
  static const String _visibleIndicesKey = 'visible_health_indices';
  static const String _addedPeopleKey = 'added_people_list';
  static const String _myGuKey = 'my_gu';
  static const String _myDongKey = 'my_dong';
  static const String _userDiseasesKey = 'user_diseases';
  static const String _userIsPregnantKey = 'user_is_pregnant';
  static const String _consentGivenKey = 'consent_given'; // 개인정보 동의 여부
  static const String _usedSimpleStartKey = 'used_simple_start'; // 간편시작 사용 여부

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
  Future<void> saveUserInfo({
    int? age,
    String? userType,
    String? gender,
  }) async {
    final prefs = await _getPrefs();
    print('[Prefs][SAVE] --- Saving User Info START ---'); // 저장 시작 로그
    print(
      '[Prefs][SAVE] Attempting to save: age=$age, type=$userType, gender=$gender',
    ); // 저장하려는 값 로그
    if (age != null) {
      await prefs.setInt(_userAgeKey, age);
      print('[Prefs][SAVE] - age saved: $age'); // 저장 직후 값 확인 로그
    } else {
      await prefs.remove(_userAgeKey);
      print('[Prefs][SAVE] - age removed.');
    }
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType);
      print('[Prefs][SAVE] - type saved: $userType');
    } else {
      await prefs.remove(_userTypeKey);
      print('[Prefs][SAVE] - type removed.');
    }
    if (gender != null) {
      await prefs.setString(_userGenderKey, gender);
      print('[Prefs][SAVE] - gender saved: $gender');
    } else {
      await prefs.remove(_userGenderKey);
      print('[Prefs][SAVE] - gender removed.');
    }
    print('[Prefs][SAVE] --- Saving User Info END ---'); // 저장 종료 로그
  }

  // 사용자 나이 불러오기
  Future<int?> getUserAge() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_userAgeKey); // 저장된 값 없으면 null 반환
  }

  // 사용자 특성 리스트 불러오기 (disease 파라미터용)
  Future<String?> getUserType() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userTypeKey); // 저장된 값 없으면 null 반환
  }

  Future<String?> getUserGender() async {
    print('[Prefs] Getting User Gender...'); // 읽기 시작 로그
    final prefs = await _getPrefs();
    final gender = prefs.getString(_userGenderKey); // 읽기 직전
    print('[Prefs] Get User Gender: $gender'); // 읽은 후 로그
    return gender;
  }

  // --- '내 정보' 임산부 여부 저장/로드 함수 추가 ---
  Future<void> saveIsPregnant(bool? isPregnant) async {
    final prefs = await _getPrefs();
    if (isPregnant != null) {
      await prefs.setBool(_userIsPregnantKey, isPregnant);
    } else {
      await prefs.remove(_userIsPregnantKey); // null이면 삭제
    }
    print('Saved Is Pregnant: $isPregnant');
  }

  Future<bool?> getIsPregnant() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_userIsPregnantKey); // 없으면 null 반환
  }

  Future<void> saveUserDiseases(List<String>? diseases) async {
    final prefs = await _getPrefs();
    if (diseases != null && diseases.isNotEmpty) {
      await prefs.setStringList(_userDiseasesKey, diseases);
    } else {
      await prefs.remove(_userDiseasesKey);
    }
    print('Saved User Diseases: $diseases');
  }

  Future<List<String>?> getUserDiseases() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_userDiseasesKey);
  }

  Future<void> saveMyGuDong(String? gu, String? dong) async {
    final prefs = await _getPrefs();
    if (gu != null) {
      await prefs.setString(_myGuKey, gu);
    } else {
      await prefs.remove(_myGuKey);
    }
    if (dong != null) {
      await prefs.setString(_myDongKey, dong);
    } else {
      await prefs.remove(_myDongKey);
    }
    print('[Prefs] Saved My Location: gu=$gu, dong=$dong');
  }

  /// 저장된 '내 정보'의 구와 동 정보를 불러옵니다.
  /// 반환값: (String? gu, String? dong) 튜플
  Future<(String?, String?)> getMyGuDong() async {
    final prefs = await _getPrefs();
    final String? gu = prefs.getString(_myGuKey);
    final String? dong = prefs.getString(_myDongKey);
    print('[Prefs] Get My Location: gu=$gu, dong=$dong');
    return (gu, dong);
  }

  // (참고) 모든 저장된 정보 삭제 (테스트용)
  Future<void> clearAllPreferences() async {
    final prefs = await _getPrefs();
    // 앱에서 사용하는 모든 SharedPreferences 키 목록을 정확히 명시합니다.
    const List<String> allUsedKeys = [
      _onboardingCompleteKey,
      _userAgeKey,
      _userTypeKey,
      _userGenderKey,
      _visibleIndicesKey,
      _addedPeopleKey, // <<< 추가된 사용자 목록 키 포함!
      _myGuKey,
      _myDongKey,
      _userDiseasesKey,
      _userIsPregnantKey,
      _consentGivenKey,
      // 이전에 사용했던 키나 숨겨진 다른 키가 있다면 모두 추가해야 합니다.
    ];

    print("[PrefsService] Clearing preferences by removing individual keys...");
    int removedCount = 0;
    for (final key in allUsedKeys) {
      if (await prefs.containsKey(key)) {
        final success = await prefs.remove(key);
        if (success) {
          print("[PrefsService] Successfully removed key: $key");
          removedCount++;
        } else {
          print("[PrefsService] Failed to remove key: $key");
        }
      } else {
        print("[PrefsService] Key not found, skipping removal: $key");
      }
    }
    // 또는 모든 키를 가져와서 삭제하는 방식 (앱 외부에서 설정된 키도 삭제될 수 있음)
    final allKeysInPrefs = prefs.getKeys();
    print("[PrefsService] Clearing all found keys: ${allKeysInPrefs}");
    for (final key in allKeysInPrefs) {
      await prefs.remove(key);
    }

    print(
      "[PrefsService] Finished attempting to clear keys. Removed $removedCount keys.",
    );
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
    print(
      "[PrefsService] getAddedPeople: Raw JSON list from prefs: $jsonStringList",
    );

    if (jsonStringList == null) {
      print(
        "[PrefsService] getAddedPeople: No saved list found. Returning empty list.",
      );
      return [];
    }
    try {
      final decodedList =
          jsonStringList
              .map((jsonString) {
                try {
                  return AddedPerson.fromJson(jsonDecode(jsonString));
                } catch (e) {
                  print(
                    "[PrefsService] getAddedPeople: Error decoding JSON string '$jsonString': $e",
                  );
                  return null; // 오류 발생 시 null 반환
                }
              })
              .whereType<AddedPerson>()
              .toList(); // null이 아닌 것만 리스트로 만듦
      print(
        "[PrefsService] getAddedPeople: Decoded ${decodedList.length} people.",
      );
      return decodedList;
    } catch (e) {
      print(
        "[PrefsService] getAddedPeople: General error decoding added people list: $e",
      );
      return [];
    }
  }

  /// 추가된 사람 목록 전체를 저장합니다. (기존 목록 덮어쓰기)
  Future<void> saveAddedPeople(List<AddedPerson> people) async {
    final prefs = await _getPrefs();
    final List<String> jsonStringList =
        people
            .map((person) {
              try {
                return jsonEncode(person.toJson());
              } catch (e) {
                print(
                  "[PrefsService] saveAddedPeople: Error encoding person ${person.name} to JSON: $e",
                );
                return null; // 오류 발생 시 null 반환
              }
            })
            .whereType<String>()
            .toList(); // null이 아닌 것만 리스트로 만듦

    if (people.length != jsonStringList.length) {
      print(
        "[PrefsService] saveAddedPeople: Some people could not be encoded to JSON. Original count: ${people.length}, Encoded count: ${jsonStringList.length}",
      );
    }
    await prefs.setStringList(_addedPeopleKey, jsonStringList);
    print(
      "[PrefsService] saveAddedPeople: Saved ${jsonStringList.length} people. Raw JSON list: $jsonStringList",
    );
  }

  /// 새 사람을 목록에 추가합니다.
  Future<void> addPerson(AddedPerson person) async {
    final List<AddedPerson> currentList = await getAddedPeople();
    if (currentList.any((p) => p.id == person.id)) {
      print(
        "[PrefsService] addPerson: Person with ID ${person.id} already exists. Not adding.",
      );
      return;
    }
    currentList.add(person);
    print(
      "[PrefsService] addPerson: Adding person ${person.name}. Current list size before save: ${currentList.length}",
    );
    await saveAddedPeople(currentList); // saveAddedPeople 내부 로그도 확인
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
  /// 개인정보 활용 동의 여부를 저장합니다.
  Future<void> setConsentGiven(bool consented) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_consentGivenKey, consented);
    print("[PrefsService] Consent given status saved: $consented");
  }

  /// 저장된 개인정보 활용 동의 여부를 불러옵니다. 동의한 적 없으면 false를 반환합니다.
  Future<bool> hasConsent() async {
    final prefs = await _getPrefs();
    final result = prefs.getBool(_consentGivenKey) ?? false;
    print("[PrefsService] Read consent given status: $result");
    return result;
  }

  /// 간편시작 사용 여부를 저장합니다.
  Future<void> setUsedSimpleStart(bool used) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_usedSimpleStartKey, used);
    print("[PrefsService] Used simple start status saved: $used");
  }

  /// 간편시작 사용 여부를 불러옵니다. 사용한 적 없으면 false를 반환합니다.
  Future<bool> didUseSimpleStart() async {
    final prefs = await _getPrefs();
    final result = prefs.getBool(_usedSimpleStartKey) ?? false;
    print("[PrefsService] Read used simple start status: $result");
    return result;
  }
}
