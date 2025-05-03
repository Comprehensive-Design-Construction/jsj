import 'dart:convert'; // jsonEncode, jsonDecode 사용

class AddedPerson {
  final String id; // 각 사람을 구분할 고유 ID (예: 타임스탬프 또는 UUID)
  final String name;
  final DateTime? birthDate; // 생년월일 직접 저장
  final String? gu; // 선택한 구
  final String? dong; // 선택한 동
  final double? latitude; // 조회된 위도
  final double? longitude; // 조회된 경도
  final List<String>? userTypes; // 선택한 사용자 특성/질병 목록

  AddedPerson({
    required this.id,
    required this.name,
    this.birthDate,
    this.gu,
    this.dong,
    this.latitude,
    this.longitude,
    this.userTypes,
  });

  // 나이 계산 getter (필요시 사용)
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

  // 객체를 JSON(Map)으로 변환 (shared_preferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // DateTime은 ISO8601 문자열로 저장
      'birthDate': birthDate?.toIso8601String(),
      'gu': gu,
      'dong': dong,
      'latitude': latitude,
      'longitude': longitude,
      'userTypes': userTypes,
    };
  }

  // JSON(Map)을 객체로 변환 (shared_preferences 로드용)
  factory AddedPerson.fromJson(Map<String, dynamic> json) {
    return AddedPerson(
      id: json['id'] as String,
      name: json['name'] as String,
      // 저장된 ISO8601 문자열을 DateTime으로 변환
      birthDate:
          json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'] as String)
              : null,
      gu: json['gu'] as String?,
      dong: json['dong'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // List<dynamic>을 List<String>으로 변환
      userTypes: (json['userTypes'] as List<dynamic>?)?.cast<String>().toList(),
    );
  }
}
