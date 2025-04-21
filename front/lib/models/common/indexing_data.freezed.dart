// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'indexing_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IndexingData _$IndexingDataFromJson(Map<String, dynamic> json) {
  return _IndexingData.fromJson(json);
}

/// @nodoc
mixin _$IndexingData {
  @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
  double? get apparentTemperature => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_status')
  String? get apparentTempRiskStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'ali_score', fromJson: parseDouble)
  double? get aliScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'ali_level', fromJson: parseInt)
  int? get aliLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
  double? get strokeIndexScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
  int? get strokeIndexLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
  double? get coldIndexScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'cold_index_level', fromJson: parseInt)
  int? get coldIndexLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
  double? get foodPoisoningIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'food_poisoning_risk')
  String? get foodPoisoningRisk => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this IndexingData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IndexingData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IndexingDataCopyWith<IndexingData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndexingDataCopyWith<$Res> {
  factory $IndexingDataCopyWith(
    IndexingData value,
    $Res Function(IndexingData) then,
  ) = _$IndexingDataCopyWithImpl<$Res, IndexingData>;
  @useResult
  $Res call({
    @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
    double? apparentTemperature,
    @JsonKey(name: 'risk_status') String? apparentTempRiskStatus,
    @JsonKey(name: 'ali_score', fromJson: parseDouble) double? aliScore,
    @JsonKey(name: 'ali_level', fromJson: parseInt) int? aliLevel,
    @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
    double? strokeIndexScore,
    @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
    int? strokeIndexLevel,
    @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
    double? coldIndexScore,
    @JsonKey(name: 'cold_index_level', fromJson: parseInt) int? coldIndexLevel,
    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    double? foodPoisoningIndex,
    @JsonKey(name: 'food_poisoning_risk') String? foodPoisoningRisk,
    String? error,
  });
}

/// @nodoc
class _$IndexingDataCopyWithImpl<$Res, $Val extends IndexingData>
    implements $IndexingDataCopyWith<$Res> {
  _$IndexingDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IndexingData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apparentTemperature = freezed,
    Object? apparentTempRiskStatus = freezed,
    Object? aliScore = freezed,
    Object? aliLevel = freezed,
    Object? strokeIndexScore = freezed,
    Object? strokeIndexLevel = freezed,
    Object? coldIndexScore = freezed,
    Object? coldIndexLevel = freezed,
    Object? foodPoisoningIndex = freezed,
    Object? foodPoisoningRisk = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            apparentTemperature:
                freezed == apparentTemperature
                    ? _value.apparentTemperature
                    : apparentTemperature // ignore: cast_nullable_to_non_nullable
                        as double?,
            apparentTempRiskStatus:
                freezed == apparentTempRiskStatus
                    ? _value.apparentTempRiskStatus
                    : apparentTempRiskStatus // ignore: cast_nullable_to_non_nullable
                        as String?,
            aliScore:
                freezed == aliScore
                    ? _value.aliScore
                    : aliScore // ignore: cast_nullable_to_non_nullable
                        as double?,
            aliLevel:
                freezed == aliLevel
                    ? _value.aliLevel
                    : aliLevel // ignore: cast_nullable_to_non_nullable
                        as int?,
            strokeIndexScore:
                freezed == strokeIndexScore
                    ? _value.strokeIndexScore
                    : strokeIndexScore // ignore: cast_nullable_to_non_nullable
                        as double?,
            strokeIndexLevel:
                freezed == strokeIndexLevel
                    ? _value.strokeIndexLevel
                    : strokeIndexLevel // ignore: cast_nullable_to_non_nullable
                        as int?,
            coldIndexScore:
                freezed == coldIndexScore
                    ? _value.coldIndexScore
                    : coldIndexScore // ignore: cast_nullable_to_non_nullable
                        as double?,
            coldIndexLevel:
                freezed == coldIndexLevel
                    ? _value.coldIndexLevel
                    : coldIndexLevel // ignore: cast_nullable_to_non_nullable
                        as int?,
            foodPoisoningIndex:
                freezed == foodPoisoningIndex
                    ? _value.foodPoisoningIndex
                    : foodPoisoningIndex // ignore: cast_nullable_to_non_nullable
                        as double?,
            foodPoisoningRisk:
                freezed == foodPoisoningRisk
                    ? _value.foodPoisoningRisk
                    : foodPoisoningRisk // ignore: cast_nullable_to_non_nullable
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
abstract class _$$IndexingDataImplCopyWith<$Res>
    implements $IndexingDataCopyWith<$Res> {
  factory _$$IndexingDataImplCopyWith(
    _$IndexingDataImpl value,
    $Res Function(_$IndexingDataImpl) then,
  ) = __$$IndexingDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
    double? apparentTemperature,
    @JsonKey(name: 'risk_status') String? apparentTempRiskStatus,
    @JsonKey(name: 'ali_score', fromJson: parseDouble) double? aliScore,
    @JsonKey(name: 'ali_level', fromJson: parseInt) int? aliLevel,
    @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
    double? strokeIndexScore,
    @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
    int? strokeIndexLevel,
    @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
    double? coldIndexScore,
    @JsonKey(name: 'cold_index_level', fromJson: parseInt) int? coldIndexLevel,
    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    double? foodPoisoningIndex,
    @JsonKey(name: 'food_poisoning_risk') String? foodPoisoningRisk,
    String? error,
  });
}

/// @nodoc
class __$$IndexingDataImplCopyWithImpl<$Res>
    extends _$IndexingDataCopyWithImpl<$Res, _$IndexingDataImpl>
    implements _$$IndexingDataImplCopyWith<$Res> {
  __$$IndexingDataImplCopyWithImpl(
    _$IndexingDataImpl _value,
    $Res Function(_$IndexingDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IndexingData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apparentTemperature = freezed,
    Object? apparentTempRiskStatus = freezed,
    Object? aliScore = freezed,
    Object? aliLevel = freezed,
    Object? strokeIndexScore = freezed,
    Object? strokeIndexLevel = freezed,
    Object? coldIndexScore = freezed,
    Object? coldIndexLevel = freezed,
    Object? foodPoisoningIndex = freezed,
    Object? foodPoisoningRisk = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$IndexingDataImpl(
        apparentTemperature:
            freezed == apparentTemperature
                ? _value.apparentTemperature
                : apparentTemperature // ignore: cast_nullable_to_non_nullable
                    as double?,
        apparentTempRiskStatus:
            freezed == apparentTempRiskStatus
                ? _value.apparentTempRiskStatus
                : apparentTempRiskStatus // ignore: cast_nullable_to_non_nullable
                    as String?,
        aliScore:
            freezed == aliScore
                ? _value.aliScore
                : aliScore // ignore: cast_nullable_to_non_nullable
                    as double?,
        aliLevel:
            freezed == aliLevel
                ? _value.aliLevel
                : aliLevel // ignore: cast_nullable_to_non_nullable
                    as int?,
        strokeIndexScore:
            freezed == strokeIndexScore
                ? _value.strokeIndexScore
                : strokeIndexScore // ignore: cast_nullable_to_non_nullable
                    as double?,
        strokeIndexLevel:
            freezed == strokeIndexLevel
                ? _value.strokeIndexLevel
                : strokeIndexLevel // ignore: cast_nullable_to_non_nullable
                    as int?,
        coldIndexScore:
            freezed == coldIndexScore
                ? _value.coldIndexScore
                : coldIndexScore // ignore: cast_nullable_to_non_nullable
                    as double?,
        coldIndexLevel:
            freezed == coldIndexLevel
                ? _value.coldIndexLevel
                : coldIndexLevel // ignore: cast_nullable_to_non_nullable
                    as int?,
        foodPoisoningIndex:
            freezed == foodPoisoningIndex
                ? _value.foodPoisoningIndex
                : foodPoisoningIndex // ignore: cast_nullable_to_non_nullable
                    as double?,
        foodPoisoningRisk:
            freezed == foodPoisoningRisk
                ? _value.foodPoisoningRisk
                : foodPoisoningRisk // ignore: cast_nullable_to_non_nullable
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
class _$IndexingDataImpl implements _IndexingData {
  _$IndexingDataImpl({
    @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
    this.apparentTemperature,
    @JsonKey(name: 'risk_status') this.apparentTempRiskStatus,
    @JsonKey(name: 'ali_score', fromJson: parseDouble) this.aliScore,
    @JsonKey(name: 'ali_level', fromJson: parseInt) this.aliLevel,
    @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
    this.strokeIndexScore,
    @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
    this.strokeIndexLevel,
    @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
    this.coldIndexScore,
    @JsonKey(name: 'cold_index_level', fromJson: parseInt) this.coldIndexLevel,
    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    this.foodPoisoningIndex,
    @JsonKey(name: 'food_poisoning_risk') this.foodPoisoningRisk,
    this.error,
  });

  factory _$IndexingDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$IndexingDataImplFromJson(json);

  @override
  @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
  final double? apparentTemperature;
  @override
  @JsonKey(name: 'risk_status')
  final String? apparentTempRiskStatus;
  @override
  @JsonKey(name: 'ali_score', fromJson: parseDouble)
  final double? aliScore;
  @override
  @JsonKey(name: 'ali_level', fromJson: parseInt)
  final int? aliLevel;
  @override
  @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
  final double? strokeIndexScore;
  @override
  @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
  final int? strokeIndexLevel;
  @override
  @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
  final double? coldIndexScore;
  @override
  @JsonKey(name: 'cold_index_level', fromJson: parseInt)
  final int? coldIndexLevel;
  @override
  @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
  final double? foodPoisoningIndex;
  @override
  @JsonKey(name: 'food_poisoning_risk')
  final String? foodPoisoningRisk;
  @override
  final String? error;

  @override
  String toString() {
    return 'IndexingData(apparentTemperature: $apparentTemperature, apparentTempRiskStatus: $apparentTempRiskStatus, aliScore: $aliScore, aliLevel: $aliLevel, strokeIndexScore: $strokeIndexScore, strokeIndexLevel: $strokeIndexLevel, coldIndexScore: $coldIndexScore, coldIndexLevel: $coldIndexLevel, foodPoisoningIndex: $foodPoisoningIndex, foodPoisoningRisk: $foodPoisoningRisk, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IndexingDataImpl &&
            (identical(other.apparentTemperature, apparentTemperature) ||
                other.apparentTemperature == apparentTemperature) &&
            (identical(other.apparentTempRiskStatus, apparentTempRiskStatus) ||
                other.apparentTempRiskStatus == apparentTempRiskStatus) &&
            (identical(other.aliScore, aliScore) ||
                other.aliScore == aliScore) &&
            (identical(other.aliLevel, aliLevel) ||
                other.aliLevel == aliLevel) &&
            (identical(other.strokeIndexScore, strokeIndexScore) ||
                other.strokeIndexScore == strokeIndexScore) &&
            (identical(other.strokeIndexLevel, strokeIndexLevel) ||
                other.strokeIndexLevel == strokeIndexLevel) &&
            (identical(other.coldIndexScore, coldIndexScore) ||
                other.coldIndexScore == coldIndexScore) &&
            (identical(other.coldIndexLevel, coldIndexLevel) ||
                other.coldIndexLevel == coldIndexLevel) &&
            (identical(other.foodPoisoningIndex, foodPoisoningIndex) ||
                other.foodPoisoningIndex == foodPoisoningIndex) &&
            (identical(other.foodPoisoningRisk, foodPoisoningRisk) ||
                other.foodPoisoningRisk == foodPoisoningRisk) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    apparentTemperature,
    apparentTempRiskStatus,
    aliScore,
    aliLevel,
    strokeIndexScore,
    strokeIndexLevel,
    coldIndexScore,
    coldIndexLevel,
    foodPoisoningIndex,
    foodPoisoningRisk,
    error,
  );

  /// Create a copy of IndexingData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IndexingDataImplCopyWith<_$IndexingDataImpl> get copyWith =>
      __$$IndexingDataImplCopyWithImpl<_$IndexingDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IndexingDataImplToJson(this);
  }
}

abstract class _IndexingData implements IndexingData {
  factory _IndexingData({
    @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
    final double? apparentTemperature,
    @JsonKey(name: 'risk_status') final String? apparentTempRiskStatus,
    @JsonKey(name: 'ali_score', fromJson: parseDouble) final double? aliScore,
    @JsonKey(name: 'ali_level', fromJson: parseInt) final int? aliLevel,
    @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
    final double? strokeIndexScore,
    @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
    final int? strokeIndexLevel,
    @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
    final double? coldIndexScore,
    @JsonKey(name: 'cold_index_level', fromJson: parseInt)
    final int? coldIndexLevel,
    @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
    final double? foodPoisoningIndex,
    @JsonKey(name: 'food_poisoning_risk') final String? foodPoisoningRisk,
    final String? error,
  }) = _$IndexingDataImpl;

  factory _IndexingData.fromJson(Map<String, dynamic> json) =
      _$IndexingDataImpl.fromJson;

  @override
  @JsonKey(name: 'apparent_temperature', fromJson: parseDouble)
  double? get apparentTemperature;
  @override
  @JsonKey(name: 'risk_status')
  String? get apparentTempRiskStatus;
  @override
  @JsonKey(name: 'ali_score', fromJson: parseDouble)
  double? get aliScore;
  @override
  @JsonKey(name: 'ali_level', fromJson: parseInt)
  int? get aliLevel;
  @override
  @JsonKey(name: 'stroke_index_score', fromJson: parseDouble)
  double? get strokeIndexScore;
  @override
  @JsonKey(name: 'stroke_index_level', fromJson: parseInt)
  int? get strokeIndexLevel;
  @override
  @JsonKey(name: 'cold_index_score', fromJson: parseDouble)
  double? get coldIndexScore;
  @override
  @JsonKey(name: 'cold_index_level', fromJson: parseInt)
  int? get coldIndexLevel;
  @override
  @JsonKey(name: 'food_poisoning_index', fromJson: parseDouble)
  double? get foodPoisoningIndex;
  @override
  @JsonKey(name: 'food_poisoning_risk')
  String? get foodPoisoningRisk;
  @override
  String? get error;

  /// Create a copy of IndexingData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IndexingDataImplCopyWith<_$IndexingDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
