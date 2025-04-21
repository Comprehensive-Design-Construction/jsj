// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelter_map_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShelterMapResponse _$ShelterMapResponseFromJson(Map<String, dynamic> json) {
  return _ShelterMapResponse.fromJson(json);
}

/// @nodoc
mixin _$ShelterMapResponse {
  @JsonKey(name: 'request_info')
  RequestInfo get requestInfo => throw _privateConstructorUsedError;
  String? get shelterMapHtml =>
      throw _privateConstructorUsedError; // 지도 HTML (nullable)
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this ShelterMapResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShelterMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShelterMapResponseCopyWith<ShelterMapResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShelterMapResponseCopyWith<$Res> {
  factory $ShelterMapResponseCopyWith(
    ShelterMapResponse value,
    $Res Function(ShelterMapResponse) then,
  ) = _$ShelterMapResponseCopyWithImpl<$Res, ShelterMapResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'request_info') RequestInfo requestInfo,
    String? shelterMapHtml,
    String? error,
  });

  $RequestInfoCopyWith<$Res> get requestInfo;
}

/// @nodoc
class _$ShelterMapResponseCopyWithImpl<$Res, $Val extends ShelterMapResponse>
    implements $ShelterMapResponseCopyWith<$Res> {
  _$ShelterMapResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShelterMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? shelterMapHtml = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            requestInfo:
                null == requestInfo
                    ? _value.requestInfo
                    : requestInfo // ignore: cast_nullable_to_non_nullable
                        as RequestInfo,
            shelterMapHtml:
                freezed == shelterMapHtml
                    ? _value.shelterMapHtml
                    : shelterMapHtml // ignore: cast_nullable_to_non_nullable
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

  /// Create a copy of ShelterMapResponse
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
abstract class _$$ShelterMapResponseImplCopyWith<$Res>
    implements $ShelterMapResponseCopyWith<$Res> {
  factory _$$ShelterMapResponseImplCopyWith(
    _$ShelterMapResponseImpl value,
    $Res Function(_$ShelterMapResponseImpl) then,
  ) = __$$ShelterMapResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'request_info') RequestInfo requestInfo,
    String? shelterMapHtml,
    String? error,
  });

  @override
  $RequestInfoCopyWith<$Res> get requestInfo;
}

/// @nodoc
class __$$ShelterMapResponseImplCopyWithImpl<$Res>
    extends _$ShelterMapResponseCopyWithImpl<$Res, _$ShelterMapResponseImpl>
    implements _$$ShelterMapResponseImplCopyWith<$Res> {
  __$$ShelterMapResponseImplCopyWithImpl(
    _$ShelterMapResponseImpl _value,
    $Res Function(_$ShelterMapResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShelterMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? shelterMapHtml = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$ShelterMapResponseImpl(
        requestInfo:
            null == requestInfo
                ? _value.requestInfo
                : requestInfo // ignore: cast_nullable_to_non_nullable
                    as RequestInfo,
        shelterMapHtml:
            freezed == shelterMapHtml
                ? _value.shelterMapHtml
                : shelterMapHtml // ignore: cast_nullable_to_non_nullable
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
class _$ShelterMapResponseImpl implements _ShelterMapResponse {
  const _$ShelterMapResponseImpl({
    @JsonKey(name: 'request_info') required this.requestInfo,
    this.shelterMapHtml,
    this.error,
  });

  factory _$ShelterMapResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShelterMapResponseImplFromJson(json);

  @override
  @JsonKey(name: 'request_info')
  final RequestInfo requestInfo;
  @override
  final String? shelterMapHtml;
  // 지도 HTML (nullable)
  @override
  final String? error;

  @override
  String toString() {
    return 'ShelterMapResponse(requestInfo: $requestInfo, shelterMapHtml: $shelterMapHtml, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShelterMapResponseImpl &&
            (identical(other.requestInfo, requestInfo) ||
                other.requestInfo == requestInfo) &&
            (identical(other.shelterMapHtml, shelterMapHtml) ||
                other.shelterMapHtml == shelterMapHtml) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, requestInfo, shelterMapHtml, error);

  /// Create a copy of ShelterMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShelterMapResponseImplCopyWith<_$ShelterMapResponseImpl> get copyWith =>
      __$$ShelterMapResponseImplCopyWithImpl<_$ShelterMapResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ShelterMapResponseImplToJson(this);
  }
}

abstract class _ShelterMapResponse implements ShelterMapResponse {
  const factory _ShelterMapResponse({
    @JsonKey(name: 'request_info') required final RequestInfo requestInfo,
    final String? shelterMapHtml,
    final String? error,
  }) = _$ShelterMapResponseImpl;

  factory _ShelterMapResponse.fromJson(Map<String, dynamic> json) =
      _$ShelterMapResponseImpl.fromJson;

  @override
  @JsonKey(name: 'request_info')
  RequestInfo get requestInfo;
  @override
  String? get shelterMapHtml; // 지도 HTML (nullable)
  @override
  String? get error;

  /// Create a copy of ShelterMapResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShelterMapResponseImplCopyWith<_$ShelterMapResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
