// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mapCacheHash() => r'd53895ce1622edf4b48c15d868a608b4d7473abe';

/// 지도 HTML 컨텐츠를 위한 간단한 인메모리 캐시 프로바이더
/// key: 'env_fine_dust', 'shelter_EARTHQUAKE' 등
/// value: 지도 HTML 문자열
///
/// Copied from [MapCache].
@ProviderFor(MapCache)
final mapCacheProvider =
    NotifierProvider<MapCache, Map<String, String>>.internal(
      MapCache.new,
      name: r'mapCacheProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product') ? null : _$mapCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MapCache = Notifier<Map<String, String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
