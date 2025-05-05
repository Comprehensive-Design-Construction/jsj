// lib/presentation/screens/index_detail/index_detail_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'index_detail_state.dart';
import '../../../data/services/api_service.dart';
import '../../../core/utils/preferences_service.dart';
import '../../../data/models/ui/health_index.dart';
import '../../../data/models/ui/feels_like_data.dart';
import '../../../data/models/added_person.dart';
import '../main/main_screen_notifier.dart'; // Main Provider 사용 위함
import '../../../core/constants/app_constants.dart'; // myInfoId 사용 위함

class IndexDetailNotifier extends StateNotifier<IndexDetailState> {
  final ApiService _apiService;
  final PreferencesService _prefsService;
  final String _selectedPersonId;
  final dynamic indexData;

  IndexDetailNotifier(
    this._apiService,
    this._prefsService,
    this._selectedPersonId,
    this.indexData,
  ) : super(const IndexDetailState()) {
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearErrorMessage: true,
    );

    try {
      // 1. 현재 사용자 정보 로드 (_selectedPersonId 사용)
      int? age;
      String? workingType;
      List<String>? diseases;
      bool? isPregnant;

      // 사용자 정보 로드 (병렬 처리 가능성 고려)
      if (_selectedPersonId == myInfoId) {
        final results = await Future.wait([
          _prefsService.getUserAge(),
          _prefsService.getUserType(),
          _prefsService.getUserDiseases(),
          _prefsService.getIsPregnant(),
        ]);
        // `mounted` 확인: SharedPreferences 로드 후
        if (!mounted) return;
        age = results[0] as int?;
        workingType = results[1] as String?;
        diseases = results[2] as List<String>?;
        isPregnant = results[3] as bool?;
      } else {
        final addedPeople = await _prefsService.getAddedPeople();
        // `mounted` 확인: SharedPreferences 로드 후
        if (!mounted) return;

        final person = addedPeople.firstWhere(
          (p) => p.id == _selectedPersonId,
          orElse: () => AddedPerson(id: '', name: 'Unknown'), // Fallback
        );
        if (person.id.isNotEmpty) {
          age = person.age;
          workingType = person.workingType;
          diseases = person.diseases;
          isPregnant = person.isPregnant;
        } else {
          // Fallback: 사용자를 찾지 못한 경우 '내 정보' 기준 다시 로드
          print(
            "Warning: Could not find added person $_selectedPersonId in detail page. Using My Info.",
          );
          final results = await Future.wait([
            _prefsService.getUserAge(),
            _prefsService.getUserType(),
            _prefsService.getUserDiseases(),
            _prefsService.getIsPregnant(),
          ]);
          // `mounted` 확인: Fallback SharedPreferences 로드 후
          if (!mounted) return;
          age = results[0] as int?;
          workingType = results[1] as String?;
          diseases = results[2] as List<String>?;
          isPregnant = results[3] as bool?;
        }
      }

      // 2. indexData에서 필요한 정보 추출 (동기 작업)
      String indexType = '';
      String indexLevel = '';
      if (indexData is HealthIndex) {
        indexType = indexData.name;
        indexLevel = indexData.status;
      } else if (indexData is FeelsLikeData) {
        indexType = '체감온도';
        indexLevel = indexData.status;
      } else {
        throw Exception(
          "Unsupported index data type: ${indexData.runtimeType}",
        );
      }
      if (indexType.isEmpty || indexLevel.isEmpty) {
        throw Exception("Could not determine index type or level from data.");
      }
      // TODO: indexLevel을 백엔드가 요구하는 형식으로 변환 (필요 시)

      // 3. 백엔드 API 호출
      final recommendationText = await _apiService.fetchRecommendation(
        indexType: indexType,
        indexLevel: indexLevel,
        age: age,
        workingType: workingType,
        diseases: diseases,
        isPregnant: isPregnant,
      );

      // `mounted` 확인: API 호출 후
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        recommendation: recommendationText,
      );
    } catch (e) {
      print("Error loading recommendation: $e");
      if (!mounted) return; // 에러 발생 후 상태 변경 전 확인
      state = state.copyWith(
        isLoading: false,
        errorMessage: '행동 요령 정보를 불러오는 데 실패했습니다.',
      );
    }
  }
}

// Provider 정의 (Family 사용)
final indexDetailNotifierProvider = StateNotifierProvider.autoDispose.family<
  IndexDetailNotifier,
  IndexDetailState,
  ({dynamic indexData, String selectedPersonId})
>((ref, params) {
  final apiService = ref.watch(apiServiceProvider);
  final prefsService = ref.watch(preferencesServiceProvider);
  return IndexDetailNotifier(
    apiService,
    prefsService,
    params.selectedPersonId,
    params.indexData,
  );
});
