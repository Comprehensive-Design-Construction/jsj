import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView 지도를 표시하는 공용 위젯
class WebViewMapWidget extends StatelessWidget {
  final WebViewController? controller; // Nullable WebViewController
  final IconData placeholderIcon;
  final String placeholderText;
  final double aspectRatio; // 종횡비

  const WebViewMapWidget({
    super.key,
    required this.controller,
    required this.placeholderIcon,
    required this.placeholderText,
    this.aspectRatio = 16 / 9, // 기본값 16:9
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // 플레이스홀더 배경색
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!), // 테두리
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              controller != null
                  // WebViewController가 있으면 WebView 표시
                  ? WebViewWidget(controller: controller!)
                  // 없으면 플레이스홀더 표시
                  : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                        SizedBox(height: 8),
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
