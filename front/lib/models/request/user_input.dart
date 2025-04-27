// lib/models/request/user_input.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_input.freezed.dart';
part 'user_input.g.dart';

@freezed
class UserInput with _$UserInput {
  const factory UserInput({
    int? age, // Optional
    @Default([]) List<String> disease, // Default to empty list
  }) = _UserInput;

  factory UserInput.fromJson(Map<String, dynamic> json) =>
      _$UserInputFromJson(json);
}
