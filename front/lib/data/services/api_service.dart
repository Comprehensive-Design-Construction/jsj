import 'dart:convert';
import 'dart:async'; // Timer 사용 (선택적: 주기적 캐시 정리)
import 'package:http/http.dart' as http;

// 상수 import
import '../../core/constants/app_constants.dart';

// API 모델 import
import '../models/api/health_index_response.dart';
import '../models/api/weather_response.dart';
import '../models/api/region_fine_dust_response.dart';
import '../models/api/region_uv_response.dart';
import '../models/api/env_map_response.dart';
import '../models/api/map_api_response.dart';
import '../models/api/coordinates_response.dart';

// --- 캐시 항목 클래스 ---
class _CacheEntry {
  final dynamic data; // JSON 디코딩된 데이터 저장
  final DateTime expiryTime;

  _CacheEntry({required this.data, required this.expiryTime});

  bool get isValid => DateTime.now().isBefore(expiryTime);
}
// ---------------------

class ApiService {
  final String _baseUrl = baseUrl;
  final Duration _defaultTimeout = apiTimeout;
  final Duration _mapTimeout = mapApiTimeout;

  // --- 인메모리 캐시 ---
  final Map<String, _CacheEntry> _cache = {};
  // ------------------

  // --- 캐시 TTL 정의 (API 종류별) ---
  static const Duration _shortCacheTTL = Duration(minutes: 5); // 날씨, 건강 지수 등
  static const Duration _mediumCacheTTL = Duration(minutes: 30); // 지도 등
  static const Duration _longCacheTTL = Duration(hours: 1); // 구/동 목록 등
  // --------------------------------

  // --- 캐시 키 생성 헬퍼 ---
  String _generateCacheKey(String endpoint, Map<String, dynamic> params) {
    // 파라미터를 정렬하여 순서에 관계없이 동일한 키 생성
    final sortedKeys = params.keys.toList()..sort();
    final sortedParams = sortedKeys
        .map((key) => '$key=${params[key].toString()}')
        .join('&');
    return '$endpoint?$sortedParams';
  }
  // ----------------------

  // --- 공통 HTTP GET 요청 함수 (캐싱 로직 추가) ---
  Future<dynamic> _get(
    String endpoint,
    Map<String, dynamic> queryParameters, {
    Duration? timeout,
    Duration? cacheTTL, // 캐시 TTL 파라미터 추가
    bool forceRefresh = false, // 캐시 무시 옵션
  }) async {
    final cacheKey = _generateCacheKey(endpoint, queryParameters);

    // 1. 캐시 확인 (forceRefresh가 아니고, TTL이 지정된 경우)
    if (!forceRefresh && cacheTTL != null && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (entry.isValid) {
        print('Cache HIT: $cacheKey');
        return entry.data; // 유효한 캐시 반환
      } else {
        print('Cache EXPIRED: $cacheKey');
        _cache.remove(cacheKey); // 만료된 캐시 제거
      }
    } else if (cacheTTL != null) {
      print('Cache MISS: $cacheKey (ForceRefresh: $forceRefresh)');
    }

    // 2. 네트워크 요청
    final uri = _buildUriWithListParams('$_baseUrl$endpoint', queryParameters);
    print('Requesting API: $uri');
    try {
      final response = await http.get(uri).timeout(timeout ?? _defaultTimeout);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // 3. 성공 시 캐시 저장 (TTL이 지정된 경우)
        if (cacheTTL != null) {
          final expiryTime = DateTime.now().add(cacheTTL);
          _cache[cacheKey] = _CacheEntry(
            data: decodedData,
            expiryTime: expiryTime,
          );
          print('Cached response for: $cacheKey until $expiryTime');
        }
        return decodedData;
      } else {
        throw Exception(
          'API Error ($endpoint): ${response.statusCode}, Body: ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('Error requesting $endpoint: $e');
      throw Exception('Failed to connect to API ($endpoint): $e');
    }
  }

  // --- URI 수동 구성 헬퍼 (List 파라미터 처리) ---
  Uri _buildUriWithListParams(String url, Map<String, dynamic> params) {
    final queryParts = <String>[];
    print("[DEBUG] Building URI for $url with params: $params"); // 함수 시작 로그
    params.forEach((key, value) {
      // <<< 각 파라미터 타입과 값 확인 로그 >>>
      print(
        "[DEBUG] _buildUri: Processing key='$key', value='$value', type=${value.runtimeType}",
      );
      // ------------------------------------
      try {
        // 혹시 모를 예외 처리 추가
        if (value is List) {
          print("  - Value is List. Iterating..."); // 리스트 처리 시작 로그
          if (value.isEmpty) {
            print(
              "  - List is empty. Skipping parameter '$key'.",
            ); // 빈 리스트 처리 로그
            // 빈 리스트는 쿼리 파라미터에 포함하지 않거나, 특정 방식으로 처리 (백엔드 협의 필요)
            // 예: queryParts.add('${Uri.encodeComponent(key)}='); // 빈 값으로 추가?
          } else {
            for (var item in value) {
              // 여기서 int에 대한 오류가 발생한다고 의심됨
              queryParts.add(
                '${Uri.encodeComponent(key)}=${Uri.encodeComponent(item.toString())}',
              );
            }
            print("  - Added list items for '$key'."); // 리스트 처리 완료 로그
          }
        } else if (value != null) {
          print("  - Value is not List. Adding directly."); // 단일 값 처리 로그
          queryParts.add(
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}',
          );
        } else {
          print("  - Value is null for key '$key'. Skipping."); // null 값 처리 로그
        }
      } catch (e, s) {
        // 루프 내에서 예외 발생 시 로그 출력
        print(
          "[ERROR] Exception during URI param processing for key='$key', value='$value': $e",
        );
        print("  - Stacktrace: $s");
      }
    });
    final queryString = queryParts.join('&');
    final finalUri = Uri.parse(
      '$url${queryString.isNotEmpty ? '?' : ''}$queryString',
    );
    print("[DEBUG] Built URI: $finalUri"); // 최종 생성된 URI 로그
    return finalUri;
  }

  // --- 건강 지수 API ---
  Future<HealthIndexResponse> fetchHealthIndex(
    double latitude,
    double longitude, {
    int? age,
    List<String>? disease,
    String? userType,
  }) async {
    List<String> userTypeList = [];
    if (userType != null && userType != '없음') {
      userTypeList.add(userType); // 단일 항목 리스트
    }
    final Map<String, dynamic> queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'age': age ?? "0",
      // List<String> 파라미터 처리: 각 요소를 별도의 파라미터로 전달 (FastAPI List Query 파라미터 방식)
      // 백엔드에서 `Query([])` 또는 `Query(None)` 등으로 받는지 확인 필요.
      // 만약 백엔드가 쉼표 구분 문자열을 기대한다면 이전 방식 사용: 'disease': disease.join(',')
      // 여기서는 FastAPI 표준 방식(파라미터 반복)을 가정하지 않고, 이전의 쉼표 구분 방식을 주석으로 남겨둡니다.
      if (disease != null && disease.isNotEmpty)
        'disease': disease.join(','), // 백엔드가 쉼표 구분 문자열을 처리할 경우
      'user_type': userTypeList,
    };
    // disease 리스트를 쿼리 파라미터에 추가 (FastAPI 스타일)
    if (disease != null) {
      for (var d in disease) {
        queryParameters['disease'] = d; // 같은 키로 여러 번 추가 (FastAPI가 리스트로 인식)
      }
    }

    // _get 헬퍼 함수 사용
    final decodedJson = await _get(
      healthIndexEndpoint,
      queryParameters,
      cacheTTL: _shortCacheTTL,
    );
    return HealthIndexResponse.fromJson(decodedJson);
  }

  // --- 상세 날씨 API (캐싱 적용) ---
  Future<WeatherDetailResponse> fetchWeather(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final decodedJson = await _get(
      weatherEndpoint,
      queryParameters,
      cacheTTL: _shortCacheTTL,
    );
    return WeatherDetailResponse.fromJson(decodedJson);
  }

  // --- 지역별 미세먼지 API (캐싱 적용) ---
  Future<SingleRegionFineDustResponse> fetchFineDust(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final decodedJson = await _get(
      fineDustEndpoint,
      queryParameters,
      cacheTTL: _shortCacheTTL,
    );
    return SingleRegionFineDustResponse.fromJson(decodedJson);
  }

  // --- 지역별 UV 지수 API (캐싱 적용) ---
  Future<SingleRegionUvResponse> fetchUv(
    double latitude,
    double longitude,
  ) async {
    final queryParameters = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    final decodedJson = await _get(
      uvEndpoint,
      queryParameters,
      cacheTTL: _shortCacheTTL,
    );
    return SingleRegionUvResponse.fromJson(decodedJson);
  }

  // --- 환경 지도 API (캐싱 적용, forceRefresh 처리) ---
  Future<EnvMapApiResponse> fetchEnvMap(
    String envType, {
    bool forceRefresh = false, // 파라미터 받음
  }) async {
    final queryParameters = {
      'env_type': envType,
      'force_refresh': forceRefresh.toString(),
    };
    // forceRefresh 옵션 전달
    final decodedJson = await _get(
      envMapEndpoint,
      queryParameters,
      timeout: _mapTimeout,
      cacheTTL: _mediumCacheTTL,
      forceRefresh: forceRefresh,
    );
    return EnvMapApiResponse.fromJson(decodedJson);
  }

  // --- 대피소 지도 API (캐싱 적용, forceRefresh 처리) ---
  Future<MapApiResponse> fetchShelterMap(
    double latitude,
    double longitude,
    String disasterType, {
    double radiusKm = 1.5,
    bool forceRefresh = false, // 파라미터 받음
  }) async {
    final queryParameters = {
      /* ... 파라미터 설정 ... */
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'disaster_type': disasterType,
      'radius_km': radiusKm.toString(),
      'force_refresh': forceRefresh.toString(),
    };
    // forceRefresh 옵션 전달
    final decodedJson = await _get(
      shelterMapEndpoint,
      queryParameters,
      timeout: _mapTimeout,
      cacheTTL: _mediumCacheTTL,
      forceRefresh: forceRefresh,
    );
    return MapApiResponse.fromJson(decodedJson);
  }

  /// 서울시 전체 '구' 목록 가져오기 (캐싱 적용)
  Future<List<String>> fetchGuList() async {
    final decodedJson = await _get(
      districtsEndpoint,
      {},
      cacheTTL: _longCacheTTL,
    );
    final List<dynamic> districtListDynamics = decodedJson['districts'];
    return districtListDynamics.cast<String>().toList();
  }

  /// 특정 '구'에 속하는 '동' 목록 가져오기 (캐싱 적용)
  Future<List<String>> fetchDongList(String gu) async {
    final queryParameters = {'gu': gu};
    try {
      final decodedJson = await _get(
        dongsEndpoint,
        queryParameters,
        cacheTTL: _longCacheTTL,
      );
      final List<dynamic> dongListDynamics = decodedJson['dongs'];
      return dongListDynamics.cast<String>().toList();
    } on Exception catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      rethrow;
    }
  }

  /// '구'와 '동' 이름으로 위경도 좌표 가져오기 (캐싱 적용)
  Future<CoordinatesResponse> fetchCoordinates(String gu, String dong) async {
    final queryParameters = {'gu': gu, 'dong': dong};
    try {
      final decodedJson = await _get(
        coordinatesEndpoint,
        queryParameters,
        cacheTTL: _longCacheTTL,
      );
      return CoordinatesResponse.fromJson(decodedJson);
    } on Exception catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Coordinates not found for $gu $dong (404)');
      }
      rethrow;
    }
  }

  /// 행동 요령 정보 가져오기 (POST 요청)
  Future<String> fetchRecommendation({
    required String indexType,
    required String indexLevel,
    required int? age,
    required String? workingType,
    required List<String>? diseases,
    required bool? isPregnant,
  }) async {
    final uri = Uri.parse('$_baseUrl$recommendationEndpoint');
    final body = jsonEncode({
      'index_type': indexType,
      'index_level': indexLevel,
      'age': age ?? "0",
      // 'working_type': workingType, // 백엔드 모델에 맞게 키 이름 확인 필요! (request_models.py 에는 있음)
      'diseases': diseases ?? [],
      'is_pregnant': isPregnant ?? false,
      // 백엔드 Request 모델에 'working_type'이 있으므로 추가
      if (workingType != null && workingType != '없음')
        'working_type': workingType,
    });
    final headers = {'Content-Type': 'application/json'};

    print('Requesting Recommendation: $uri with body: $body');

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(responseBody);
        // 백엔드 응답에서 실제 행동 요령 텍스트 키 확인 (response_models.py 에는 'recommendation')
        return decoded['recommendation'] as String? ?? '행동 요령 정보를 불러올 수 없습니다.';
      } else {
        // API 에러 응답 처리
        String errorMsg =
            'Failed to load recommendation: ${response.statusCode}';
        try {
          final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (decodedBody['detail'] != null) {
            errorMsg += '\nDetail: ${decodedBody['detail']}';
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Error fetchRecommendation: $e');
      throw Exception('행동 요령 로드 실패: $e');
    }
  }

  // --- (선택적) 캐시 정리 로직 ---
  // 주기적으로 만료된 캐시를 정리하거나, 메모리 부족 시 정리하는 로직 추가 가능
  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => !entry.isValid);
    print("Cleared expired cache entries.");
  }

  void clearAllCache() {
    _cache.clear();
    print("Cleared all cache entries.");
  }

  // ---------------------------
}
