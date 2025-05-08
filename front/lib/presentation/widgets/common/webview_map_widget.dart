// lib/presentation/widgets/common/webview_map_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewMapWidget extends StatelessWidget {
  final WebViewController? controller;
  final IconData placeholderIcon;
  final String placeholderText;
  final double aspectRatio;

  const WebViewMapWidget({
    super.key,
    required this.controller,
    required this.placeholderIcon,
    required this.placeholderText,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              controller != null
                  ? WebViewWidget(
                    controller: controller!,
                    // --- 제스처 인식기 설정 추가 ---
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                      ),
                      // Factory<HorizontalDragGestureRecognizer>( // 가로 이동이 필요하다면 추가
                      //   () => HorizontalDragGestureRecognizer(),
                      // ),
                      Factory<ScaleGestureRecognizer>(
                        // 확대/축소 제스처
                        () => ScaleGestureRecognizer(),
                      ),
                      // 만약 WebView 내부 스크롤이 앱의 전체 스크롤과 충돌한다면,
                      // EagerGestureRecognizer를 사용하여 WebView가 제스처를 우선적으로 처리하도록 할 수 있습니다.
                      // Factory<EagerGestureRecognizer>(
                      //   () => EagerGestureRecognizer(),
                      // ),
                    },
                    // --- ---------------------- ---
                  )
                  : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          placeholderText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
