// lib/core/storage/user_profile_storage.dart
// TODO: 추가 등록한 인원 정보
import 'dart:convert'; // jsonEncode, jsonDecode 사용
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart'; // UserProfile 모델 import

class UserProfileStorage {
  static const String _profileKey = 'user_profile'; // SharedPreferences 키

  // 프로필 저장
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson()); // Map -> JSON 문자열
      return await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      print("Error saving user profile: $e");
      return false;
    }
  }

  // 프로필 로드
  Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        final profileMap =
            jsonDecode(profileJson) as Map<String, dynamic>; // JSON 문자열 -> Map
        return UserProfile.fromJson(profileMap); // Map -> UserProfile 객체
      }
      return null; // 저장된 프로필 없음
    } catch (e) {
      print("Error loading user profile: $e");
      return null;
    }
  }

  // 프로필 존재 여부 확인
  Future<bool> hasUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_profileKey);
    } catch (e) {
      print("Error checking user profile existence: $e");
      return false;
    }
  }

  // 프로필 삭제 (필요시)
  Future<bool> deleteUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_profileKey);
    } catch (e) {
      print("Error deleting user profile: $e");
      return false;
    }
  }
}
