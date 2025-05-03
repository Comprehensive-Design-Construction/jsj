import 'dart:convert';
import 'package:http/http.dart' as http;

// 상수 import
import '../../core/constants/app_constants.dart';

// API 모델 import (경로 수정)
import '../models/api/health_index_response.dart';
import '../models/api/weather_response.dart';
import '../models/api/region_fine_dust_response.dart';
import '../models/api/region_uv_response.dart';
import '../models/api/env_map_response.dart';
import '../models/api/map_api_response.dart';
import '../models/api/coordinates_response.dart';

class ApiService {
  // baseUrl은 app_constants.dart 에서 가져옴
  final String _baseUrl = baseUrl; // from app_constants.dart

  // 타임아웃 설정 (선택 사항)
  final Duration _timeout = const Duration(seconds: 15);
  final Duration _mapTimeout = const Duration(seconds: 25); // 지도 API는 더 길게

  // --- 건강 지수 API ---
  Future<HealthIndexResponse> fetchHealthIndex(
    double latitude,
    double longitude, {
    int? age,
    List<String>? disease,
  }) async {
    final Map<String, String> queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (age != null) 'age': age.toString(),
      // disease: List[str] 처리 - 쉼표 구분 문자열로 전달 시도 (백엔드 확인 필요)
      // TODO: FastAPI에서 List[str] = Query([]) 인 경우 파라미터 반복 필요
      if (disease != null && disease.isNotEmpty) 'disease': disease.join(','),
    };
    final uri = Uri.parse(
      '$_baseUrl/index',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return HealthIndexResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception('Failed to load health index: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchHealthIndex: $e');
      throw Exception('Failed to load health index: $e');
    }
  }

  // --- 상세 날씨 API ---
  Future<WeatherDetailResponse> fetchWeather(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/weather',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return WeatherDetailResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchWeather: $e');
      throw Exception('Failed to load weather: $e');
    }
  }

  // --- 지역별 미세먼지 API ---
  Future<SingleRegionFineDustResponse> fetchFineDust(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/environment/fine_dust',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return SingleRegionFineDustResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception('Failed to load fine dust: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchFineDust: $e');
      throw Exception('Failed to load fine dust: $e');
    }
  }

  // --- 지역별 UV 지수 API ---
  Future<SingleRegionUvResponse> fetchUv(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/environment/uv',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return SingleRegionUvResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception('Failed to load UV: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchUv: $e');
      throw Exception('Failed to load UV: $e');
    }
  }

  // --- 환경 지도 API ---
  Future<EnvMapApiResponse> fetchEnvMap(
    String envType, {
    bool forceRefresh = false,
  }) async {
    final queryParameters = {
      'env_type': envType,
      'force_refresh': forceRefresh.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/env_map',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_mapTimeout); // 지도 타임아웃 증가
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return EnvMapApiResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception(
          'Failed to load env map ($envType): ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchEnvMap ($envType): $e');
      throw Exception('Failed to load env map ($envType): $e');
    }
  }

  // --- 대피소 지도 API ---
  Future<MapApiResponse> fetchShelterMap(
    double latitude,
    double longitude,
    String disasterType, {
    double radiusKm = 1.5,
    bool forceRefresh = false,
  }) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'disaster_type': disasterType,
      'radius_km': radiusKm.toString(),
      'force_refresh': forceRefresh.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/map',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_mapTimeout); // 지도 타임아웃 증가
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return MapApiResponse.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception(
          'Failed to load shelter map ($disasterType): ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchShelterMap ($disasterType): $e');
      throw Exception('Failed to load shelter map ($disasterType): $e');
    }
  }

  /// 서울시 전체 '구' 목록 가져오기
  Future<List<String>> fetchGuList() async {
    final uri = Uri.parse('$_baseUrl/districts');
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> districtListDynamics = decodedData['districts'];
        return districtListDynamics
            .cast<String>()
            .toList(); // List<dynamic> -> List<String>
      } else {
        throw Exception('Failed to load Gu list: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetchGuList: $e');
      throw Exception('Failed to load Gu list: $e');
    }
  }

  /// 특정 '구'에 속하는 '동' 목록 가져오기
  Future<List<String>> fetchDongList(String gu) async {
    final queryParameters = {'gu': gu};
    final uri = Uri.parse(
      '$_baseUrl/dongs',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> districtListDynamics = decodedData['dongs'];
        return districtListDynamics.cast<String>().toList();
      } else if (response.statusCode == 404) {
        print('Dongs not found for Gu: $gu');
        return []; // 404 이면 빈 리스트 반환
      } else {
        throw Exception(
          'Failed to load Dong list for $gu: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchDongList($gu): $e');
      throw Exception('Failed to load Dong list for $gu: $e');
    }
  }

  /// '구'와 '동' 이름으로 위경도 좌표 가져오기
  Future<CoordinatesResponse> fetchCoordinates(String gu, String dong) async {
    final queryParameters = {'gu': gu, 'dong': dong};
    final uri = Uri.parse(
      '$_baseUrl/coordinates',
    ).replace(queryParameters: queryParameters);
    print('Requesting: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return CoordinatesResponse.fromJson(jsonDecode(responseBody));
      } else if (response.statusCode == 404) {
        throw Exception('Coordinates not found for $gu $dong (404)');
      } else {
        throw Exception(
          'Failed to load coordinates for $gu $dong: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetchCoordinates($gu, $dong): $e');
      throw Exception('Failed to load coordinates for $gu $dong: $e');
    }
  }

  // -------------------------------------------
}
