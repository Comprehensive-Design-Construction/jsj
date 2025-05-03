import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart'; // defaultLatitude, defaultLongitude 사용
import '../../../../data/models/added_person.dart';
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
import '../main_screen_state.dart'; // MainScreenState 사용

class LocationInfoWidget extends ConsumerWidget {
  const LocationInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainScreenNotifierProvider);
    final currentWeatherUI = state.weatherDataUI; // 위치 이름 가져오기 위함

    // 현재 선택된 사람의 지역 이름 결정
    String locationName = '위치 정보 로딩 중...';
    if (state.selectedPersonId == myInfoId) {
      locationName = currentWeatherUI?.location ?? '위치 정보 없음';
    } else {
      final person = state.addedPeopleList.firstWhere(
        (p) => p.id == state.selectedPersonId,
        orElse: () => AddedPerson(id: '', name: '', gu: '지역', dong: '정보 없음'),
      );
      locationName = '${person.gu ?? ""} ${person.dong ?? "지역 정보 없음"}';
    }

    // 기본 위치 사용 여부 확인
    final bool isDefaultLocation =
        state.selectedPersonId == myInfoId &&
        state.lastLoadedLatitude != null &&
        state.lastLoadedLongitude != null &&
        state.lastLoadedLatitude == defaultLatitude &&
        state.lastLoadedLongitude == defaultLongitude;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            state.selectedPersonId == myInfoId
                ? Icons.my_location
                : Icons.location_city_outlined,
            color: Colors.grey[600],
            size: 18,
          ),
          const SizedBox(width: 4),
          // 지역 이름이 길어질 경우 대비 Flexible 추가
          Flexible(
            child: Text(
              locationName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis, // 넘칠 경우 ... 처리
            ),
          ),
          // 기본 위치 알림
          if (isDefaultLocation)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '(기본위치)',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
