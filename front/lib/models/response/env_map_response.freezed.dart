// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'env_map_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EnvMapResponse _$EnvMapResponseFromJson(Map<String, dynamic> json) {
  return _EnvMapResponse.fromJson(json);
}

/// @nodoc
mixin _$EnvMapResponse {
  @JsonKey(name: 'request_info')
  RequestInfo get requestInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'env_map_html')
  String? get envMapHtml => throw _privateConstructorUsedError;
  @JsonKey(name: 'env_type')
  String get envType => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_updated')
  String? get lastUpdated => throw _privateConstructorUsedError;
  @JsonKey(name: 'error')
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this EnvMapResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnvMapResponseCopyWith<EnvMapResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnvMapResponseCopyWith<$Res> {
  factory $EnvMapResponseCopyWith(
    EnvMapResponse value,
    $Res Function(EnvMapResponse) then,
  ) = _$EnvMapResponseCopyWithImpl<$Res, EnvMapResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'request_info') RequestInfo requestInfo,
    @JsonKey(name: 'env_map_html') String? envMapHtml,
    @JsonKey(name: 'env_type') String envType,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'error') String? error,
  });

  $RequestInfoCopyWith<$Res> get requestInfo;
}

/// @nodoc
class _$EnvMapResponseCopyWithImpl<$Res, $Val extends EnvMapResponse>
    implements $EnvMapResponseCopyWith<$Res> {
  _$EnvMapResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? envMapHtml = freezed,
    Object? envType = null,
    Object? lastUpdated = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            requestInfo:
                null == requestInfo
                    ? _value.requestInfo
                    : requestInfo // ignore: cast_nullable_to_non_nullable
                        as RequestInfo,
            envMapHtml:
                freezed == envMapHtml
                    ? _value.envMapHtml
                    : envMapHtml // ignore: cast_nullable_to_non_nullable
                        as String?,
            envType:
                null == envType
                    ? _value.envType
                    : envType // ignore: cast_nullable_to_non_nullable
                        as String,
            lastUpdated:
                freezed == lastUpdated
                    ? _value.lastUpdated
                    : lastUpdated // ignore: cast_nullable_to_non_nullable
                        as String?,
            error:
                freezed == error
                    ? _value.error
                    : error // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RequestInfoCopyWith<$Res> get requestInfo {
    return $RequestInfoCopyWith<$Res>(_value.requestInfo, (value) {
      return _then(_value.copyWith(requestInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EnvMapResponseImplCopyWith<$Res>
    implements $EnvMapResponseCopyWith<$Res> {
  factory _$$EnvMapResponseImplCopyWith(
    _$EnvMapResponseImpl value,
    $Res Function(_$EnvMapResponseImpl) then,
  ) = __$$EnvMapResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'request_info') RequestInfo requestInfo,
    @JsonKey(name: 'env_map_html') String? envMapHtml,
    @JsonKey(name: 'env_type') String envType,
    @JsonKey(name: 'last_updated') String? lastUpdated,
    @JsonKey(name: 'error') String? error,
  });

  @override
  $RequestInfoCopyWith<$Res> get requestInfo;
}

/// @nodoc
class __$$EnvMapResponseImplCopyWithImpl<$Res>
    extends _$EnvMapResponseCopyWithImpl<$Res, _$EnvMapResponseImpl>
    implements _$$EnvMapResponseImplCopyWith<$Res> {
  __$$EnvMapResponseImplCopyWithImpl(
    _$EnvMapResponseImpl _value,
    $Res Function(_$EnvMapResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? envMapHtml = freezed,
    Object? envType = null,
    Object? lastUpdated = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$EnvMapResponseImpl(
        requestInfo:
            null == requestInfo
                ? _value.requestInfo
                : requestInfo // ignore: cast_nullable_to_non_nullable
                    as RequestInfo,
        envMapHtml:
            freezed == envMapHtml
                ? _value.envMapHtml
                : envMapHtml // ignore: cast_nullable_to_non_nullable
                    as String?,
        envType:
            null == envType
                ? _value.envType
                : envType // ignore: cast_nullable_to_non_nullable
                    as String,
        lastUpdated:
            freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                    as String?,
        error:
            freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EnvMapResponseImpl implements _EnvMapResponse {
  const _$EnvMapResponseImpl({
    @JsonKey(name: 'request_info') required this.requestInfo,
    @JsonKey(name: 'env_map_html') this.envMapHtml,
    @JsonKey(name: 'env_type') required this.envType,
    @JsonKey(name: 'last_updated') this.lastUpdated,
    @JsonKey(name: 'error') this.error,
  });

  factory _$EnvMapResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnvMapResponseImplFromJson(json);

  @override
  @JsonKey(name: 'request_info')
  final RequestInfo requestInfo;
  @override
  @JsonKey(name: 'env_map_html')
  final String? envMapHtml;
  @override
  @JsonKey(name: 'env_type')
  final String envType;
  @override
  @JsonKey(name: 'last_updated')
  final String? lastUpdated;
  @override
  @JsonKey(name: 'error')
  final String? error;

  @override
  String toString() {
    return 'EnvMapResponse(requestInfo: $requestInfo, envMapHtml: $envMapHtml, envType: $envType, lastUpdated: $lastUpdated, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnvMapResponseImpl &&
            (identical(other.requestInfo, requestInfo) ||
                other.requestInfo == requestInfo) &&
            (identical(other.envMapHtml, envMapHtml) ||
                other.envMapHtml == envMapHtml) &&
            (identical(other.envType, envType) || other.envType == envType) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    requestInfo,
    envMapHtml,
    envType,
    lastUpdated,
    error,
  );

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnvMapResponseImplCopyWith<_$EnvMapResponseImpl> get copyWith =>
      __$$EnvMapResponseImplCopyWithImpl<_$EnvMapResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EnvMapResponseImplToJson(this);
  }
}

abstract class _EnvMapResponse implements EnvMapResponse {
  const factory _EnvMapResponse({
    @JsonKey(name: 'request_info') required final RequestInfo requestInfo,
    @JsonKey(name: 'env_map_html') final String? envMapHtml,
    @JsonKey(name: 'env_type') required final String envType,
    @JsonKey(name: 'last_updated') final String? lastUpdated,
    @JsonKey(name: 'error') final String? error,
  }) = _$EnvMapResponseImpl;

  factory _EnvMapResponse.fromJson(Map<String, dynamic> json) =
      _$EnvMapResponseImpl.fromJson;

  @override
  @JsonKey(name: 'request_info')
  RequestInfo get requestInfo;
  @override
  @JsonKey(name: 'env_map_html')
  String? get envMapHtml;
  @override
  @JsonKey(name: 'env_type')
  String get envType;
  @override
  @JsonKey(name: 'last_updated')
  String? get lastUpdated;
  @override
  @JsonKey(name: 'error')
  String? get error;

  /// Create a copy of EnvMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnvMapResponseImplCopyWith<_$EnvMapResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
