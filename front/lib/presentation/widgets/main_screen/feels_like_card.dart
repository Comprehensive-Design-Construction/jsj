import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/models/ui/feels_like_data.dart';
import '../common/speech_bubble.dart';
// 상세 페이지 import (추후 생성 후 경로 수정)
import '../../screens/index_detail/index_detail_screen.dart';
// PreferencesService import (기저질환 등 정보 가져오기 위함)
import '../../../core/utils/preferences_service.dart';
// Riverpod import (ref 사용 위함) - ConsumerWidget으로 변경 또는 ref 전달 필요
// 여기서는 onTap 내에서 임시로 Provider를 직접 read하는 방식으로 처리 (개선 가능)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/main/main_screen_notifier.dart'; // provider 사용 위함

class FeelsLikeCard extends ConsumerWidget {
  final FeelsLikeData feelsLikeData;
  const FeelsLikeCard({Key? key, required this.feelsLikeData})
    : super(key: key);

  // --- 핸들 중심 X 좌표 계산 함수 ---
  // _calculateProgress 함수 제거하고 이 함수로 대체
  double _calculateHandleCenterX(BuildContext context, double temperature) {
    // TODO: 프로그레스 바 범위 논의 후 확정 필요 (현재 0~45) -> app_constants 등으로 이동 고려
    const double minTemp = 0.0;
    const double maxTemp = 45.0;

    double progressRatio = ((temperature - minTemp) / (maxTemp - minTemp))
        .clamp(0.0, 1.0);

    // 카드 좌우 패딩(16*2)을 제외한 실제 트랙 너비 계산
    double availableWidth = MediaQuery.of(context).size.width - 32;
    // 카드 내부 패딩(16*2)도 고려
    double trackWidth = availableWidth - 32;

    const double thumbRadius = 10.0; // 핸들 반지름 (새 디자인 기준)

    // 핸들 중심의 X 좌표 계산 (트랙 시작점 기준)
    double handleCenterX = (trackWidth * progressRatio);

    // 핸들이 트랙 양 끝을 벗어나지 않도록 clamp 적용
    // (트랙 시작점부터 thumbRadius, 트랙 끝점 - thumbRadius 까지)
    handleCenterX = handleCenterX.clamp(thumbRadius, trackWidth - thumbRadius);

    return handleCenterX;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 프로그레스 바 관련 상수 (새 디자인 기준)
    const double speechBubbleWidth = 60.0;
    const double thumbRadius = 10.0;
    const double trackHeight = 8.0;
    const double bubbleBottomMargin = 5.0;
    const int numberOfDots = 6;
    const double dotRadius = 2.5;

    return Container(
      padding: const EdgeInsets.all(16), // 카드 내부 패딩
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
          // --- 상단: 아이콘, 온도 --- (상태 태그는 프로그레스 바로 이동)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 (배경색은 statusColor 사용)
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: feelsLikeData.statusColor, // 상태 색상으로 배경
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  // 아이콘 변경 (온도계 모양)
                  Icons.thermostat,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // 온도 텍스트
              Expanded(
                // Expanded 추가하여 공간 차지
                child: Text(
                  '${feelsLikeData.temperature.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
              // <<< 화살표 버튼 추가 >>>
              InkWell(
                onTap: () async {
                  // async 추가
                  print('FeelsLikeCard arrow tapped!');
                  // TODO: 현재 사용자 정보(기저질환 등) 로드
                  // 예시: '내 정보' 기준 (실제로는 selectedPersonId 확인 필요)
                  final prefsService = ref.read(preferencesServiceProvider);
                  final diseases = await prefsService.getUserDiseases();
                  // final isPregnant = await prefsService.getIsPregnant();
                  // ... 기타 필요한 정보 로드 ...

                  // 상세 페이지로 이동 (indexData 전달)
                  if (context.mounted) {
                    // context 유효성 검사
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => IndexDetailPage(
                              indexData: feelsLikeData,
                              // userDiseases: diseases ?? [], // 필요시 전달
                              // isPregnant: isPregnant, // 필요시 전달
                            ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // 탭 영역 확보
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              // <<< --------- >>>
            ],
          ),
          const SizedBox(height: 40), // 상단과 프로그레스 바 사이 간격
          // --- 프로그레스 바와 말풍선 ---
          LayoutBuilder(
            builder: (context, constraints) {
              final double handleCenterX = _calculateHandleCenterX(
                context,
                feelsLikeData.temperature,
              );
              double trackWidth =
                  constraints.maxWidth; // LayoutBuilder에서 실제 트랙 너비 얻기
              // 말풍선 시작 X 좌표 계산 및 화면 벗어나지 않도록 clamp
              double bubbleLeft = (handleCenterX - (speechBubbleWidth / 2))
                  .clamp(0, trackWidth - speechBubbleWidth);
              final double dotSpacing =
                  trackWidth / (numberOfDots + 1); // 점 간격 계산

              return SizedBox(
                height: 50 + bubbleBottomMargin + trackHeight, // 높이 확보
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // --- 배경 트랙 ---
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 50 + bubbleBottomMargin,
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                    ),
                    // --- 진행 상태 바 ---
                    Positioned(
                      left: 0,
                      top: 50 + bubbleBottomMargin,
                      child: Container(
                        height: trackHeight,
                        width: handleCenterX,
                        decoration: BoxDecoration(
                          color: feelsLikeData.statusColor, // 상태 색상으로 채우기
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                    ),
                    // --- 점들 ---
                    for (int i = 1; i <= numberOfDots; i++)
                      Positioned(
                        left: (dotSpacing * i) - dotRadius,
                        top:
                            50 +
                            bubbleBottomMargin +
                            (trackHeight / 2) -
                            dotRadius,
                        child: Container(
                          width: dotRadius * 2,
                          height: dotRadius * 2,
                          decoration: BoxDecoration(
                            // 핸들 위치 기준으로 점 색상 결정
                            color:
                                (dotSpacing * i) < handleCenterX
                                    ? Colors
                                        .white // 진행된 부분 위: 흰색
                                    : Colors.grey[400], // 진행 안된 부분 위: 회색
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    // --- 핸들 (동그라미) ---
                    Positioned(
                      left: handleCenterX - thumbRadius,
                      top:
                          50 +
                          bubbleBottomMargin +
                          (trackHeight / 2) -
                          thumbRadius, // 트랙 중앙에 핸들 중앙이 오도록 top 조정
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- 상태 말풍선 ---
                    Positioned(
                      left: bubbleLeft,
                      top: 0,
                      child: SizedBox(
                        width: speechBubbleWidth,
                        child: SpeechBubble(
                          // 분리된 위젯 사용
                          borderColor: feelsLikeData.statusColor,
                          backgroundColor:
                              feelsLikeData.statusColor, // 배경색도 상태색과 동일하게
                          child: Text(
                            feelsLikeData.status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 15), // 프로그레스 바와 메시지 사이 간격
          // --- 안내 메시지 ---
          Text(
            feelsLikeData.message1,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            feelsLikeData.message2,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          // --- 하단 버튼 (스타일 변경) ---
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     // 아이콘 없는 버튼으로 변경
          //     child: Text(feelsLikeData.buttonText),
          //     onPressed: () {
          //       // TODO: 버튼 클릭 동작 (기능 미확정 상태)
          //       print('"${feelsLikeData.buttonText}" 버튼 클릭됨');
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.grey[400], // 배경색 변경
          //       foregroundColor: Colors.white, // 글자색 변경
          //       elevation: 0,
          //       padding: const EdgeInsets.symmetric(vertical: 14),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ), // 모서리 덜 둥글게
          //       textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          //         fontSize: 14,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
