// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart'; // defaultRadiusKm 사용
// 모델 import
import '../models/response/health_indices_response.dart';
import '../models/response/env_map_response.dart';
import '../models/response/shelter_map_response.dart';

class ApiService {
  final http.Client _client;
  final String _baseUrl = ApiConstants.baseUrl;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// 수동으로 URI 생성 (List 파라미터 처리용)
  Uri _buildUriWithListParams(String path, Map<String, dynamic> params) {
    final queryParams = <String, dynamic>{};
    final listParams = <String, List<String>>{};

    // 파라미터를 일반 파라미터와 리스트 파라미터로 분리
    params.forEach((key, value) {
      if (value is List<String>) {
        listParams[key] = value;
      } else if (value != null) {
        queryParams[key] = value.toString();
      }
    });

    // 기본 URI 생성
    var uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    // 리스트 파라미터 추가 (key=value1&key=value2 형태)
    listParams.forEach((key, values) {
      if (values.isNotEmpty) {
        // 기존 쿼리 파라미터와 연결
        String queryString = uri.query;
        for (var value in values) {
          final encodedValue = Uri.encodeQueryComponent(value);
          if (queryString.isEmpty) {
            queryString += '$key=$encodedValue';
          } else {
            queryString += '&$key=$encodedValue';
          }
        }
        uri = uri.replace(query: queryString);
      }
    });
    return uri;
  }

  /// 건강 지수 API 호출
  Future<HealthIndicesResponse> getHealthIndices({
    required double latitude,
    required double longitude,
    int? age,
    List<String>? disease,
  }) async {
    // 요청 파라미터 구성 (disease는 List 타입 그대로 전달)
    final params = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (age != null) 'age': age.toString(),
      if (disease != null && disease.isNotEmpty) 'disease': disease, // List 전달
    };

    // URI 생성 (리스트 파라미터 처리 함수 사용)
    final uri = _buildUriWithListParams(
      ApiConstants.healthIndexEndpoint,
      params,
    );

    print('Requesting Health Indices: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        try {
          return HealthIndicesResponse.fromJson(jsonDecode(decodedBody));
        } catch (e) {
          print("JSON Parsing Error (Health Indices): $e");
          print("Received Data: $decodedBody");
          throw Exception("API 응답 데이터 형식이 잘못되었습니다.");
        }
      } else {
        print(
          'Error Response (Health Indices): ${response.statusCode} ${response.body}',
        );
        throw Exception('건강 지수 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching health indices: $e');
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception('서버에 연결할 수 없습니다. 서버 상태를 확인해주세요.');
      }
      throw Exception('건강 지수 정보를 가져오는데 실패했습니다.');
    }
  }

  /// 환경 지도 API 호출 (변경 없음)
  Future<EnvMapResponse> getEnvMap({
    required String envType,
    bool forceRefresh = false,
  }) async {
    final params = {
      'env_type': envType,
      'force_refresh': forceRefresh.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl${ApiConstants.envMapEndpoint}',
    ).replace(queryParameters: params);

    print('Requesting Env Map: $uri');

    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        try {
          return EnvMapResponse.fromJson(jsonDecode(decodedBody));
        } catch (e) {
          print("JSON Parsing Error (Env Map): $e");
          print("Received Data: $decodedBody");
          throw Exception("API 응답 데이터 형식이 잘못되었습니다.");
        }
      } else {
        print(
          'Error Response (Env Map): ${response.statusCode} ${response.body}',
        );
        throw Exception('환경 지도 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching env map: $e');
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception('서버에 연결할 수 없습니다. 서버 상태를 확인해주세요.');
      }
      throw Exception('환경 지도 정보를 가져오는데 실패했습니다.');
    }
  }

  /// 대피소 지도 API 호출 (변경 없음)
  Future<ShelterMapResponse> getShelterMap({
    required double latitude,
    required double longitude,
    required String disasterType,
    double radiusKm = AppConstants.defaultRadiusKm, // 기본 반경 사용
  }) async {
    final params = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'disaster_type': disasterType,
      'radius_km': radiusKm.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl${ApiConstants.shelterMapEndpoint}',
    ).replace(queryParameters: params);

    print('Requesting Shelter Map: $uri');

    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        try {
          return ShelterMapResponse.fromJson(jsonDecode(decodedBody));
        } catch (e) {
          print("JSON Parsing Error (Shelter Map): $e");
          print("Received Data: $decodedBody");
          throw Exception("API 응답 데이터 형식이 잘못되었습니다.");
        }
      } else {
        print(
          'Error Response (Shelter Map): ${response.statusCode} ${response.body}',
        );
        throw Exception('대피소 지도 로딩 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching shelter map: $e');
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception('네트워크 연결을 확인해주세요.');
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception('서버에 연결할 수 없습니다. 서버 상태를 확인해주세요.');
      }
      throw Exception('대피소 지도 정보를 가져오는데 실패했습니다.');
    }
  }
}
