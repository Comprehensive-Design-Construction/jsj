// lib/models/common/alert_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_info.freezed.dart';
part 'alert_info.g.dart';

@freezed
class AlertInfo with _$AlertInfo {
  const factory AlertInfo({
    required String type, // 예: "폭염", "한파", "미세먼지 주의보" 등
    required String message, // 알림 내용
  }) = _AlertInfo;

  factory AlertInfo.fromJson(Map<String, dynamic> json) =>
      _$AlertInfoFromJson(json);
}
