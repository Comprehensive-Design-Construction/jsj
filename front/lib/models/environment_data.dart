// lib/models/environment_data.dart
import 'package:flutter/foundation.dart' show immutable;
import 'health_indices.dart'; // RegionInfo 재사용

@immutable
class RegionFineDustData {
  final String? grade;
  final int? pm10;
  final int? pm25;
  final String? maxIndex; // GRADE와 유사? API 응답 확인 필요

  const RegionFineDustData({this.grade, this.pm10, this.pm25, this.maxIndex});

  factory RegionFineDustData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegionFineDustData();
    return RegionFineDustData(
      grade: json['GRADE'] as String?,
      pm10: json['PM10'] as int?,
      pm25: json['PM25'] as int?,
      maxIndex: json['MAXINDEX'] as String?,
    );
  }
}

@immutable
class SingleRegionFineDustResponse {
  final Map<String, double>? requestLocation;
  final RegionInfo regionInfo;
  final RegionFineDustData? fineDustData;
  final String? lastUpdated;
  final String? error;

  const SingleRegionFineDustResponse({
    this.requestLocation,
    required this.regionInfo,
    this.fineDustData,
    this.lastUpdated,
    this.error,
  });

  factory SingleRegionFineDustResponse.fromJson(Map<String, dynamic> json) {
    return SingleRegionFineDustResponse(
      requestLocation:
          (json['request_location'] as Map?)?.cast<String, double>(),
      regionInfo: RegionInfo.fromJson(
        json['region_info'] as Map<String, dynamic>?,
      ),
      fineDustData: RegionFineDustData.fromJson(
        json['fine_dust_data'] as Map<String, dynamic>?,
      ),
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}

@immutable
class RegionUvData {
  final int? uvIndex;

  const RegionUvData({this.uvIndex});

  factory RegionUvData.fromJson(Map<String, dynamic>? json) {
    // 백엔드 캐시가 {'uv_index': 5} 형태인지, 아니면 그냥 5 인지 확인 필요
    if (json == null) return const RegionUvData();
    return RegionUvData(uvIndex: json['uv_index'] as int?);
  }
}

@immutable
class SingleRegionUvResponse {
  final Map<String, double>? requestLocation;
  final RegionInfo regionInfo;
  final RegionUvData? uvData;
  final String? lastUpdated;
  final String? error;

  const SingleRegionUvResponse({
    this.requestLocation,
    required this.regionInfo,
    this.uvData,
    this.lastUpdated,
    this.error,
  });

  factory SingleRegionUvResponse.fromJson(Map<String, dynamic> json) {
    return SingleRegionUvResponse(
      requestLocation:
          (json['request_location'] as Map?)?.cast<String, double>(),
      regionInfo: RegionInfo.fromJson(
        json['region_info'] as Map<String, dynamic>?,
      ),
      uvData: RegionUvData.fromJson(json['uv_data'] as Map<String, dynamic>?),
      lastUpdated: json['last_updated'] as String?,
      error: json['error'] as String?,
    );
  }
}
