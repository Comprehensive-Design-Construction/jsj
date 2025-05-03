import 'package:flutter/material.dart';
import 'dart:math'; // max 함수 사용 위해 추가

import '../../../data/models/ui/health_index.dart';
import '../common/speech_bubble.dart'; // 분리된 SpeechBubble 위젯 import

class HealthIndexCard extends StatelessWidget {
  final HealthIndex healthIndex;
  final bool showProgressBar; // 프로그레스 바 표시 여부
  // final VoidCallback? onTap; // 카드 전체 탭 콜백 (필요 시 추가)

  const HealthIndexCard({
    Key? key,
    required this.healthIndex,
    required this.showProgressBar,
    // onStatusTap 콜백 제거 (새 디자인에서는 상태 부분이 탭되지 않음)
    // this.onTap,
  }) : super(key: key);

  // --- 핸들 중심 X 좌표 계산 함수 (지수별 범위 고려) ---
  // _calculateProgress 함수 제거하고 이 함수로 대체
  double _calculateHandleCenterX(
    BuildContext context,
    double value,
    String indexName,
  ) {
    // TODO: 각 지수별 프로그레스 바 범위 논의 후 확정 필요 -> app_constants 등으로 이동 고려
    double minValue = 0.0;
    double maxValue = 100.0; // 기본 최대값

    // 지수 이름에 따라 최대값 설정 (기존 TODO 및 새 UI 코드 참고)
    if (indexName == '자외선 지수') {
      maxValue = 15.0;
    } else if (indexName.contains('꽃가루')) {
      maxValue = 100.0;
    } // 범위 확인 필요
    else if (indexName == '미세먼지 지수') {
      maxValue = 200.0;
    } // API 응답 최대값 고려 (예: 150+ 매우나쁨)
    else if (indexName == '심뇌혈관질환 지수') {
      maxValue = 4.0;
    } // 예: 1(낮음)~4(매우높음) 레벨 기준? 값 기준?
    else if (indexName == '대기정체 지수') {
      maxValue = 100.0;
    } // 예시
    else if (indexName == '식중독 지수') {
      maxValue = 100.0;
    } else if (indexName == '감기가능 지수') {
      maxValue = 4.0;
    } // 레벨 기준?
    else if (indexName == '천식질환 지수') {
      maxValue = 4.0;
    } // 레벨 기준?
    // ... 다른 지수 추가 ...

    // 값 범위를 벗어나는 경우 처리 (Clamp 사용)
    value = value.clamp(minValue, maxValue);

    double progressRatio =
        (maxValue == minValue)
            ? 0.0
            : ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    // 카드 좌우 패딩(16*2) 제외한 실제 트랙 너비 계산
    double availableWidth = MediaQuery.of(context).size.width - 32;
    // 카드 내부 패딩(16*2)도 고려
    double trackWidth = availableWidth - 32;

    const double thumbRadius = 10.0; // 핸들 반지름

    // 핸들 중심 X 좌표 계산 및 트랙 범위 내로 제한
    double handleCenterX = (trackWidth * progressRatio).clamp(
      thumbRadius,
      trackWidth - thumbRadius,
    );

    return handleCenterX;
  }

  @override
  Widget build(BuildContext context) {
    // 프로그레스 바 관련 상수
    const double thumbRadius = 10.0;
    const double trackHeight = 8.0;
    const double speechBubbleWidth = 60.0;
    const double bubbleBottomMargin = 5.0;
    const int numberOfDots = 6;
    const double dotRadius = 2.5;

    // 프로그레스 바 UI 빌드 함수 (showProgressBar가 true일 때만 사용)
    Widget buildProgressBarUI() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double handleCenterX = _calculateHandleCenterX(
            context,
            healthIndex.value,
            healthIndex.name,
          );
          final double trackWidth = constraints.maxWidth;
          double bubbleLeft = (handleCenterX - (speechBubbleWidth / 2)).clamp(
            0,
            trackWidth - speechBubbleWidth,
          );
          final double dotSpacing = trackWidth / (numberOfDots + 1);

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
                      color: healthIndex.statusColor, // 상태 색상 사용
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // --- 점들 ---
                for (int i = 1; i <= numberOfDots; i++)
                  Positioned(
                    left: (dotSpacing * i) - dotRadius,
                    top:
                        50 + bubbleBottomMargin + (trackHeight / 2) - dotRadius,
                    child: Container(
                      width: dotRadius * 2,
                      height: dotRadius * 2,
                      decoration: BoxDecoration(
                        color:
                            (dotSpacing * i) < handleCenterX
                                ? Colors.white
                                : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                // --- 핸들 ---
                Positioned(
                  left: handleCenterX - thumbRadius,
                  top:
                      50 + bubbleBottomMargin + (trackHeight / 2) - thumbRadius,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: healthIndex.statusColor,
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
                      borderColor: healthIndex.statusColor,
                      backgroundColor: healthIndex.statusColor,
                      child: Text(
                        healthIndex.status,
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
      );
    } // End of buildProgressBarUI

    return Container(
      // 카드 패딩 조정 (프로그레스 바 유무에 따라)
      padding: EdgeInsets.fromLTRB(16, 16, 16, showProgressBar ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 상단: 아이콘, 이름/값, 상태 박스 또는 '>' 아이콘 ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: 아이콘 + 이름/값
              Expanded(
                child: Row(
                  children: [
                    // 아이콘 (새 디자인: 배경색 적용)
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: healthIndex.iconColor, // <<< 아이콘 배경색 사용
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        healthIndex.icon,
                        color: Colors.white,
                        size: 24,
                      ), // 아이콘 흰색
                    ),
                    const SizedBox(width: 12),
                    // 이름 & 값
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, // 수직 정렬
                        children: [
                          Text(
                            healthIndex.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis, // 이름 길 경우 ...
                          ),
                          const SizedBox(height: 3),
                          // 값 표시 (소수점 처리 방식은 모델/데이터에 따라 조정)
                          Text(
                            // 예시: 소수점 첫째 자리까지 또는 정수로 표시
                            healthIndex.value.toStringAsFixed(
                              healthIndex.value.truncateToDouble() ==
                                      healthIndex.value
                                  ? 0
                                  : 1,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 오른쪽: 상태 박스 (showProgressBar가 false일 때) 또는 간격
              if (!showProgressBar) // 전체 목록 뷰일 때 상태 박스 표시
                Container(
                  margin: const EdgeInsets.only(left: 8), // 이름/값과 간격
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: healthIndex.iconColor, // <<< 아이콘 배경색과 동일하게
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    healthIndex.status,
                    style: const TextStyle(
                      color: Colors.white, // 흰색 텍스트
                      // fontWeight: FontWeight.bold, // 필요시 굵게
                      fontSize: 12,
                    ),
                  ),
                )
              else // 주요 목록 뷰(프로그레스 바 표시)일 때는 간격만 둠 (말풍선이 상태 표시)
                const SizedBox(width: 8), // '>' 아이콘과의 간격을 위해
              // 맨 오른쪽: '>' 아이콘 (탭 가능)
              InkWell(
                onTap: () {
                  // TODO: 카드 또는 '>' 아이콘 탭 시 동작 구현 (상세 페이지 이동 등)
                  print('${healthIndex.name} card tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${healthIndex.name} 카드 클릭됨! 상세 페이지 이동 등 구현 필요.',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  // 필요하다면 생성자에 onTap 콜백 추가
                  // onTap?.call();
                },
                borderRadius: BorderRadius.circular(20), // 탭 효과 영역
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // 탭 영역 확보
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ), // End of Top Row
          // --- 프로그레스 바 UI (showProgressBar가 true일 때만 표시) ---
          if (showProgressBar) ...[
            const SizedBox(height: 20), // 상단 정보와 프로그레스 바 사이 간격
            buildProgressBarUI(), // 프로그레스 바 빌드 함수 호출
            const SizedBox(height: 10), // 프로그레스 바와 카드 하단 사이 간격
          ],
        ],
      ),
    );
  }
}
