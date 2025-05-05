// lib/data/models/added_person.dart
import 'dart:convert';

class Gender {
  static const String male = 'male';
  static const String female = 'female';
}

class AddedPerson {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String? gu;
  final String? dong;
  final double? latitude;
  final double? longitude;
  // final List<String>? userTypes; // <<< 이름 변경
  final String? workingType; // <<< 이름 변경 (단일 근무 유형)
  final List<String>? diseases; // <<< 기저 질환 필드 추가
  final String? gender;
  final bool? isPregnant;

  AddedPerson({
    required this.id,
    required this.name,
    this.birthDate,
    this.gu,
    this.dong,
    this.latitude,
    this.longitude,
    // this.userTypes, // <<< 이름 변경
    this.workingType, // <<< 이름 변경
    this.diseases, // <<< 추가
    this.gender,
    this.isPregnant,
  });

  // 나이 계산 getter (유지)
  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  // 객체를 JSON(Map)으로 변환 (수정)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'gu': gu,
      'dong': dong,
      'latitude': latitude,
      'longitude': longitude,
      // 'userTypes': userTypes, // <<< 이름 변경
      'workingType': workingType, // <<< 이름 변경
      'diseases': diseases, // <<< 추가
      'gender': gender,
      'isPregnant': isPregnant,
    };
  }

  // JSON(Map)을 객체로 변환 (수정)
  factory AddedPerson.fromJson(Map<String, dynamic> json) {
    return AddedPerson(
      id: json['id'] as String,
      name: json['name'] as String,
      birthDate:
          json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'] as String)
              : null,
      gu: json['gu'] as String?,
      dong: json['dong'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // userTypes: (json['userTypes'] as List<dynamic>?)?.cast<String>().toList(), // <<< 이름 변경
      workingType: json['workingType'] as String?, // <<< 이름 변경
      diseases:
          (json['diseases'] as List<dynamic>?)
              ?.cast<String>()
              .toList(), // <<< 추가
      gender: json['gender'] as String?,
      isPregnant: json['isPregnant'] as bool?,
    );
  }
}
