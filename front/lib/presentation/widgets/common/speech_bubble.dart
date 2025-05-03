import 'package:flutter/material.dart';

// --- 말풍선 모양을 그리는 CustomPainter ---
class SpeechBubblePainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;
  final double strokeWidth;
  final double borderRadius;
  final double tailHeight;
  final double tailWidth; // 꼬리 너비 추가

  SpeechBubblePainter({
    required this.borderColor,
    required this.backgroundColor,
    this.strokeWidth = 1.5, // 테두리 두께
    this.borderRadius = 8.0, // 모서리 둥글기
    this.tailHeight = 8.0, // 꼬리 높이
    this.tailWidth = 12.0, // 꼬리 밑변 너비
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final Paint fillPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    // 사각형 몸통 경로 (꼬리 높이만큼 아래 공간 확보)
    final RRect bubbleBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
      Radius.circular(borderRadius),
    );

    // 꼬리 경로 (아래 중앙)
    final Path tail = Path();
    // 꼬리 시작점 (중앙 약간 왼쪽)
    tail.moveTo(size.width / 2 - tailWidth / 2, size.height - tailHeight);
    // 꼬리 끝점 (아래 중앙)
    tail.lineTo(size.width / 2, size.height);
    // 꼬리 돌아오는 점 (중앙 약간 오른쪽)
    tail.lineTo(size.width / 2 + tailWidth / 2, size.height - tailHeight);
    tail.close();

    // 몸통과 꼬리 합치기 (또는 따로 그리기)
    // 여기서는 따로 그려서 테두리가 꼬리에도 적용되도록 함
    final Path bubblePath = Path()..addRRect(bubbleBody);

    // 채우기 먼저
    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(tail, fillPaint); // 꼬리도 채우기

    // 테두리 그리기
    canvas.drawPath(bubblePath, borderPaint); // 몸통 테두리
    // 꼬리 테두리 (moveTo 제외하고 라인만)
    canvas.drawLine(
      Offset(size.width / 2 - tailWidth / 2, size.height - tailHeight),
      Offset(size.width / 2, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2 + tailWidth / 2, size.height - tailHeight),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // 색상 등 변경 시 다시 그리도록 설정
    return oldDelegate is SpeechBubblePainter &&
        (oldDelegate.borderColor != borderColor ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.strokeWidth != strokeWidth ||
            oldDelegate.borderRadius != borderRadius ||
            oldDelegate.tailHeight != tailHeight ||
            oldDelegate.tailWidth != tailWidth);
  }
}

// --- 말풍선 위젯 ---
class SpeechBubble extends StatelessWidget {
  final Widget child; // 말풍선 안에 들어갈 위젯 (주로 Text)
  final Color borderColor;
  final Color backgroundColor;
  final double tailHeight;
  final double tailWidth;
  final EdgeInsets padding;

  const SpeechBubble({
    Key? key,
    required this.child,
    required this.borderColor,
    this.backgroundColor = Colors.white, // 기본 배경 흰색
    this.tailHeight = 8.0,
    this.tailWidth = 12.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 4,
    ), // 내부 패딩
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpeechBubblePainter(
        borderColor: borderColor,
        backgroundColor: backgroundColor,
        tailHeight: tailHeight,
        tailWidth: tailWidth,
      ),
      child: Padding(
        // 꼬리 높이만큼 아래 패딩을 주어 텍스트가 꼬리와 겹치지 않게 함
        padding: padding.copyWith(bottom: padding.bottom + tailHeight),
        child: child,
      ),
    );
  }
}
