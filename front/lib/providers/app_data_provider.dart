import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Position 클래스 사용
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import 'dart:async'; // Future 사용

class AppDataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- 상태 변수 ---
  Position? _currentPosition; // 고정 위치 저장
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _indexData;
  List<dynamic>? _alerts;
  String? _errorMessage;
  bool _isLoadingInitialData = true;

  // 대피소 지도 관련 상태
  final Map<ShelterType, String?> _shelterMapHtmls = {}; // 타입별 HTML 저장
  final Map<ShelterType, bool> _isLoadingMaps = {}; // 타입별 로딩 상태 저장
  final Map<ShelterType, String?> _mapErrorMessages = {}; // 타입별 에러 메시지
  ShelterType _selectedShelterType = ShelterType.HEAT_WAVE; // 기본 선택: 폭염

  // --- Getter ---
  Position? get currentPosition => _currentPosition;
  Map<String, dynamic>? get weatherData => _weatherData;
  Map<String, dynamic>? get indexData => _indexData;
  List<dynamic>? get alerts => _alerts;
  String? get errorMessage => _errorMessage;
  bool get isLoadingInitialData => _isLoadingInitialData;

  Map<ShelterType, String?> get shelterMapHtmls => _shelterMapHtmls;
  Map<ShelterType, bool> get isLoadingMaps => _isLoadingMaps;
  Map<ShelterType, String?> get mapErrorMessages => _mapErrorMessages;
  ShelterType get selectedShelterType => _selectedShelterType;

  // --- 데이터 로드 로직 ---

  // 앱 시작 시 초기 데이터 로드 (날씨/지수 + 모든 지도 백그라운드 로드)
  Future<void> loadInitialData() async {
    _isLoadingInitialData = true;
    _errorMessage = null;
    notifyListeners();

    // 1. 고정 위치 설정
    _currentPosition = Position(
      latitude: fixedLatitude,
      longitude: fixedLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    // 2. 날씨/지수 데이터 가져오기
    try {
      final indexApiResponse = await _apiService.fetchIndexData(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _weatherData = indexApiResponse['weather'];
      _indexData = indexApiResponse['indexing_result'];
      _alerts = indexApiResponse['alerts'];
      _isLoadingInitialData = false; // 날씨/지수 로딩 완료
      _errorMessage = null; // 성공 시 에러 메시지 초기화
    } catch (e) {
      _errorMessage = "초기 데이터 로드 실패: ${e.toString()}";
      _isLoadingInitialData = false; // 실패 시에도 로딩 상태 해제
      _weatherData = null; // 데이터 초기화
      _indexData = null;
      _alerts = null;
    } finally {
      notifyListeners(); // 날씨/지수 로딩 결과 UI 업데이트
    }

    // 3. 모든 대피소 지도 백그라운드에서 로드 시작
    // 날씨/지수 로딩 성공 여부와 관계없이 지도 로드는 시도
    if (_currentPosition != null) {
      _loadAllShelterMapsInBackground();
    }
  }

  // 모든 유형의 대피소 지도를 백그라운드에서 로드
  Future<void> _loadAllShelterMapsInBackground() async {
    // 모든 지도 로딩 상태 초기화 및 시작 알림
    for (var type in ShelterType.values) {
      _isLoadingMaps[type] = true;
      _shelterMapHtmls[type] = null; // 기존 맵 데이터 클리어
      _mapErrorMessages[type] = null; // 기존 에러 클리어
    }
    // 중요: 지도 로딩 시작 상태를 즉시 UI에 반영
    notifyListeners();

    List<Future> fetchFutures = [];

    for (var type in ShelterType.values) {
      final future = _apiService
          .fetchMapHtml(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            type.apiParam, // Enum -> API 파라미터 문자열 변환
          )
          .then((html) {
            // 성공 시
            _shelterMapHtmls[type] = html;
            _isLoadingMaps[type] = false;
            _mapErrorMessages[type] = null; // 성공 시 에러 메시지 제거
            print("Map loaded successfully for: ${type.displayName}");
            notifyListeners(); // 해당 지도 로딩 완료 상태 업데이트
          })
          .catchError((e) {
            // 실패 시
            print("Error loading map for ${type.displayName}: $e");
            _shelterMapHtmls[type] = null; // 실패 시 HTML null 처리
            _isLoadingMaps[type] = false;
            _mapErrorMessages[type] = "지도 로딩 실패: ${e.toString()}"; // 타입별 에러 저장
            notifyListeners(); // 해당 지도 로딩 실패 상태 업데이트
          });
      fetchFutures.add(future);
    }

    // 모든 fetch가 시작되었음을 로그로 남김 (선택 사항)
    print("All shelter map fetch processes initiated.");

    // 여기서 모든 Future가 완료될 때까지 기다릴 필요는 없음 (백그라운드 진행)
    // Future.wait(fetchFutures).then((_) => print("All map fetches attempted."));
  }

  // --- UI 상호작용 로직 ---

  // 사용자가 선택한 대피소 유형 변경
  void selectShelterType(ShelterType type) {
    if (_selectedShelterType != type) {
      _selectedShelterType = type;
      print("Selected Shelter Type: ${type.displayName}");
      notifyListeners(); // 선택된 유형 변경 시 UI 업데이트
    }
  }

  // 새로고침 로직 (초기 데이터 다시 로드)
  Future<void> refreshData() async {
    // 기존 지도 데이터는 유지하면서 날씨/지수만 새로고침하거나,
    // 전체를 새로 로드할 수 있음. 여기서는 전체 새로고침.
    await loadInitialData();
  }
}
