// lib/features/dashboard/presentation/widgets/map_display_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 상태 관리 예시 (또는 Provider 등)
import '../../../../services/api_service.dart'; // ApiService 사용
import 'map_display.dart';
import '../../../../models/user_profile.dart'; // UserProfile (위치 정보 필요 시)
import '../../../../core/storage/user_profile_storage.dart'; // 위치 정보 필요 시
import 'package:geolocator/geolocator.dart'; // 위치 정보 필요 시
import '../../../../services/location_service.dart'; // 위치 정보 필요 시

// 이 위젯의 상태를 관리할 Cubit/Bloc 또는 Provider 필요
// 여기서는 간단하게 StatefulWidget 으로 구현 (복잡해질 수 있음)

class MapDisplaySection extends StatefulWidget {
  const MapDisplaySection({super.key});

  @override
  State<MapDisplaySection> createState() => _MapDisplaySectionState();
}

class _MapDisplaySectionState extends State<MapDisplaySection> {
  String _selectedMapType = 'env'; // 'env' 또는 'shelter'
  String? _selectedEnvType = 'fine_dust'; // 'fine_dust', 'uv', 'flood_trace'
  String? _selectedDisasterType = 'HEAT_WAVE'; // 'HEAT_WAVE', 'EARTHQUAKE' 등

  String? _mapHtmlContent;
  bool _isLoadingMap = false;
  String? _mapError;

  // ApiService 인스턴스 (실제로는 Provider나 get_it 등으로 주입받는 것이 좋음)
  final ApiService _apiService = ApiService();
  final LocationService _locationService =
      LocationService(); // 현재 위치 기반 대피소 지도 위해

  @override
  void initState() {
    super.initState();
    // 초기 지도 로드 (예: 미세먼지 지도)
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() {
      _isLoadingMap = true;
      _mapError = null;
      _mapHtmlContent = null; // 로딩 시작 시 이전 지도 제거
    });

    try {
      String? htmlResult;
      if (_selectedMapType == 'env' && _selectedEnvType != null) {
        // 환경 지도 로드
        final response = await _apiService.getEnvMapHtml(
          _selectedEnvType!,
          false,
        ); // force_refresh=false
        if (response.error == null) {
          htmlResult = response.envMapHtml;
        } else {
          _mapError = response.error;
        }
      } else if (_selectedMapType == 'shelter' &&
          _selectedDisasterType != null) {
        // 대피소 지도 로드 (현재 위치 필요)
        try {
          final position = await _locationService.getCurrentLocation();
          // 기본 반경 사용 (또는 사용자 설정값)
          final response = await _apiService.getShelterMapHtml(
            position.latitude,
            position.longitude,
            _selectedDisasterType!,
            2.0,
            false,
          );
          if (response.error == null) {
            htmlResult = response.shelterMapHtml;
          } else {
            _mapError = response.error;
          }
        } on Exception catch (e) {
          // 위치 서비스 관련 예외 처리
          _mapError = "현재 위치를 가져올 수 없어 대피소 지도를 표시할 수 없습니다: $e";
        }
      }

      setState(() {
        _mapHtmlContent = htmlResult;
      });
    } catch (e) {
      setState(() {
        _mapError = "지도 로딩 중 오류 발생: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 지도 타입 선택 (환경 지도 / 대피소 지도)
        SegmentedButton<String>(
          // Flutter 3.7 이상
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'env',
              label: Text('환경 지도'),
              icon: Icon(Icons.public),
            ),
            ButtonSegment<String>(
              value: 'shelter',
              label: Text('대피소'),
              icon: Icon(Icons.security),
            ),
          ],
          selected: {_selectedMapType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedMapType = newSelection.first;
              // 타입 변경 시 첫번째 상세 타입으로 초기화 및 지도 다시 로드
              if (_selectedMapType == 'env') _selectedEnvType = 'fine_dust';
              if (_selectedMapType == 'shelter')
                _selectedDisasterType = 'HEAT_WAVE';
              _loadMap();
            });
          },
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 8),

        // 상세 지도 타입 선택 (Dropdown 사용)
        if (_selectedMapType == 'env')
          DropdownButton<String>(
            value: _selectedEnvType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'fine_dust', child: Text('미세먼지 지도')),
              DropdownMenuItem(value: 'uv', child: Text('자외선 지도')),
              DropdownMenuItem(value: 'flood_trace', child: Text('침수 흔적 지도')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedEnvType = newValue;
                });
                _loadMap();
              }
            },
          ),

        if (_selectedMapType == 'shelter')
          DropdownButton<String>(
            value: _selectedDisasterType,
            isExpanded: true,
            items: const [
              // core/shelter/config.py 의 ALL_DISASTER_TYPES 와 일치시키는 것이 좋음
              DropdownMenuItem(value: 'HEAT_WAVE', child: Text('폭염 대피소')),
              DropdownMenuItem(value: 'COLD_WAVE', child: Text('한파 대피소')),
              DropdownMenuItem(value: 'EARTHQUAKE', child: Text('지진 대피소')),
              DropdownMenuItem(value: 'FLOOD', child: Text('홍수 대피소')),
              DropdownMenuItem(value: 'FINE_DUST', child: Text('미세먼지 대피소')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDisasterType = newValue;
                });
                _loadMap();
              }
            },
          ),
        const SizedBox(height: 8),

        // 지도 표시 영역
        _isLoadingMap
            ? const Center(child: CircularProgressIndicator())
            : _mapError != null
            ? Text('오류: $_mapError', style: const TextStyle(color: Colors.red))
            : MapDisplay(mapHtmlContent: _mapHtmlContent), // 웹뷰 위젯 사용
      ],
    );
  }
}
