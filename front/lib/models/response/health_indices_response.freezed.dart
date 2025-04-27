// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_indices_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HealthIndicesResponse _$HealthIndicesResponseFromJson(
  Map<String, dynamic> json,
) {
  return _HealthIndicesResponse.fromJson(json);
}

/// @nodoc
mixin _$HealthIndicesResponse {
  // RequestInfo 모델 사용 (json['request'] 부분을 RequestInfo.fromJson으로 처리)
  @JsonKey(name: 'request')
  RequestInfo get requestInfo => throw _privateConstructorUsedError;
  Region get region => throw _privateConstructorUsedError;
  IndexingData get indices =>
      throw _privateConstructorUsedError; // WeatherData와 alerts 추가 (API 스키마 기반)
  WeatherData? get weather => throw _privateConstructorUsedError; // Optional
  List<AlertInfo> get alerts =>
      throw _privateConstructorUsedError; // Default to empty list
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this HealthIndicesResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthIndicesResponseCopyWith<HealthIndicesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthIndicesResponseCopyWith<$Res> {
  factory $HealthIndicesResponseCopyWith(
    HealthIndicesResponse value,
    $Res Function(HealthIndicesResponse) then,
  ) = _$HealthIndicesResponseCopyWithImpl<$Res, HealthIndicesResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'request') RequestInfo requestInfo,
    Region region,
    IndexingData indices,
    WeatherData? weather,
    List<AlertInfo> alerts,
    String? error,
  });

  $RequestInfoCopyWith<$Res> get requestInfo;
  $RegionCopyWith<$Res> get region;
  $IndexingDataCopyWith<$Res> get indices;
  $WeatherDataCopyWith<$Res>? get weather;
}

/// @nodoc
class _$HealthIndicesResponseCopyWithImpl<
  $Res,
  $Val extends HealthIndicesResponse
>
    implements $HealthIndicesResponseCopyWith<$Res> {
  _$HealthIndicesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? region = null,
    Object? indices = null,
    Object? weather = freezed,
    Object? alerts = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            requestInfo:
                null == requestInfo
                    ? _value.requestInfo
                    : requestInfo // ignore: cast_nullable_to_non_nullable
                        as RequestInfo,
            region:
                null == region
                    ? _value.region
                    : region // ignore: cast_nullable_to_non_nullable
                        as Region,
            indices:
                null == indices
                    ? _value.indices
                    : indices // ignore: cast_nullable_to_non_nullable
                        as IndexingData,
            weather:
                freezed == weather
                    ? _value.weather
                    : weather // ignore: cast_nullable_to_non_nullable
                        as WeatherData?,
            alerts:
                null == alerts
                    ? _value.alerts
                    : alerts // ignore: cast_nullable_to_non_nullable
                        as List<AlertInfo>,
            error:
                freezed == error
                    ? _value.error
                    : error // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RequestInfoCopyWith<$Res> get requestInfo {
    return $RequestInfoCopyWith<$Res>(_value.requestInfo, (value) {
      return _then(_value.copyWith(requestInfo: value) as $Val);
    });
  }

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegionCopyWith<$Res> get region {
    return $RegionCopyWith<$Res>(_value.region, (value) {
      return _then(_value.copyWith(region: value) as $Val);
    });
  }

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IndexingDataCopyWith<$Res> get indices {
    return $IndexingDataCopyWith<$Res>(_value.indices, (value) {
      return _then(_value.copyWith(indices: value) as $Val);
    });
  }

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WeatherDataCopyWith<$Res>? get weather {
    if (_value.weather == null) {
      return null;
    }

    return $WeatherDataCopyWith<$Res>(_value.weather!, (value) {
      return _then(_value.copyWith(weather: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HealthIndicesResponseImplCopyWith<$Res>
    implements $HealthIndicesResponseCopyWith<$Res> {
  factory _$$HealthIndicesResponseImplCopyWith(
    _$HealthIndicesResponseImpl value,
    $Res Function(_$HealthIndicesResponseImpl) then,
  ) = __$$HealthIndicesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'request') RequestInfo requestInfo,
    Region region,
    IndexingData indices,
    WeatherData? weather,
    List<AlertInfo> alerts,
    String? error,
  });

  @override
  $RequestInfoCopyWith<$Res> get requestInfo;
  @override
  $RegionCopyWith<$Res> get region;
  @override
  $IndexingDataCopyWith<$Res> get indices;
  @override
  $WeatherDataCopyWith<$Res>? get weather;
}

/// @nodoc
class __$$HealthIndicesResponseImplCopyWithImpl<$Res>
    extends
        _$HealthIndicesResponseCopyWithImpl<$Res, _$HealthIndicesResponseImpl>
    implements _$$HealthIndicesResponseImplCopyWith<$Res> {
  __$$HealthIndicesResponseImplCopyWithImpl(
    _$HealthIndicesResponseImpl _value,
    $Res Function(_$HealthIndicesResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestInfo = null,
    Object? region = null,
    Object? indices = null,
    Object? weather = freezed,
    Object? alerts = null,
    Object? error = freezed,
  }) {
    return _then(
      _$HealthIndicesResponseImpl(
        requestInfo:
            null == requestInfo
                ? _value.requestInfo
                : requestInfo // ignore: cast_nullable_to_non_nullable
                    as RequestInfo,
        region:
            null == region
                ? _value.region
                : region // ignore: cast_nullable_to_non_nullable
                    as Region,
        indices:
            null == indices
                ? _value.indices
                : indices // ignore: cast_nullable_to_non_nullable
                    as IndexingData,
        weather:
            freezed == weather
                ? _value.weather
                : weather // ignore: cast_nullable_to_non_nullable
                    as WeatherData?,
        alerts:
            null == alerts
                ? _value._alerts
                : alerts // ignore: cast_nullable_to_non_nullable
                    as List<AlertInfo>,
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
class _$HealthIndicesResponseImpl implements _HealthIndicesResponse {
  const _$HealthIndicesResponseImpl({
    @JsonKey(name: 'request') required this.requestInfo,
    required this.region,
    required this.indices,
    this.weather,
    final List<AlertInfo> alerts = const [],
    this.error,
  }) : _alerts = alerts;

  factory _$HealthIndicesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthIndicesResponseImplFromJson(json);

  // RequestInfo 모델 사용 (json['request'] 부분을 RequestInfo.fromJson으로 처리)
  @override
  @JsonKey(name: 'request')
  final RequestInfo requestInfo;
  @override
  final Region region;
  @override
  final IndexingData indices;
  // WeatherData와 alerts 추가 (API 스키마 기반)
  @override
  final WeatherData? weather;
  // Optional
  final List<AlertInfo> _alerts;
  // Optional
  @override
  @JsonKey()
  List<AlertInfo> get alerts {
    if (_alerts is EqualUnmodifiableListView) return _alerts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_alerts);
  }

  // Default to empty list
  @override
  final String? error;

  @override
  String toString() {
    return 'HealthIndicesResponse(requestInfo: $requestInfo, region: $region, indices: $indices, weather: $weather, alerts: $alerts, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthIndicesResponseImpl &&
            (identical(other.requestInfo, requestInfo) ||
                other.requestInfo == requestInfo) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.indices, indices) || other.indices == indices) &&
            (identical(other.weather, weather) || other.weather == weather) &&
            const DeepCollectionEquality().equals(other._alerts, _alerts) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    requestInfo,
    region,
    indices,
    weather,
    const DeepCollectionEquality().hash(_alerts),
    error,
  );

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthIndicesResponseImplCopyWith<_$HealthIndicesResponseImpl>
  get copyWith =>
      __$$HealthIndicesResponseImplCopyWithImpl<_$HealthIndicesResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthIndicesResponseImplToJson(this);
  }
}

abstract class _HealthIndicesResponse implements HealthIndicesResponse {
  const factory _HealthIndicesResponse({
    @JsonKey(name: 'request') required final RequestInfo requestInfo,
    required final Region region,
    required final IndexingData indices,
    final WeatherData? weather,
    final List<AlertInfo> alerts,
    final String? error,
  }) = _$HealthIndicesResponseImpl;

  factory _HealthIndicesResponse.fromJson(Map<String, dynamic> json) =
      _$HealthIndicesResponseImpl.fromJson;

  // RequestInfo 모델 사용 (json['request'] 부분을 RequestInfo.fromJson으로 처리)
  @override
  @JsonKey(name: 'request')
  RequestInfo get requestInfo;
  @override
  Region get region;
  @override
  IndexingData get indices; // WeatherData와 alerts 추가 (API 스키마 기반)
  @override
  WeatherData? get weather; // Optional
  @override
  List<AlertInfo> get alerts; // Default to empty list
  @override
  String? get error;

  /// Create a copy of HealthIndicesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthIndicesResponseImplCopyWith<_$HealthIndicesResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
