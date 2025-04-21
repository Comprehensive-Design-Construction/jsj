class ApiConstants {
  // TODO: 실제 백엔드 서버 주소로 변경하세요.
  // 로컬 개발 시: 'http://localhost:5000' (iOS 시뮬레이터) 또는 'http://10.0.2.2:5000' (Android 에뮬레이터)
  // 또는 로컬 네트워크 IP 사용 (예: 'http://192.168.0.5:5000')
  static const String baseUrl = 'http://192.168.0.106:5000'; // 여기에 실제 URL 입력

  // API 엔드포인트 경로
  static const String healthIndexEndpoint = '/api/index';
  static const String envMapEndpoint = '/api/env_map';
  static const String shelterMapEndpoint = '/api/map';
}
