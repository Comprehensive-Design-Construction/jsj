// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) {
  return _WeatherData.fromJson(json);
}

/// @nodoc
mixin _$WeatherData {
  @JsonKey(fromJson: parseDouble)
  double? get temperature => throw _privateConstructorUsedError; // 현재 온도
  @JsonKey(fromJson: parseDouble)
  double? get pressure => throw _privateConstructorUsedError; // 기압
  @JsonKey(fromJson: parseDouble)
  double? get humidity => throw _privateConstructorUsedError; // 습도
  @JsonKey(fromJson: parseDouble)
  double? get windSpeed => throw _privateConstructorUsedError; // 풍속
  @JsonKey(fromJson: parseDouble)
  double? get tempMin => throw _privateConstructorUsedError; // 최저 온도
  @JsonKey(fromJson: parseDouble)
  double? get tempMax => throw _privateConstructorUsedError; // 최고 온도
  String? get description =>
      throw _privateConstructorUsedError; // 날씨 설명 (예: "Clear sky", "Rain") - !!! API 응답 키 확인 필요 !!!
  String? get mainCondition =>
      throw _privateConstructorUsedError; // 주 날씨 상태 (예: "Clear", "Rain", "Clouds") - !!! API 응답 키 확인 필요 !!!
  String? get icon =>
      throw _privateConstructorUsedError; // 날씨 아이콘 코드 (OpenWeatherMap 등) - !!! API 응답 키 확인 필요 !!!
  String? get city => throw _privateConstructorUsedError; // 도시 이름
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this WeatherData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeatherData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeatherDataCopyWith<WeatherData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeatherDataCopyWith<$Res> {
  factory $WeatherDataCopyWith(
    WeatherData value,
    $Res Function(WeatherData) then,
  ) = _$WeatherDataCopyWithImpl<$Res, WeatherData>;
  @useResult
  $Res call({
    @JsonKey(fromJson: parseDouble) double? temperature,
    @JsonKey(fromJson: parseDouble) double? pressure,
    @JsonKey(fromJson: parseDouble) double? humidity,
    @JsonKey(fromJson: parseDouble) double? windSpeed,
    @JsonKey(fromJson: parseDouble) double? tempMin,
    @JsonKey(fromJson: parseDouble) double? tempMax,
    String? description,
    String? mainCondition,
    String? icon,
    String? city,
    String? error,
  });
}

/// @nodoc
class _$WeatherDataCopyWithImpl<$Res, $Val extends WeatherData>
    implements $WeatherDataCopyWith<$Res> {
  _$WeatherDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeatherData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = freezed,
    Object? pressure = freezed,
    Object? humidity = freezed,
    Object? windSpeed = freezed,
    Object? tempMin = freezed,
    Object? tempMax = freezed,
    Object? description = freezed,
    Object? mainCondition = freezed,
    Object? icon = freezed,
    Object? city = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            temperature:
                freezed == temperature
                    ? _value.temperature
                    : temperature // ignore: cast_nullable_to_non_nullable
                        as double?,
            pressure:
                freezed == pressure
                    ? _value.pressure
                    : pressure // ignore: cast_nullable_to_non_nullable
                        as double?,
            humidity:
                freezed == humidity
                    ? _value.humidity
                    : humidity // ignore: cast_nullable_to_non_nullable
                        as double?,
            windSpeed:
                freezed == windSpeed
                    ? _value.windSpeed
                    : windSpeed // ignore: cast_nullable_to_non_nullable
                        as double?,
            tempMin:
                freezed == tempMin
                    ? _value.tempMin
                    : tempMin // ignore: cast_nullable_to_non_nullable
                        as double?,
            tempMax:
                freezed == tempMax
                    ? _value.tempMax
                    : tempMax // ignore: cast_nullable_to_non_nullable
                        as double?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            mainCondition:
                freezed == mainCondition
                    ? _value.mainCondition
                    : mainCondition // ignore: cast_nullable_to_non_nullable
                        as String?,
            icon:
                freezed == icon
                    ? _value.icon
                    : icon // ignore: cast_nullable_to_non_nullable
                        as String?,
            city:
                freezed == city
                    ? _value.city
                    : city // ignore: cast_nullable_to_non_nullable
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
}

/// @nodoc
abstract class _$$WeatherDataImplCopyWith<$Res>
    implements $WeatherDataCopyWith<$Res> {
  factory _$$WeatherDataImplCopyWith(
    _$WeatherDataImpl value,
    $Res Function(_$WeatherDataImpl) then,
  ) = __$$WeatherDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: parseDouble) double? temperature,
    @JsonKey(fromJson: parseDouble) double? pressure,
    @JsonKey(fromJson: parseDouble) double? humidity,
    @JsonKey(fromJson: parseDouble) double? windSpeed,
    @JsonKey(fromJson: parseDouble) double? tempMin,
    @JsonKey(fromJson: parseDouble) double? tempMax,
    String? description,
    String? mainCondition,
    String? icon,
    String? city,
    String? error,
  });
}

/// @nodoc
class __$$WeatherDataImplCopyWithImpl<$Res>
    extends _$WeatherDataCopyWithImpl<$Res, _$WeatherDataImpl>
    implements _$$WeatherDataImplCopyWith<$Res> {
  __$$WeatherDataImplCopyWithImpl(
    _$WeatherDataImpl _value,
    $Res Function(_$WeatherDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WeatherData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperature = freezed,
    Object? pressure = freezed,
    Object? humidity = freezed,
    Object? windSpeed = freezed,
    Object? tempMin = freezed,
    Object? tempMax = freezed,
    Object? description = freezed,
    Object? mainCondition = freezed,
    Object? icon = freezed,
    Object? city = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$WeatherDataImpl(
        temperature:
            freezed == temperature
                ? _value.temperature
                : temperature // ignore: cast_nullable_to_non_nullable
                    as double?,
        pressure:
            freezed == pressure
                ? _value.pressure
                : pressure // ignore: cast_nullable_to_non_nullable
                    as double?,
        humidity:
            freezed == humidity
                ? _value.humidity
                : humidity // ignore: cast_nullable_to_non_nullable
                    as double?,
        windSpeed:
            freezed == windSpeed
                ? _value.windSpeed
                : windSpeed // ignore: cast_nullable_to_non_nullable
                    as double?,
        tempMin:
            freezed == tempMin
                ? _value.tempMin
                : tempMin // ignore: cast_nullable_to_non_nullable
                    as double?,
        tempMax:
            freezed == tempMax
                ? _value.tempMax
                : tempMax // ignore: cast_nullable_to_non_nullable
                    as double?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        mainCondition:
            freezed == mainCondition
                ? _value.mainCondition
                : mainCondition // ignore: cast_nullable_to_non_nullable
                    as String?,
        icon:
            freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                    as String?,
        city:
            freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
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
class _$WeatherDataImpl implements _WeatherData {
  const _$WeatherDataImpl({
    @JsonKey(fromJson: parseDouble) this.temperature,
    @JsonKey(fromJson: parseDouble) this.pressure,
    @JsonKey(fromJson: parseDouble) this.humidity,
    @JsonKey(fromJson: parseDouble) this.windSpeed,
    @JsonKey(fromJson: parseDouble) this.tempMin,
    @JsonKey(fromJson: parseDouble) this.tempMax,
    this.description,
    this.mainCondition,
    this.icon,
    this.city,
    this.error,
  });

  factory _$WeatherDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeatherDataImplFromJson(json);

  @override
  @JsonKey(fromJson: parseDouble)
  final double? temperature;
  // 현재 온도
  @override
  @JsonKey(fromJson: parseDouble)
  final double? pressure;
  // 기압
  @override
  @JsonKey(fromJson: parseDouble)
  final double? humidity;
  // 습도
  @override
  @JsonKey(fromJson: parseDouble)
  final double? windSpeed;
  // 풍속
  @override
  @JsonKey(fromJson: parseDouble)
  final double? tempMin;
  // 최저 온도
  @override
  @JsonKey(fromJson: parseDouble)
  final double? tempMax;
  // 최고 온도
  @override
  final String? description;
  // 날씨 설명 (예: "Clear sky", "Rain") - !!! API 응답 키 확인 필요 !!!
  @override
  final String? mainCondition;
  // 주 날씨 상태 (예: "Clear", "Rain", "Clouds") - !!! API 응답 키 확인 필요 !!!
  @override
  final String? icon;
  // 날씨 아이콘 코드 (OpenWeatherMap 등) - !!! API 응답 키 확인 필요 !!!
  @override
  final String? city;
  // 도시 이름
  @override
  final String? error;

  @override
  String toString() {
    return 'WeatherData(temperature: $temperature, pressure: $pressure, humidity: $humidity, windSpeed: $windSpeed, tempMin: $tempMin, tempMax: $tempMax, description: $description, mainCondition: $mainCondition, icon: $icon, city: $city, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeatherDataImpl &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.pressure, pressure) ||
                other.pressure == pressure) &&
            (identical(other.humidity, humidity) ||
                other.humidity == humidity) &&
            (identical(other.windSpeed, windSpeed) ||
                other.windSpeed == windSpeed) &&
            (identical(other.tempMin, tempMin) || other.tempMin == tempMin) &&
            (identical(other.tempMax, tempMax) || other.tempMax == tempMax) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.mainCondition, mainCondition) ||
                other.mainCondition == mainCondition) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    temperature,
    pressure,
    humidity,
    windSpeed,
    tempMin,
    tempMax,
    description,
    mainCondition,
    icon,
    city,
    error,
  );

  /// Create a copy of WeatherData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeatherDataImplCopyWith<_$WeatherDataImpl> get copyWith =>
      __$$WeatherDataImplCopyWithImpl<_$WeatherDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeatherDataImplToJson(this);
  }
}

abstract class _WeatherData implements WeatherData {
  const factory _WeatherData({
    @JsonKey(fromJson: parseDouble) final double? temperature,
    @JsonKey(fromJson: parseDouble) final double? pressure,
    @JsonKey(fromJson: parseDouble) final double? humidity,
    @JsonKey(fromJson: parseDouble) final double? windSpeed,
    @JsonKey(fromJson: parseDouble) final double? tempMin,
    @JsonKey(fromJson: parseDouble) final double? tempMax,
    final String? description,
    final String? mainCondition,
    final String? icon,
    final String? city,
    final String? error,
  }) = _$WeatherDataImpl;

  factory _WeatherData.fromJson(Map<String, dynamic> json) =
      _$WeatherDataImpl.fromJson;

  @override
  @JsonKey(fromJson: parseDouble)
  double? get temperature; // 현재 온도
  @override
  @JsonKey(fromJson: parseDouble)
  double? get pressure; // 기압
  @override
  @JsonKey(fromJson: parseDouble)
  double? get humidity; // 습도
  @override
  @JsonKey(fromJson: parseDouble)
  double? get windSpeed; // 풍속
  @override
  @JsonKey(fromJson: parseDouble)
  double? get tempMin; // 최저 온도
  @override
  @JsonKey(fromJson: parseDouble)
  double? get tempMax; // 최고 온도
  @override
  String? get description; // 날씨 설명 (예: "Clear sky", "Rain") - !!! API 응답 키 확인 필요 !!!
  @override
  String? get mainCondition; // 주 날씨 상태 (예: "Clear", "Rain", "Clouds") - !!! API 응답 키 확인 필요 !!!
  @override
  String? get icon; // 날씨 아이콘 코드 (OpenWeatherMap 등) - !!! API 응답 키 확인 필요 !!!
  @override
  String? get city; // 도시 이름
  @override
  String? get error;

  /// Create a copy of WeatherData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeatherDataImplCopyWith<_$WeatherDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
