import 'package:flutter/material.dart';
import '../../../data/models/ui/feels_like_data.dart'; // 경로 수정

class FeelsLikeCard extends StatelessWidget {
  final FeelsLikeData feelsLikeData;
  const FeelsLikeCard({Key? key, required this.feelsLikeData})
    : super(key: key);

  // --- 프로그레스 바 위치 계산 (변경 없음) ---
  double _calculateProgress(BuildContext context, double temperature) {
    // TODO: 프로그레스 바 범위 논의 후 확정 필요 (현재 0~45)
    const double minTemp = 0.0;
    const double maxTemp = 45.0;
    double progress = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(
      0.0,
      1.0,
    );
    double trackWidth = MediaQuery.of(context).size.width - (16 * 2) - (16 * 2);
    const double thumbRadius = 8.0;
    return (trackWidth * progress).clamp(0.0, trackWidth - thumbRadius * 2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 상단: 아이콘, 온도, 상태 태그 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 아이콘 + 온도
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.thermostat_outlined,
                    color: feelsLikeData.statusColor,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${feelsLikeData.temperature.toStringAsFixed(1)}°', // 소수점 한 자리 표시
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              // 오른쪽: 상태 태그
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: feelsLikeData.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: feelsLikeData.statusColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  feelsLikeData.status,
                  style: TextStyle(
                    color: feelsLikeData.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // --- 프로그레스 바 ---
          LayoutBuilder(
            // 정확한 너비 계산 위해 LayoutBuilder 사용
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth; // 실제 사용 가능한 너비
              const double thumbRadius = 8.0;
              const double trackHeight = 6.0;

              // 온도 범위를 기준으로 진행률 계산 (0.0 ~ 1.0)
              // TODO: 프로그레스 바 범위 논의 후 확정 필요 (현재 0~45)
              const double minTemp = 0.0;
              const double maxTemp = 45.0;
              double progressRatio = ((feelsLikeData.temperature - minTemp) /
                      (maxTemp - minTemp))
                  .clamp(0.0, 1.0);

              // 핸들 위치 계산 (트랙 내부에 있도록)
              double progressPosition = (trackWidth * progressRatio).clamp(
                thumbRadius,
                trackWidth - thumbRadius,
              );

              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none, // 핸들이 트랙 밖으로 약간 나가도 보이게
                children: [
                  // --- 배경 트랙 ---
                  Container(
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                  // --- 진행 상태 바 ---
                  Container(
                    height: trackHeight,
                    width: progressPosition, // 핸들 중앙까지 색 채우도록 너비 조정
                    decoration: BoxDecoration(
                      color: feelsLikeData.statusColor,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                  // --- 핸들 (동그라미) ---
                  Positioned(
                    // left 값을 핸들 중앙이 progressPosition에 오도록 조정
                    left: progressPosition - thumbRadius,
                    child: Container(
                      width: thumbRadius * 2,
                      height: thumbRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: feelsLikeData.statusColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 16),
          // --- 안내 메시지 ---
          Text(
            feelsLikeData.message1,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 6),
          Text(
            feelsLikeData.message2,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 20),
          // --- 하단 버튼 ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.location_searching_rounded, size: 18),
              label: Text(feelsLikeData.buttonText),
              onPressed: () {
                // TODO: 버튼 클릭 동작 (대피소 위치 보기 -> 기능 미확정 상태, 추후 구현 또는 제거)
                print('"${feelsLikeData.buttonText}" 버튼 클릭됨');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
