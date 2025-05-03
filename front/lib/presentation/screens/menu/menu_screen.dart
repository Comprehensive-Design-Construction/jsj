import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart'; // 정의된 상수 사용
import '../../../core/utils/preferences_service.dart'; // Preferences 서비스
import '../profile/edit_profile_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final PreferencesService _prefsService = PreferencesService();

  // 상태 변수: 보이는 지수 이름들의 Set
  Set<String> _visibleIndices = {}; // 초기 빈 Set
  bool _isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadVisibleIndices(); // 저장된 설정 불러오기
  }

  // 저장된 보이는 지수 목록 불러오기
  Future<void> _loadVisibleIndices() async {
    setState(() => _isLoading = true); // 로딩 시작

    Set<String>? savedIndices = await _prefsService.getVisibleIndices();

    if (savedIndices == null) {
      // 저장된 값이 없으면 (첫 실행 등), 모든 지수를 기본값으로 선택
      _visibleIndices = availableHealthIndices.toSet();
      // 기본값을 저장소에도 저장 (선택 사항)
      // await _prefsService.saveVisibleIndices(_visibleIndices);
    } else {
      _visibleIndices = savedIndices;
    }

    if (mounted) {
      setState(() => _isLoading = false); // 로딩 완료
    }
  }

  // 지수 보이기/숨기기 토글 및 저장
  Future<void> _toggleIndexVisibility(String indexName) async {
    setState(() {
      if (_visibleIndices.contains(indexName)) {
        _visibleIndices.remove(indexName); // 있으면 제거
      } else {
        _visibleIndices.add(indexName); // 없으면 추가
      }
    });
    // 변경된 상태를 즉시 저장
    await _prefsService.saveVisibleIndices(_visibleIndices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9), // 배경색 (깡통 UI 참고)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // title을 왼쪽 정렬하고 싶으면 leading 사용 또는 centerTitle 조정
        leading: IconButton(
          // 뒤로가기 버튼 추가 (일반적인 메뉴 화면)
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // 이전 화면으로 돌아가기
        ),
        title: Text(
          '메뉴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        // actions: [ IconButton( icon: Icon(Icons.settings, color: Colors.black), onPressed: () {}, ), ], // 설정 아이콘 등으로 변경 가능
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      '사용자 정보 변경', // TODO: 해당 기능 구현 시 네비게이션 추가
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ListTile(
                      // 예시: 탭 가능한 ListTile
                      title: Text(
                        '내 정보 수정하기',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '건강 지수 추가 / 제거',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            availableHealthIndices.length, // 정의된 전체 지수 목록 사용
                        itemBuilder: (context, index) {
                          final String indexName =
                              availableHealthIndices[index]; // 현재 지수 이름
                          final bool isVisible = _visibleIndices.contains(
                            indexName,
                          ); // 보이는지 여부 확인

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // 모서리 둥글기 조정
                                boxShadow: [
                                  // 약간의 그림자 효과 (선택 사항)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  indexName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    // isVisible 값에 따라 아이콘 변경
                                    isVisible
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.orangeAccent, // 색상 통일
                                    size: 28, // 아이콘 크기 살짝 키움
                                  ),
                                  onPressed: () {
                                    // 아이콘 탭 시 상태 변경 및 저장 함수 호출
                                    _toggleIndexVisibility(indexName);
                                  },
                                  tooltip:
                                      isVisible
                                          ? '$indexName 숨기기'
                                          : '$indexName 보이기',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
