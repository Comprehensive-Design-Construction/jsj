// lib/presentation/screens/main/widgets/hourly_weather_section_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/ui/hourly_weather_ui.dart';
import '../main_screen_notifier.dart'; // mainScreenNotifierProvider 사용
import '../../../widgets/common/section_title_widget.dart';
import '../../../widgets/main_screen/hourly_weather_card.dart';
import '../../../widgets/common/data_error_placeholder_widget.dart';

class HourlyWeatherSectionWidget extends ConsumerWidget {
  const HourlyWeatherSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<HourlyWeatherUI> hourlyData = ref.watch(
      mainScreenNotifierProvider.select((state) => state.hourlyWeatherDataUI),
    );

    if (hourlyData.isEmpty) {
      // 데이터가 비어있으면 아무것도 표시하지 않거나, 로딩/에러 상태에 따라 다른 UI 표시 가능
      // 여기서는 일단 숨김 처리
      return const SizedBox.shrink();
    }
    // 화면 너비에 따라 아이템 크기 및 간격 자동 조정을 위해 LayoutBuilder 사용 (선택적)
    // 여기서는 고정된 아이템 너비와 개수를 가정합니다.
    const int crossAxisCount = 6; // 한 줄에 표시할 아이템 개수
    const double itemAspectRatio = 0.505; // 아이템의 가로세로 비율 (조절 필요)
    // (너비 대비 높이 비율: 높이가 너비의 약 1.8배)
    // HourlyWeatherCard의 내용물 높이에 따라 조절합니다.
    // (시간 + 상태텍스트 + 아이콘 + 강수확률 + 온도)
    // 예: 너비 60, 높이 110 이면 60/110 = 0.545

    // GridView에 필요한 전체 높이를 동적으로 계산하거나, 충분한 높이를 확보해야 합니다.
    // 여기서는 2줄을 기준으로 높이를 계산합니다.
    // (HourlyWeatherCard의 예상 높이 * 2) + (줄 간 간격 * 1)
    // HourlyWeatherCard가 약 120~130px 높이를 가진다고 가정하면,
    // 2줄이면 260~280px 정도 필요합니다. (패딩 포함)
    // 아이템 너비는 (화면너비 - (총 좌우패딩) - (아이템간 총 간격)) / crossAxisCount 로 결정됩니다.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitleWidget(title: '날씨'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ), // GridView 주변 패딩
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true, // Column 내에서 GridView 크기를 내용에 맞춤
            physics:
                const NeverScrollableScrollPhysics(), // 외부 SingleChildScrollView와 스크롤 충돌 방지
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // 한 줄에 6개
              childAspectRatio: itemAspectRatio, // 아이템 가로세로 비율
              crossAxisSpacing: 2, // 아이템 간 가로 간격
              mainAxisSpacing: 8, // 아이템 간 세로 간격 (줄 간 간격)
            ),
            itemCount: hourlyData.length, // 최대 12개까지 DataMapper에서 제한됨
            itemBuilder: (context, index) {
              return HourlyWeatherCard(hourlyWeather: hourlyData[index]);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
