// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelter_map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shelterMapHash() => r'799d71f87d2f126844eb9751e75d2a7ee5723ead';

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

/// See also [shelterMap].
@ProviderFor(shelterMap)
const shelterMapProvider = ShelterMapFamily();

/// See also [shelterMap].
class ShelterMapFamily extends Family<AsyncValue<ShelterMapResponse>> {
  /// See also [shelterMap].
  const ShelterMapFamily();

  /// See also [shelterMap].
  ShelterMapProvider call(String disasterType) {
    return ShelterMapProvider(disasterType);
  }

  @override
  ShelterMapProvider getProviderOverride(
    covariant ShelterMapProvider provider,
  ) {
    return call(provider.disasterType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shelterMapProvider';
}

/// See also [shelterMap].
class ShelterMapProvider extends FutureProvider<ShelterMapResponse> {
  /// See also [shelterMap].
  ShelterMapProvider(String disasterType)
    : this._internal(
        (ref) => shelterMap(ref as ShelterMapRef, disasterType),
        from: shelterMapProvider,
        name: r'shelterMapProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$shelterMapHash,
        dependencies: ShelterMapFamily._dependencies,
        allTransitiveDependencies: ShelterMapFamily._allTransitiveDependencies,
        disasterType: disasterType,
      );

  ShelterMapProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.disasterType,
  }) : super.internal();

  final String disasterType;

  @override
  Override overrideWith(
    FutureOr<ShelterMapResponse> Function(ShelterMapRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShelterMapProvider._internal(
        (ref) => create(ref as ShelterMapRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        disasterType: disasterType,
      ),
    );
  }

  @override
  FutureProviderElement<ShelterMapResponse> createElement() {
    return _ShelterMapProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShelterMapProvider && other.disasterType == disasterType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, disasterType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShelterMapRef on FutureProviderRef<ShelterMapResponse> {
  /// The parameter `disasterType` of this provider.
  String get disasterType;
}

class _ShelterMapProviderElement
    extends FutureProviderElement<ShelterMapResponse>
    with ShelterMapRef {
  _ShelterMapProviderElement(super.provider);

  @override
  String get disasterType => (origin as ShelterMapProvider).disasterType;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
