double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  print("Warning: Could not parse value '$value' as double."); // 파싱 실패 시 로그
  return null;
}

/// JSON의 다양한 숫자/문자열 타입을 int?로 안전하게 변환
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  // double을 int로 변환 시 소수점 버림
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  print("Warning: Could not parse value '$value' as int."); // 파싱 실패 시 로그
  return null;
}
