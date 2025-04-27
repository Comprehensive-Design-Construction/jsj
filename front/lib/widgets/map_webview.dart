import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../screens/loading_error/loading_indicator.dart'; // 로딩 인디케이터 위젯

/// HTML 컨텐츠를 표시하는 WebView 위젯
class MapWebView extends StatefulWidget {
  final String? htmlContent; // 표시할 HTML 문자열 (null 가능)
  final String mapKey; // WebView 식별 및 상태 관리를 위한 고유 키

  const MapWebView({
    super.key,
    required this.htmlContent,
    required this.mapKey,
  });

  @override
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  // WebView 컨트롤러 선언 (late 키워드 사용)
  late final WebViewController _controller;
  bool _isLoading = true; // 로딩 상태 플래그
  bool _hasError = false; // 오류 발생 플래그

  @override
  void initState() {
    super.initState();
    _initializeWebView(); // WebView 초기화 로직 분리
  }

  // WebView 컨트롤러 초기화 및 HTML 로드
  void _initializeWebView() {
    final html = widget.htmlContent; // 현재 위젯의 HTML 컨텐츠 가져오기

    // HTML 컨텐츠가 유효한 경우에만 컨트롤러 설정 및 로드
    if (html != null && html.isNotEmpty) {
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted) // JavaScript 활성화
            ..setBackgroundColor(const Color(0x00000000)) // 배경 투명 처리 (선택 사항)
            ..setNavigationDelegate(
              // 네비게이션 이벤트 처리
              NavigationDelegate(
                onProgress: (int progress) {
                  // 페이지 로딩 진행률 (필요시 사용)
                },
                onPageStarted: (String url) {
                  // 페이지 로딩 시작 시 로딩 상태 업데이트
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                  }
                },
                onPageFinished: (String url) {
                  // 페이지 로딩 완료 시 로딩 상태 업데이트
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onWebResourceError: (WebResourceError error) {
                  // 웹 리소스 로딩 오류 발생 시 (네트워크, HTML 오류 등)
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                  }
                  print("WebView 오류 (${widget.mapKey}): ${error.description}");
                  // 사용자에게 오류 메시지 표시 고려
                },
                // 필요에 따라 onNavigationRequest 등 다른 델리게이트 추가
              ),
            )
            // 제공된 HTML 문자열 로드
            ..loadHtmlString(html, baseUrl: null); // baseUrl은 필요시 설정
    } else {
      // 초기 HTML 컨텐츠가 null이거나 비어있는 경우 오류 상태로 처리
      _isLoading = false;
      _hasError = true;
      print("WebView 오류 (${widget.mapKey}): 초기 HTML 컨텐츠 없음.");
    }
  }

  // 위젯이 업데이트될 때 호출 (예: 다른 지도 버튼 클릭)
  @override
  void didUpdateWidget(covariant MapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // HTML 컨텐츠가 변경되었고, 새로운 컨텐츠가 유효한 경우 WebView 리로드
    if (widget.htmlContent != oldWidget.htmlContent &&
        widget.htmlContent != null &&
        widget.htmlContent!.isNotEmpty) {
      _isLoading = true; // 로딩 상태 초기화
      _hasError = false;
      print("WebView 리로드: ${widget.mapKey}");
      // 컨트롤러가 초기화된 경우에만 로드 시도
      // initState에서 _hasError가 true가 된 경우 controller가 없을 수 있음
      if (mounted &&
          !_hasError &&
          widget.htmlContent != null &&
          widget.htmlContent!.isNotEmpty) {
        // 컨트롤러 초기화 시도
        try {
          _controller.loadHtmlString(widget.htmlContent!, baseUrl: null);
        } catch (e) {
          print("WebView 리로드 오류 (${widget.mapKey}): $e");
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        }
      } else if (widget.htmlContent == null || widget.htmlContent!.isEmpty) {
        // 업데이트된 HTML이 유효하지 않은 경우
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        print("WebView 오류 (${widget.mapKey}): 업데이트된 HTML 컨텐츠 없음.");
        // 필요시 빈 페이지 또는 에러 페이지 로드
        // _controller.loadHtmlString('<html><body>지도 로딩 실패</body></html>');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 지도 비율 유지를 위해 AspectRatio 사용 (100:60은 예시, 실제 HTML 비율에 맞춤)
    return AspectRatio(
      aspectRatio: 100 / 60,
      child: Stack(
        alignment: Alignment.center, // 로딩/에러 메시지 중앙 정렬
        children: [
          // 오류가 없고 HTML 컨텐츠가 있을 때만 WebView 표시
          if (!_hasError &&
              widget.htmlContent != null &&
              widget.htmlContent!.isNotEmpty)
            WebViewWidget(controller: _controller),

          // 로딩 중일 때 로딩 인디케이터 표시
          if (_isLoading) const LoadingIndicator(),

          // 오류 발생 시 에러 메시지 표시
          if (_hasError)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("지도 로딩 실패", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
