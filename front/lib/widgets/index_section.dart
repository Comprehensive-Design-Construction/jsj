import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class IndexSection extends StatelessWidget {
  final Map<String, dynamic>? indexData;

  const IndexSection({super.key, required this.indexData});

  @override
  Widget build(BuildContext context) {
    if (indexData == null) {
      // return const Center(child: Text("위험 지수 정보를 불러올 수 없습니다."));
      return SizedBox.shrink(); // 데이터 없으면 공간 차지 안함
    }

    // 표시할 지수 목록 정의 (API 응답 키 기준)
    final List<Map<String, String>> indicesToShow = [
      {'key': 'apparent_temperature', 'name': '체감온도', 'unit': '°C'},
      {
        'key': 'food_poisoning_index',
        'name': '식중독 지수',
        'unit': '',
        'riskKey': 'food_poisoning_risk',
      },
      {
        'key': 'stroke_index_score',
        'name': '뇌졸중 지수',
        'unit': '',
        'levelKey': 'stroke_index_level',
      },
      {
        'key': 'cold_index_score',
        'name': '동파 지수',
        'unit': '',
        'levelKey': 'cold_index_level',
      },
      {
        'key': 'ali_score',
        'name': '천식폐질환',
        'unit': '',
        'levelKey': 'ali_level',
      },
      // 필요에 따라 다른 지수 추가
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "상세 정보",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        // GridView를 사용하여 2열로 카드 표시
        GridView.builder(
          physics: NeverScrollableScrollPhysics(), // ListView 내부 스크롤 방지
          shrinkWrap: true, // 내용물 크기에 맞춤
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 한 줄에 2개씩
            crossAxisSpacing: 12.0, // 카드 좌우 간격
            mainAxisSpacing: 12.0, // 카드 상하 간격
            childAspectRatio: 2.0, // 카드 가로세로 비율 (조정 필요)
          ),
          itemCount: indicesToShow.length,
          itemBuilder: (context, index) {
            final item = indicesToShow[index];
            final value = indexData![item['key']];
            String displayValue = 'N/A';
            String subValue = ''; // 레벨이나 위험도 표시

            if (value != null) {
              // 수치 포맷팅 (소수점 등)
              if (value is num) {
                displayValue = value.toStringAsFixed(
                  item['unit'] == '°C'
                      ? 1
                      : (item['key']?.contains('score') ?? false ? 3 : 1),
                );
                if (item['unit']!.isNotEmpty) {
                  displayValue += item['unit']!;
                }
              } else {
                displayValue = value.toString();
              }

              // 추가 정보 (레벨 또는 위험도)
              if (item.containsKey('levelKey') &&
                  indexData!.containsKey(item['levelKey'])) {
                subValue =
                    " (${indexData![item['levelKey']]?.toString() ?? ''}단계)";
              } else if (item.containsKey('riskKey') &&
                  indexData!.containsKey(item['riskKey'])) {
                subValue =
                    " (${indexData![item['riskKey']]?.toString() ?? ''})";
              }
            }

            return _buildIndexCard(
              title: item['name']!,
              value: displayValue,
              subValue: subValue,
              icon: _getIndexIcon(item['key']!), // 키에 따른 아이콘
            );
          },
        ),
      ],
    );
  }

  // 지수 종류에 따른 아이콘 반환 (예시)
  IconData _getIndexIcon(String key) {
    if (key.contains('temperature')) return Icons.thermostat;
    if (key.contains('food')) return Icons.restaurant;
    if (key.contains('stroke')) return Icons.monitor_heart;
    if (key.contains('cold')) return Icons.ac_unit;
    if (key.contains('ali')) return Icons.masks;
    return Icons.info_outline; // 기본 아이콘
  }

  // 지수 정보를 표시하는 카드 위젯
  Widget _buildIndexCard({
    required String title,
    required String value,
    String subValue = '',
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // 내용물 중앙 정렬
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryColor),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Spacer(), // 값과 부가정보를 아래로 밀기
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis, // 값이 길 경우 ... 처리
          ),
          if (subValue.isNotEmpty)
            Text(
              subValue,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
