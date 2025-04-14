import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

class ApiService {
  final String _baseUrl = backendUrl; // 상수 사용

  // /api/index 호출
  Future<Map<String, dynamic>> fetchIndexData(
    double latitude,
    double longitude, {
    int? age,
  }) async {
    final Map<String, String> queryParams = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (age != null) 'age': age.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/api/index',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        // UTF-8 디코딩 후 JSON 파싱
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load index data: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print("Error fetching index data: $e");
      throw Exception('Failed to connect or fetch index data: $e');
    }
  }

  // /api/map 호출
  Future<String> fetchMapHtml(
    double latitude,
    double longitude,
    String disasterType, {
    int? age,
  }) async {
    final Map<String, String> queryParams = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'disaster_type': disasterType, // API 파라미터 이름 확인 필요
      if (age != null) 'age': age.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/api/map',
    ).replace(queryParameters: queryParams);

    try {
      // 지도 로딩은 더 오래 걸릴 수 있으므로 타임아웃 증가
      final response = await http.get(uri).timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        // 백엔드 응답에서 실제 HTML 문자열이 있는 키 확인 필요
        return decodedData['shelter_map_html'] as String? ??
            ''; // Null 또는 빈 값 처리
      } else {
        throw Exception(
          'Failed to load map data for $disasterType: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print("Error fetching map data for $disasterType: $e");
      throw Exception(
        'Failed to connect or fetch map data for $disasterType: $e',
      );
    }
  }
}
