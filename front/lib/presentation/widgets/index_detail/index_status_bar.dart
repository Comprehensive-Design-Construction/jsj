// lib/presentation/widgets/index_detail/index_status_bar.dart
import 'package:flutter/material.dart';
import 'dart:math'; // max, min 사용

// 기존 SpeechBubble 위젯 import
import '../common/speech_bubble.dart';

class IndexStatusBar extends StatelessWidget {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final String statusText;
  final Color statusColor;
  // final String indexName; // 지수 이름을 받아 범위를 내부에서 결정할 수도 있음

  const IndexStatusBar({
    super.key,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.statusText,
    required this.statusColor,
    // required this.indexName,
  });

  // --- 핸들 중심 X 좌표 및 비율 계산 함수 ---
  // HealthIndexCard/FeelsLikeCard의 로직을 통합 및 일반화
  ({double handleCenterX, double progressRatio}) _calculatePosition(
    BuildContext context,
    double availableWidth,
  ) {
    // 값 범위를 벗어나는 경우 처리 (Clamp 사용)
    final clampedValue = currentValue.clamp(minValue, maxValue);

    // 진행률 계산 (0.0 ~ 1.0)
    final double progressRatio =
        (maxValue == minValue)
            ? 0.0 // 분모 0 방지
            : ((clampedValue - minValue) / (maxValue - minValue)).clamp(
              0.0,
              1.0,
            );

    // 핸들(Thumb) 반지름 정의 (기존 카드와 유사하게)
    const double thumbRadius = 10.0;
    // 실제 트랙 너비 (양쪽 핸들 반지름 제외)
    final double trackWidth = availableWidth - (thumbRadius * 2);

    // 핸들 중심 X 좌표 계산 (트랙 시작점 + 진행률 * 트랙 너비)
    double handleCenterX = thumbRadius + (trackWidth * progressRatio);

    // 계산된 중심 X 좌표가 가용 너비 내에 있도록 최종 clamp
    handleCenterX = handleCenterX.clamp(
      thumbRadius,
      availableWidth - thumbRadius,
    );

    return (handleCenterX: handleCenterX, progressRatio: progressRatio);
  }

  @override
  Widget build(BuildContext context) {
    // 프로그레스 바 UI 관련 상수 (기존 카드 참고)
    const double trackHeight = 8.0;
    const double thumbRadius = 10.0;
    const double speechBubbleWidth = 60.0;
    const double bubbleBottomMargin = 5.0; // 말풍선과 바 사이 간격
    const int numberOfDots = 6; // 트랙 위의 점 개수
    const double dotRadius = 2.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // 핸들 위치 및 진행률 계산
        final positionData = _calculatePosition(context, availableWidth);
        final double handleCenterX = positionData.handleCenterX;
        // final double progressRatio = positionData.progressRatio; // 필요 시 사용

        // 말풍선 시작 X 좌표 계산 및 화면 벗어나지 않도록 clamp
        final double bubbleLeft = (handleCenterX - (speechBubbleWidth / 2))
            .clamp(0, availableWidth - speechBubbleWidth);

        // 점 간격 계산
        final double dotSpacing = availableWidth / (numberOfDots + 1);

        return SizedBox(
          // 전체 위젯 높이 = 말풍선 높이(추정) + 간격 + 트랙 높이
          // SpeechBubble 높이는 내용에 따라 다르므로 충분히 확보 (약 50으로 가정)
          height: 50 + bubbleBottomMargin + trackHeight,
          child: Stack(
            clipBehavior: Clip.none, // 요소들이 영역 밖으로 나가도 보이도록
            alignment: Alignment.centerLeft,
            children: [
              // --- 1. 배경 트랙 ---
              Positioned(
                left: thumbRadius, // 핸들 반지름만큼 안쪽에서 시작
                right: thumbRadius, // 핸들 반지름만큼 안쪽에서 끝
                top: 50 + bubbleBottomMargin, // 말풍선 아래 + 간격
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),

              // --- 2. 진행 상태 바 ---
              Positioned(
                left: thumbRadius, // 핸들 반지름만큼 안쪽에서 시작
                top: 50 + bubbleBottomMargin,
                child: Container(
                  height: trackHeight,
                  // 너비: 핸들 중심 X좌표에서 시작점(thumbRadius)을 뺀 길이
                  width: (handleCenterX - thumbRadius).clamp(
                    0.0,
                    availableWidth - (thumbRadius * 2),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor, // 전달받은 상태 색상 사용
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),

              // --- 3. 점들 ---
              // (점 위치 계산 시 availableWidth 기준)
              for (int i = 1; i <= numberOfDots; i++)
                Positioned(
                  // 각 점의 X 좌표 = 점 간격 * 점 인덱스
                  left: (dotSpacing * i) - dotRadius, // 점 반지름 고려하여 중앙 정렬
                  // 각 점의 Y 좌표 = 말풍선아래 + 간격 + (트랙높이/2) - 점반지름
                  top: 50 + bubbleBottomMargin + (trackHeight / 2) - dotRadius,
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

              // --- 4. 핸들 (동그라미) ---
              Positioned(
                // 핸들 중심이 handleCenterX에 오도록 left 조정
                left: handleCenterX - thumbRadius,
                // 핸들 중심이 트랙의 세로 중앙에 오도록 top 조정
                top: 50 + bubbleBottomMargin + (trackHeight / 2) - thumbRadius,
                child: Container(
                  width: thumbRadius * 2,
                  height: thumbRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.white, // 핸들 색상
                    shape: BoxShape.circle,
                    border: Border.all(
                      // 테두리 색상은 상태 색상 사용
                      color: statusColor,
                      width: 2.5, // 테두리 두께
                    ),
                    boxShadow: [
                      // 약간의 그림자 효과
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 5. 상태 말풍선 ---
              Positioned(
                left: bubbleLeft, // 계산된 말풍선 시작 위치
                top: 0, // 최상단에 배치
                child: SizedBox(
                  width: speechBubbleWidth, // 고정 너비
                  child: SpeechBubble(
                    // 공용 말풍선 위젯 사용
                    borderColor: statusColor, // 테두리색 = 상태색
                    backgroundColor: statusColor, // 배경색 = 상태색
                    child: Text(
                      statusText, // 전달받은 상태 텍스트
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, // 글자색
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1, // 한 줄로 표시 (필요시 조절)
                      overflow: TextOverflow.ellipsis, // 넘치면 ...
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
