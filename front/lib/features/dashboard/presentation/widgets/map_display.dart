// lib/features/dashboard/presentation/widgets/map_display.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // 웹뷰 패키지 import

class MapDisplay extends StatefulWidget {
  final String? mapHtmlContent; // 표시할 지도 HTML 내용

  const MapDisplay({super.key, this.mapHtmlContent});

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  late final WebViewController _controller; // 웹뷰 컨트롤러

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted); // 자바스크립트 활성화
    _loadHtml();
  }

  @override
  void didUpdateWidget(covariant MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // HTML 내용이 변경되면 다시 로드
    if (widget.mapHtmlContent != oldWidget.mapHtmlContent) {
      _loadHtml();
    }
  }

  void _loadHtml() {
    if (widget.mapHtmlContent != null && widget.mapHtmlContent!.isNotEmpty) {
      _controller.loadHtmlString(widget.mapHtmlContent!);
    } else {
      // HTML 내용이 없을 때 기본 메시지 표시
      _controller.loadHtmlString(
        '<html><body><p>표시할 지도 정보가 없습니다.</p></body></html>',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹뷰를 표시 (크기 조절 필요)
    // AspectRatio 또는 SizedBox, Container 등으로 감싸서 크기 지정
    return SizedBox(
      height: 300, // 예시 높이
      child: WebViewWidget(controller: _controller),
    );
  }
}
