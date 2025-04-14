import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/app_data_provider.dart';
import '../constants/app_constants.dart';

class ShelterMapSection extends StatefulWidget {
  const ShelterMapSection({super.key});

  @override
  State<ShelterMapSection> createState() => _ShelterMapSectionState();
}

class _ShelterMapSectionState extends State<ShelterMapSection> {
  // 웹뷰 컨트롤러는 상태 내에서 관리
  WebViewController? _webViewController;
  ShelterType? _currentDisplayedMapType; // 현재 웹뷰에 로드된 지도 타입

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider 데이터가 변경될 때마다 웹뷰 업데이트 로직 호출 가능성 있음
    // 하지만 여기서는 Provider의 리스너를 통해 필요한 시점에만 업데이트
  }

  // 웹뷰 컨트롤러 초기화 및 업데이트
  void _updateWebViewController(String htmlContent, ShelterType type) {
    if (_webViewController == null || _currentDisplayedMapType != type) {
      // 새 컨트롤러 생성 또는 타입 변경 시
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {},
                onPageStarted: (String url) {},
                onPageFinished: (String url) {},
                onWebResourceError: (WebResourceError error) {
                  print("WebView Error for $type: ${error.description}");
                  // Provider를 통해 에러 상태 업데이트 가능
                  Provider.of<AppDataProvider>(
                        context,
                        listen: false,
                      ).mapErrorMessages[type] =
                      "WebView 오류: ${error.description}";
                  Provider.of<AppDataProvider>(
                    context,
                    listen: false,
                  ).notifyListeners();
                },
              ),
            )
            ..loadHtmlString(htmlContent, baseUrl: null); // baseUrl 필요시 설정

      _currentDisplayedMapType = type;
      print("WebView re-initialized and loading HTML for $type");
    } else {
      // 기존 컨트롤러에 새 HTML 로드 (더 효율적일 수 있음)
      // 단, 복잡한 JS 상태 유지가 필요 없을 경우에만 권장
      _webViewController!.loadHtmlString(htmlContent, baseUrl: null);
      print("WebView loading updated HTML for $type");
    }

    // 위젯 rebuild를 강제할 필요가 있다면 setState 호출
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider를 사용하여 상태 접근
    return Consumer<AppDataProvider>(
      builder: (context, appData, child) {
        final selectedType = appData.selectedShelterType;
        final isLoading =
            appData.isLoadingMaps[selectedType] ?? true; // 로딩 상태 확인 (기본값 true)
        final htmlContent =
            appData.shelterMapHtmls[selectedType]; // 선택된 타입의 HTML
        final errorMessage =
            appData.mapErrorMessages[selectedType]; // 선택된 타입의 에러

        // 선택된 타입의 HTML이 있고, 로딩 중이 아니며, 웹뷰 컨트롤러 준비가 필요할 때
        if (!isLoading &&
            htmlContent != null &&
            htmlContent.isNotEmpty &&
            errorMessage == null) {
          // 현재 웹뷰에 표시된 타입과 다르거나, 웹뷰가 아직 없다면 업데이트
          if (_webViewController == null ||
              _currentDisplayedMapType != selectedType) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // 위젯이 여전히 마운트 상태인지 확인
                _updateWebViewController(htmlContent, selectedType);
              }
            });
          }
        } else if (htmlContent == null && !isLoading) {
          // 로딩이 끝났는데 컨텐츠가 없으면 (오류 포함) 웹뷰 클리어 필요
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //    if (mounted && _webViewController != null) {
          //      // _webViewController?.loadHtmlString(''); // 빈 페이지 로드
          //      // _currentDisplayedMapType = null;
          //      // setStateIfMounted();
          //    }
          // });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 대피소 유형 선택 UI (FilterChip 사용) ---
            Text(
              "대피소 유형 선택",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              // 화면 너비에 따라 자동 줄바꿈
              spacing: 8.0, // 칩 사이 간격
              runSpacing: 4.0, // 줄 사이 간격
              children:
                  ShelterType.values.map((type) {
                    bool isSelected = type == selectedType;
                    bool isChipLoading =
                        appData.isLoadingMaps[type] ?? false; // 개별 칩 로딩 상태

                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.displayName),
                          if (isChipLoading) // 로딩 중이면 인디케이터 표시
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      isSelected ? Colors.white : primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected:
                          isChipLoading
                              ? null
                              : (bool selected) {
                                // 로딩 중 아닐 때만 선택 가능
                                if (selected) {
                                  appData.selectShelterType(type);
                                }
                              },
                      selectedColor: chipSelectedColor, // 선택 시 배경색
                      checkmarkColor: Colors.white, // 선택 시 체크 아이콘 색상
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : chipUnselectedColor, // 선택 여부에 따른 글자색
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white, // 미선택 시 배경색
                      shape: StadiumBorder(
                        side: BorderSide(
                          color:
                              isSelected
                                  ? chipSelectedColor
                                  : chipUnselectedColor.withOpacity(0.5),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 16),

            // --- 지도 표시 영역 ---
            Container(
              height: 400, // 지도의 높이 고정
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey[200], // 로딩/에러 시 배경색
              ),
              child: _buildMapView(
                isLoading,
                htmlContent,
                errorMessage,
                selectedType,
              ),
            ),
          ],
        );
      },
    );
  }

  // 지도 상태에 따라 다른 위젯 반환
  Widget _buildMapView(
    bool isLoading,
    String? htmlContent,
    String? errorMessage,
    ShelterType selectedType,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              "${selectedType.displayName} 대피소 지도 로딩 중...",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "오류: ${selectedType.displayName} 지도를 불러올 수 없습니다.\n(${errorMessage.length > 100 ? errorMessage.substring(0, 100) + '...' : errorMessage})",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      );
    } else if (htmlContent != null &&
        htmlContent.isNotEmpty &&
        _webViewController != null &&
        _currentDisplayedMapType == selectedType) {
      // 로딩 완료, 에러 없음, HTML 있음, 웹뷰 준비됨
      return ClipRRect(
        // 테두리 적용
        borderRadius: BorderRadius.circular(11.0), // 컨테이너보다 약간 작게
        child: WebViewWidget(controller: _webViewController!),
      );
    } else {
      // 로딩 완료했지만 표시할 수 없는 상태 (HTML이 비었거나 웹뷰 준비 안됨 등)
      return Center(
        child: Text(
          "${selectedType.displayName} 지도를 표시할 수 없습니다.",
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }
  }

  void setStateIfMounted() {
    if (mounted) {
      setState(() {});
    }
  }
}
