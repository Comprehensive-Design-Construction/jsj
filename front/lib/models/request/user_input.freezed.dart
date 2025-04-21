// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserInput _$UserInputFromJson(Map<String, dynamic> json) {
  return _UserInput.fromJson(json);
}

/// @nodoc
mixin _$UserInput {
  int? get age => throw _privateConstructorUsedError; // Optional
  List<String> get disease => throw _privateConstructorUsedError;

  /// Serializes this UserInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserInputCopyWith<UserInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserInputCopyWith<$Res> {
  factory $UserInputCopyWith(UserInput value, $Res Function(UserInput) then) =
      _$UserInputCopyWithImpl<$Res, UserInput>;
  @useResult
  $Res call({int? age, List<String> disease});
}

/// @nodoc
class _$UserInputCopyWithImpl<$Res, $Val extends UserInput>
    implements $UserInputCopyWith<$Res> {
  _$UserInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? age = freezed, Object? disease = null}) {
    return _then(
      _value.copyWith(
            age:
                freezed == age
                    ? _value.age
                    : age // ignore: cast_nullable_to_non_nullable
                        as int?,
            disease:
                null == disease
                    ? _value.disease
                    : disease // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserInputImplCopyWith<$Res>
    implements $UserInputCopyWith<$Res> {
  factory _$$UserInputImplCopyWith(
    _$UserInputImpl value,
    $Res Function(_$UserInputImpl) then,
  ) = __$$UserInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? age, List<String> disease});
}

/// @nodoc
class __$$UserInputImplCopyWithImpl<$Res>
    extends _$UserInputCopyWithImpl<$Res, _$UserInputImpl>
    implements _$$UserInputImplCopyWith<$Res> {
  __$$UserInputImplCopyWithImpl(
    _$UserInputImpl _value,
    $Res Function(_$UserInputImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? age = freezed, Object? disease = null}) {
    return _then(
      _$UserInputImpl(
        age:
            freezed == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                    as int?,
        disease:
            null == disease
                ? _value._disease
                : disease // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserInputImpl implements _UserInput {
  const _$UserInputImpl({this.age, final List<String> disease = const []})
    : _disease = disease;

  factory _$UserInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserInputImplFromJson(json);

  @override
  final int? age;
  // Optional
  final List<String> _disease;
  // Optional
  @override
  @JsonKey()
  List<String> get disease {
    if (_disease is EqualUnmodifiableListView) return _disease;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disease);
  }

  @override
  String toString() {
    return 'UserInput(age: $age, disease: $disease)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserInputImpl &&
            (identical(other.age, age) || other.age == age) &&
            const DeepCollectionEquality().equals(other._disease, _disease));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    age,
    const DeepCollectionEquality().hash(_disease),
  );

  /// Create a copy of UserInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserInputImplCopyWith<_$UserInputImpl> get copyWith =>
      __$$UserInputImplCopyWithImpl<_$UserInputImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserInputImplToJson(this);
  }
}

abstract class _UserInput implements UserInput {
  const factory _UserInput({final int? age, final List<String> disease}) =
      _$UserInputImpl;

  factory _UserInput.fromJson(Map<String, dynamic> json) =
      _$UserInputImpl.fromJson;

  @override
  int? get age; // Optional
  @override
  List<String> get disease;

  /// Create a copy of UserInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserInputImplCopyWith<_$UserInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
