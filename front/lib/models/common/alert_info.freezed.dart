// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AlertInfo _$AlertInfoFromJson(Map<String, dynamic> json) {
  return _AlertInfo.fromJson(json);
}

/// @nodoc
mixin _$AlertInfo {
  String get type =>
      throw _privateConstructorUsedError; // 예: "폭염", "한파", "미세먼지 주의보" 등
  String get message => throw _privateConstructorUsedError;

  /// Serializes this AlertInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlertInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlertInfoCopyWith<AlertInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlertInfoCopyWith<$Res> {
  factory $AlertInfoCopyWith(AlertInfo value, $Res Function(AlertInfo) then) =
      _$AlertInfoCopyWithImpl<$Res, AlertInfo>;
  @useResult
  $Res call({String type, String message});
}

/// @nodoc
class _$AlertInfoCopyWithImpl<$Res, $Val extends AlertInfo>
    implements $AlertInfoCopyWith<$Res> {
  _$AlertInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlertInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null, Object? message = null}) {
    return _then(
      _value.copyWith(
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AlertInfoImplCopyWith<$Res>
    implements $AlertInfoCopyWith<$Res> {
  factory _$$AlertInfoImplCopyWith(
    _$AlertInfoImpl value,
    $Res Function(_$AlertInfoImpl) then,
  ) = __$$AlertInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, String message});
}

/// @nodoc
class __$$AlertInfoImplCopyWithImpl<$Res>
    extends _$AlertInfoCopyWithImpl<$Res, _$AlertInfoImpl>
    implements _$$AlertInfoImplCopyWith<$Res> {
  __$$AlertInfoImplCopyWithImpl(
    _$AlertInfoImpl _value,
    $Res Function(_$AlertInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AlertInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null, Object? message = null}) {
    return _then(
      _$AlertInfoImpl(
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AlertInfoImpl implements _AlertInfo {
  const _$AlertInfoImpl({required this.type, required this.message});

  factory _$AlertInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlertInfoImplFromJson(json);

  @override
  final String type;
  // 예: "폭염", "한파", "미세먼지 주의보" 등
  @override
  final String message;

  @override
  String toString() {
    return 'AlertInfo(type: $type, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlertInfoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, message);

  /// Create a copy of AlertInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlertInfoImplCopyWith<_$AlertInfoImpl> get copyWith =>
      __$$AlertInfoImplCopyWithImpl<_$AlertInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlertInfoImplToJson(this);
  }
}

abstract class _AlertInfo implements AlertInfo {
  const factory _AlertInfo({
    required final String type,
    required final String message,
  }) = _$AlertInfoImpl;

  factory _AlertInfo.fromJson(Map<String, dynamic> json) =
      _$AlertInfoImpl.fromJson;

  @override
  String get type; // 예: "폭염", "한파", "미세먼지 주의보" 등
  @override
  String get message;

  /// Create a copy of AlertInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlertInfoImplCopyWith<_$AlertInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
