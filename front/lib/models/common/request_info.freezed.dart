// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RequestInfo _$RequestInfoFromJson(Map<String, dynamic> json) {
  return _RequestInfo.fromJson(json);
}

/// @nodoc
mixin _$RequestInfo {
  // 키 이름은 API 응답에 따라 다를 수 있으므로 주의!
  // health index API 응답 기준
  @JsonKey(name: 'latitude', fromJson: parseDouble)
  double? get reqLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'longitude', fromJson: parseDouble)
  double? get reqLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'age', fromJson: parseInt)
  int? get reqAge => throw _privateConstructorUsedError;
  @JsonKey(name: 'disease')
  List<String> get reqDisease => throw _privateConstructorUsedError; // map API 응답 기준
  LocationInput? get requestLocation => throw _privateConstructorUsedError;
  UserInput? get userInput => throw _privateConstructorUsedError;
  String? get disasterType => throw _privateConstructorUsedError;
  String? get envType =>
      throw _privateConstructorUsedError; // env_map 응답에서도 사용됨
  @JsonKey(fromJson: parseDouble)
  double? get radiusKm => throw _privateConstructorUsedError;
  bool? get forceRefresh => throw _privateConstructorUsedError;

  /// Serializes this RequestInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequestInfoCopyWith<RequestInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestInfoCopyWith<$Res> {
  factory $RequestInfoCopyWith(
    RequestInfo value,
    $Res Function(RequestInfo) then,
  ) = _$RequestInfoCopyWithImpl<$Res, RequestInfo>;
  @useResult
  $Res call({
    @JsonKey(name: 'latitude', fromJson: parseDouble) double? reqLatitude,
    @JsonKey(name: 'longitude', fromJson: parseDouble) double? reqLongitude,
    @JsonKey(name: 'age', fromJson: parseInt) int? reqAge,
    @JsonKey(name: 'disease') List<String> reqDisease,
    LocationInput? requestLocation,
    UserInput? userInput,
    String? disasterType,
    String? envType,
    @JsonKey(fromJson: parseDouble) double? radiusKm,
    bool? forceRefresh,
  });

  $LocationInputCopyWith<$Res>? get requestLocation;
  $UserInputCopyWith<$Res>? get userInput;
}

/// @nodoc
class _$RequestInfoCopyWithImpl<$Res, $Val extends RequestInfo>
    implements $RequestInfoCopyWith<$Res> {
  _$RequestInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reqLatitude = freezed,
    Object? reqLongitude = freezed,
    Object? reqAge = freezed,
    Object? reqDisease = null,
    Object? requestLocation = freezed,
    Object? userInput = freezed,
    Object? disasterType = freezed,
    Object? envType = freezed,
    Object? radiusKm = freezed,
    Object? forceRefresh = freezed,
  }) {
    return _then(
      _value.copyWith(
            reqLatitude:
                freezed == reqLatitude
                    ? _value.reqLatitude
                    : reqLatitude // ignore: cast_nullable_to_non_nullable
                        as double?,
            reqLongitude:
                freezed == reqLongitude
                    ? _value.reqLongitude
                    : reqLongitude // ignore: cast_nullable_to_non_nullable
                        as double?,
            reqAge:
                freezed == reqAge
                    ? _value.reqAge
                    : reqAge // ignore: cast_nullable_to_non_nullable
                        as int?,
            reqDisease:
                null == reqDisease
                    ? _value.reqDisease
                    : reqDisease // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            requestLocation:
                freezed == requestLocation
                    ? _value.requestLocation
                    : requestLocation // ignore: cast_nullable_to_non_nullable
                        as LocationInput?,
            userInput:
                freezed == userInput
                    ? _value.userInput
                    : userInput // ignore: cast_nullable_to_non_nullable
                        as UserInput?,
            disasterType:
                freezed == disasterType
                    ? _value.disasterType
                    : disasterType // ignore: cast_nullable_to_non_nullable
                        as String?,
            envType:
                freezed == envType
                    ? _value.envType
                    : envType // ignore: cast_nullable_to_non_nullable
                        as String?,
            radiusKm:
                freezed == radiusKm
                    ? _value.radiusKm
                    : radiusKm // ignore: cast_nullable_to_non_nullable
                        as double?,
            forceRefresh:
                freezed == forceRefresh
                    ? _value.forceRefresh
                    : forceRefresh // ignore: cast_nullable_to_non_nullable
                        as bool?,
          )
          as $Val,
    );
  }

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationInputCopyWith<$Res>? get requestLocation {
    if (_value.requestLocation == null) {
      return null;
    }

    return $LocationInputCopyWith<$Res>(_value.requestLocation!, (value) {
      return _then(_value.copyWith(requestLocation: value) as $Val);
    });
  }

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserInputCopyWith<$Res>? get userInput {
    if (_value.userInput == null) {
      return null;
    }

    return $UserInputCopyWith<$Res>(_value.userInput!, (value) {
      return _then(_value.copyWith(userInput: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RequestInfoImplCopyWith<$Res>
    implements $RequestInfoCopyWith<$Res> {
  factory _$$RequestInfoImplCopyWith(
    _$RequestInfoImpl value,
    $Res Function(_$RequestInfoImpl) then,
  ) = __$$RequestInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'latitude', fromJson: parseDouble) double? reqLatitude,
    @JsonKey(name: 'longitude', fromJson: parseDouble) double? reqLongitude,
    @JsonKey(name: 'age', fromJson: parseInt) int? reqAge,
    @JsonKey(name: 'disease') List<String> reqDisease,
    LocationInput? requestLocation,
    UserInput? userInput,
    String? disasterType,
    String? envType,
    @JsonKey(fromJson: parseDouble) double? radiusKm,
    bool? forceRefresh,
  });

  @override
  $LocationInputCopyWith<$Res>? get requestLocation;
  @override
  $UserInputCopyWith<$Res>? get userInput;
}

/// @nodoc
class __$$RequestInfoImplCopyWithImpl<$Res>
    extends _$RequestInfoCopyWithImpl<$Res, _$RequestInfoImpl>
    implements _$$RequestInfoImplCopyWith<$Res> {
  __$$RequestInfoImplCopyWithImpl(
    _$RequestInfoImpl _value,
    $Res Function(_$RequestInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reqLatitude = freezed,
    Object? reqLongitude = freezed,
    Object? reqAge = freezed,
    Object? reqDisease = null,
    Object? requestLocation = freezed,
    Object? userInput = freezed,
    Object? disasterType = freezed,
    Object? envType = freezed,
    Object? radiusKm = freezed,
    Object? forceRefresh = freezed,
  }) {
    return _then(
      _$RequestInfoImpl(
        reqLatitude:
            freezed == reqLatitude
                ? _value.reqLatitude
                : reqLatitude // ignore: cast_nullable_to_non_nullable
                    as double?,
        reqLongitude:
            freezed == reqLongitude
                ? _value.reqLongitude
                : reqLongitude // ignore: cast_nullable_to_non_nullable
                    as double?,
        reqAge:
            freezed == reqAge
                ? _value.reqAge
                : reqAge // ignore: cast_nullable_to_non_nullable
                    as int?,
        reqDisease:
            null == reqDisease
                ? _value._reqDisease
                : reqDisease // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        requestLocation:
            freezed == requestLocation
                ? _value.requestLocation
                : requestLocation // ignore: cast_nullable_to_non_nullable
                    as LocationInput?,
        userInput:
            freezed == userInput
                ? _value.userInput
                : userInput // ignore: cast_nullable_to_non_nullable
                    as UserInput?,
        disasterType:
            freezed == disasterType
                ? _value.disasterType
                : disasterType // ignore: cast_nullable_to_non_nullable
                    as String?,
        envType:
            freezed == envType
                ? _value.envType
                : envType // ignore: cast_nullable_to_non_nullable
                    as String?,
        radiusKm:
            freezed == radiusKm
                ? _value.radiusKm
                : radiusKm // ignore: cast_nullable_to_non_nullable
                    as double?,
        forceRefresh:
            freezed == forceRefresh
                ? _value.forceRefresh
                : forceRefresh // ignore: cast_nullable_to_non_nullable
                    as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RequestInfoImpl implements _RequestInfo {
  const _$RequestInfoImpl({
    @JsonKey(name: 'latitude', fromJson: parseDouble) this.reqLatitude,
    @JsonKey(name: 'longitude', fromJson: parseDouble) this.reqLongitude,
    @JsonKey(name: 'age', fromJson: parseInt) this.reqAge,
    @JsonKey(name: 'disease') final List<String> reqDisease = const [],
    this.requestLocation,
    this.userInput,
    this.disasterType,
    this.envType,
    @JsonKey(fromJson: parseDouble) this.radiusKm,
    this.forceRefresh,
  }) : _reqDisease = reqDisease;

  factory _$RequestInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RequestInfoImplFromJson(json);

  // 키 이름은 API 응답에 따라 다를 수 있으므로 주의!
  // health index API 응답 기준
  @override
  @JsonKey(name: 'latitude', fromJson: parseDouble)
  final double? reqLatitude;
  @override
  @JsonKey(name: 'longitude', fromJson: parseDouble)
  final double? reqLongitude;
  @override
  @JsonKey(name: 'age', fromJson: parseInt)
  final int? reqAge;
  final List<String> _reqDisease;
  @override
  @JsonKey(name: 'disease')
  List<String> get reqDisease {
    if (_reqDisease is EqualUnmodifiableListView) return _reqDisease;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reqDisease);
  }

  // map API 응답 기준
  @override
  final LocationInput? requestLocation;
  @override
  final UserInput? userInput;
  @override
  final String? disasterType;
  @override
  final String? envType;
  // env_map 응답에서도 사용됨
  @override
  @JsonKey(fromJson: parseDouble)
  final double? radiusKm;
  @override
  final bool? forceRefresh;

  @override
  String toString() {
    return 'RequestInfo(reqLatitude: $reqLatitude, reqLongitude: $reqLongitude, reqAge: $reqAge, reqDisease: $reqDisease, requestLocation: $requestLocation, userInput: $userInput, disasterType: $disasterType, envType: $envType, radiusKm: $radiusKm, forceRefresh: $forceRefresh)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestInfoImpl &&
            (identical(other.reqLatitude, reqLatitude) ||
                other.reqLatitude == reqLatitude) &&
            (identical(other.reqLongitude, reqLongitude) ||
                other.reqLongitude == reqLongitude) &&
            (identical(other.reqAge, reqAge) || other.reqAge == reqAge) &&
            const DeepCollectionEquality().equals(
              other._reqDisease,
              _reqDisease,
            ) &&
            (identical(other.requestLocation, requestLocation) ||
                other.requestLocation == requestLocation) &&
            (identical(other.userInput, userInput) ||
                other.userInput == userInput) &&
            (identical(other.disasterType, disasterType) ||
                other.disasterType == disasterType) &&
            (identical(other.envType, envType) || other.envType == envType) &&
            (identical(other.radiusKm, radiusKm) ||
                other.radiusKm == radiusKm) &&
            (identical(other.forceRefresh, forceRefresh) ||
                other.forceRefresh == forceRefresh));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    reqLatitude,
    reqLongitude,
    reqAge,
    const DeepCollectionEquality().hash(_reqDisease),
    requestLocation,
    userInput,
    disasterType,
    envType,
    radiusKm,
    forceRefresh,
  );

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestInfoImplCopyWith<_$RequestInfoImpl> get copyWith =>
      __$$RequestInfoImplCopyWithImpl<_$RequestInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RequestInfoImplToJson(this);
  }
}

abstract class _RequestInfo implements RequestInfo {
  const factory _RequestInfo({
    @JsonKey(name: 'latitude', fromJson: parseDouble) final double? reqLatitude,
    @JsonKey(name: 'longitude', fromJson: parseDouble)
    final double? reqLongitude,
    @JsonKey(name: 'age', fromJson: parseInt) final int? reqAge,
    @JsonKey(name: 'disease') final List<String> reqDisease,
    final LocationInput? requestLocation,
    final UserInput? userInput,
    final String? disasterType,
    final String? envType,
    @JsonKey(fromJson: parseDouble) final double? radiusKm,
    final bool? forceRefresh,
  }) = _$RequestInfoImpl;

  factory _RequestInfo.fromJson(Map<String, dynamic> json) =
      _$RequestInfoImpl.fromJson;

  // 키 이름은 API 응답에 따라 다를 수 있으므로 주의!
  // health index API 응답 기준
  @override
  @JsonKey(name: 'latitude', fromJson: parseDouble)
  double? get reqLatitude;
  @override
  @JsonKey(name: 'longitude', fromJson: parseDouble)
  double? get reqLongitude;
  @override
  @JsonKey(name: 'age', fromJson: parseInt)
  int? get reqAge;
  @override
  @JsonKey(name: 'disease')
  List<String> get reqDisease; // map API 응답 기준
  @override
  LocationInput? get requestLocation;
  @override
  UserInput? get userInput;
  @override
  String? get disasterType;
  @override
  String? get envType; // env_map 응답에서도 사용됨
  @override
  @JsonKey(fromJson: parseDouble)
  double? get radiusKm;
  @override
  bool? get forceRefresh;

  /// Create a copy of RequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequestInfoImplCopyWith<_$RequestInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
