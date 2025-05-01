import 'dart:convert'; // jsonDecode 사용
import 'dart:io'; // SocketException 등 처리
import 'dart:async'; // TimeoutException 처리
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/health_indices.dart';
import '../models/environment_data.dart';
import '../models/map_data.dart';

class ApiService {
  // 백엔드 기본 URL (환경에 따라 설정 파일에서 로드하는 것이 좋음)
  static const String _baseUrl = "http://10.0.0.2:5000/api"; // 로컬 개발 환경 예시

  // 공통 HTTP 요청 헤더 (필요시)
  // final Map<String, String> _headers = {'Content-Type': 'application/json'};

  // 공통 요청 타임아웃
  static const Duration _timeout = Duration(seconds: 15);

  // --- API 호출 메소드 ---

  /// 상세 날씨 정보 가져오기
  Future<WeatherDetailResponse> getWeather(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse('$_baseUrl/weather').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    return _handleApiCall(uri, WeatherDetailResponse.fromJson);
  }

  /// 건강 지수 정보 가져오기
  Future<HealthIndexResponse> getHealthIndices(
    double latitude,
    double longitude,
    int? age,
    List<String> diseases,
  ) async {
    final Map<String, String> params = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (age != null) params['age'] = age.toString();
    // List<String>을 쿼리 파라미터로 보내는 방식 확인 필요 (http 패키지는 기본 지원 안 할 수 있음)
    // FastAPI는 ?disease=a&disease=b 형태로 받음
    // 직접 URL 구성 또는 dio 패키지 사용 고려
    String diseaseQuery = diseases
        .map((d) => 'disease=${Uri.encodeComponent(d)}')
        .join('&');
    final url =
        '$_baseUrl/index?${Uri(queryParameters: params).query}&$diseaseQuery';
    final uri = Uri.parse(url);

    return _handleApiCall(uri, HealthIndexResponse.fromJson);
  }

  /// 지역별 UV 지수 가져오기
  Future<SingleRegionUvResponse> getRegionalUv(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse('$_baseUrl/environment/uv').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    return _handleApiCall(uri, SingleRegionUvResponse.fromJson);
  }

  /// 지역별 미세먼지 데이터 가져오기
  Future<SingleRegionFineDustResponse> getRegionalFineDust(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse('$_baseUrl/environment/fine_dust').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    return _handleApiCall(uri, SingleRegionFineDustResponse.fromJson);
  }

  /// 대피소 지도 HTML 가져오기
  Future<MapApiResponse> getShelterMapHtml(
    double latitude,
    double longitude,
    String disasterType,
    double radiusKm,
    bool forceRefresh,
  ) async {
    final uri = Uri.parse('$_baseUrl/map').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'disaster_type': disasterType,
        'radius_km': radiusKm.toString(),
        'force_refresh': forceRefresh.toString(),
      },
    );
    // MapApiResponse가 models 폴더에 정의되어 있다고 가정
    return _handleApiCall(uri, MapApiResponse.fromJson);
  }

  /// 환경 지도 HTML 가져오기
  Future<EnvMapApiResponse> getEnvMapHtml(
    String envType,
    bool forceRefresh,
  ) async {
    final uri = Uri.parse('$_baseUrl/env_map').replace(
      queryParameters: {
        'env_type': envType,
        'force_refresh': forceRefresh.toString(),
      },
    );
    // EnvMapApiResponse가 models 폴더에 정의되어 있다고 가정
    return _handleApiCall(uri, EnvMapApiResponse.fromJson);
  }

  // --- 공통 API 호출 및 오류 처리 로직 ---
  Future<T> _handleApiCall<T>(
    Uri uri,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      print('API Request: ${uri.toString()}'); // 요청 로깅 (디버깅용)
      final response = await http.get(uri).timeout(_timeout);

      print('API Response Status: ${response.statusCode}'); // 응답 상태 로깅
      // print('API Response Body: ${response.body}'); // 필요시 응답 바디 로깅 (길 수 있음)

      if (response.statusCode == 200) {
        try {
          // UTF-8 디코딩 명시 (한글 깨짐 방지)
          final decodedBody = utf8.decode(response.bodyBytes);
          final jsonData = jsonDecode(decodedBody) as Map<String, dynamic>;
          return fromJson(jsonData); // JSON -> Dart 모델 변환
        } catch (e) {
          print('JSON Parsing Error: $e');
          print('Response Body: ${response.body}'); // 파싱 실패 시 원본 출력
          throw ApiException('API 응답 데이터를 파싱하는 중 오류가 발생했습니다.');
        }
      } else if (response.statusCode == 422) {
        // FastAPI 유효성 검사 오류 처리
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(decodedBody);
        final detail = errorData['detail'] ?? '입력값 오류';
        print('API Validation Error (${response.statusCode}): $detail');
        throw ApiException('입력값 오류: ${detail.toString()}');
      } else {
        // 기타 HTTP 오류 처리
        print('API HTTP Error (${response.statusCode}): ${response.body}');
        throw ApiException('API 요청 실패 (코드: ${response.statusCode})');
      }
    } on SocketException {
      // 네트워크 연결 오류
      print('Network Error');
      throw ApiException('네트워크 연결을 확인해주세요.');
    } on TimeoutException {
      // 타임아웃 오류
      print('Request Timeout');
      throw ApiException('요청 시간이 초과되었습니다.');
    } on ApiException {
      // 직접 발생시킨 API 예외는 그대로 전달
      rethrow;
    } catch (e) {
      // 예상치 못한 기타 오류
      print('Unexpected API Error: $e');
      throw ApiException('알 수 없는 오류가 발생했습니다.');
    }
  }
}

// 커스텀 API 예외
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
