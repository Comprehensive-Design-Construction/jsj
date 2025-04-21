// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$environmentMapHash() => r'd92d4ab7fb221dcec649baa533afdd863d275cf0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
///
/// Copied from [environmentMap].
@ProviderFor(environmentMap)
const environmentMapProvider = EnvironmentMapFamily();

/// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
///
/// Copied from [environmentMap].
class EnvironmentMapFamily extends Family<AsyncValue<EnvMapResponse>> {
  /// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
  ///
  /// Copied from [environmentMap].
  const EnvironmentMapFamily();

  /// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
  ///
  /// Copied from [environmentMap].
  EnvironmentMapProvider call(String envType) {
    return EnvironmentMapProvider(envType);
  }

  @override
  EnvironmentMapProvider getProviderOverride(
    covariant EnvironmentMapProvider provider,
  ) {
    return call(provider.envType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'environmentMapProvider';
}

/// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
///
/// Copied from [environmentMap].
class EnvironmentMapProvider extends AutoDisposeFutureProvider<EnvMapResponse> {
  /// 환경 지도 데이터를 환경 유형(`envType`)별로 가져오는 프로바이더 (Family 사용)
  ///
  /// Copied from [environmentMap].
  EnvironmentMapProvider(String envType)
    : this._internal(
        (ref) => environmentMap(ref as EnvironmentMapRef, envType),
        from: environmentMapProvider,
        name: r'environmentMapProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$environmentMapHash,
        dependencies: EnvironmentMapFamily._dependencies,
        allTransitiveDependencies:
            EnvironmentMapFamily._allTransitiveDependencies,
        envType: envType,
      );

  EnvironmentMapProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.envType,
  }) : super.internal();

  final String envType;

  @override
  Override overrideWith(
    FutureOr<EnvMapResponse> Function(EnvironmentMapRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EnvironmentMapProvider._internal(
        (ref) => create(ref as EnvironmentMapRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        envType: envType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<EnvMapResponse> createElement() {
    return _EnvironmentMapProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EnvironmentMapProvider && other.envType == envType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, envType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EnvironmentMapRef on AutoDisposeFutureProviderRef<EnvMapResponse> {
  /// The parameter `envType` of this provider.
  String get envType;
}

class _EnvironmentMapProviderElement
    extends AutoDisposeFutureProviderElement<EnvMapResponse>
    with EnvironmentMapRef {
  _EnvironmentMapProviderElement(super.provider);

  @override
  String get envType => (origin as EnvironmentMapProvider).envType;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
