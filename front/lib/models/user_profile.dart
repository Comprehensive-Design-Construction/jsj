// lib/models/user_profile.dart
import 'package:flutter/foundation.dart' show immutable; // 불변 객체 명시

@immutable // 이 클래스의 인스턴스는 생성 후 변경되지 않음을 나타냄
class UserProfile {
  final String? name; // 이름 (선택적)
  final String? dob; // 생년월일 (YYYY-MM-DD 형식 등)
  final String? gender; // 성별 (선택적)
  final List<String> diseases;

  const UserProfile({this.name, this.dob, this.gender, required this.diseases});

  // 로컬 저장소(SharedPreferences)는 Map<String, dynamic> 형태로 저장/로드
  // Map -> UserProfile 변환 팩토리 생성자
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      dob: json['dob'] as String?,
      gender: json['gender'] as String?,
      // diseases 필드는 List<String>으로 저장/로드
      diseases: List<String>.from(json['diseases'] as List? ?? []),
    );
  }

  // UserProfile -> Map 변환 메소드
  Map<String, dynamic> toJson() {
    return {'name': name, 'dob': dob, 'gender': gender, 'diseases': diseases};
  }

  // 나이 계산 getter (생년월일 기준)
  int? get age {
    if (dob == null) return null;
    try {
      final birthDate = DateTime.parse(dob!); // YYYY-MM-DD 형식 가정
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age >= 0 ? age : null; // 음수 나이 방지
    } catch (e) {
      // 날짜 파싱 오류 등 처리
      print("Error calculating age from DOB: $e");
      return null;
    }
  }
}
