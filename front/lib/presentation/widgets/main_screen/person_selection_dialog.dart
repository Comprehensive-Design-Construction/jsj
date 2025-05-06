import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart'; // myInfoId 사용
import '../../../data/models/added_person.dart';

/// 사용자 선택 다이얼로그의 내용을 구성하는 위젯
class PersonSelectionDialogContent extends StatelessWidget {
  final String currentSelectedPersonId;
  final List<AddedPerson> addedPeople;

  const PersonSelectionDialogContent({
    super.key,
    required this.currentSelectedPersonId,
    required this.addedPeople,
  });

  // --- 삭제 확인 다이얼로그 (기존과 동일) ---
  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    String personName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text(
            '사용자 삭제',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '\'$personName\' 님을 목록에서 삭제하시겠습니까?',
            style: TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 8.0,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // --- 리스트 항목 공통 스타일 위젯 (선택적 분리) ---
  // InkWell 및 기본 Row 구조를 포함하는 내부 위젯을 만들어 중복을 더 줄일 수 있습니다.
  // 여기서는 각 빌더 함수 내에서 직접 구현합니다.

  // --- 1. 헤더 항목 빌더 ---
  Widget _buildHeaderItem(
    BuildContext context,
    String title,
    Color iconBgColor,
    bool isMyInfo,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(), // 헤더 탭 시 닫기
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 아이콘 (선택 점 포함)
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20, // 헤더 아이콘 크게
                  backgroundColor: iconBgColor,
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.white,
                  ), // 아이콘 고정
                ),
                // 현재 선택된 항목('내 정보')일 때 녹색 점 표시
                if (isMyInfo) // 헤더는 항상 isSelected=true 이므로 isMyInfo만 체크
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // 이름
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 드롭다운 아이콘
            SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. 사용자 항목 빌더 ---
  Widget _buildPersonItem(
    BuildContext context,
    AddedPerson person,
    bool isMyInfo,
    bool isSelected,
  ) {
    final Color iconBgColor =
        Colors.purple[400]!; // 고정 색상 (또는 person별 색상 로직 추가)

    return InkWell(
      onTap: () => Navigator.pop(context, person.id), // 선택 시 ID 반환
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // 아이콘 (선택 표시는 현재 사용 안 함)
            CircleAvatar(
              radius: 18,
              backgroundColor: iconBgColor,
              child: Icon(
                isMyInfo
                    ? Icons.person
                    : Icons.person_outline, // 내 정보/다른 사용자 아이콘 구분
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // 이름
            Expanded(
              child: Text(
                person.name,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 삭제 버튼 ('내 정보'가 아닐 때만 표시)
            SizedBox(
              width: 40,
              height: 40,
              child:
                  isMyInfo
                      ? null
                      : IconButton(
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () async {
                          final confirmDelete = await _showDeleteConfirmDialog(
                            context,
                            person.name,
                          );
                          if (confirmDelete && context.mounted) {
                            Navigator.pop(context, 'DELETE:${person.id}');
                          }
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        tooltip: '삭제', // Tooltip 추가
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. 추가 버튼 빌더 ---
  Widget _buildAddItem(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, 'ADD_NEW'), // 'ADD_NEW' 액션 ID 반환
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // 아이콘
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.add, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(width: 16),
            // 텍스트
            Expanded(
              child: Text(
                '추가',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
            ),
            // 오른쪽 공간 확보 (삭제 버튼 자리)
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 현재 선택된 사용자 정보 계산 (기존 로직 유지) ---
    final AddedPerson? currentPerson =
        (currentSelectedPersonId != myInfoId)
            ? addedPeople.firstWhere(
              (p) => p.id == currentSelectedPersonId,
              orElse: () => AddedPerson(id: '', name: '사용자'),
            )
            : null;
    final String currentName =
        (currentSelectedPersonId == myInfoId) ? "내 정보" : currentPerson!.name;
    final Color currentIconBgColor = Colors.purple[400]!; // 고정 색상

    // --- 표시될 사용자 리스트 ('내 정보' 포함) ---
    final myInfo = AddedPerson(
      id: myInfoId,
      name: "내 정보",
    ); // gender 등 다른 필드는 불필요
    final List<AddedPerson> displayList = [myInfo, ...addedPeople];

    return Container(
      // 다이얼로그 전체 컨테이너 스타일 (기존과 동일)
      margin: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 8.0,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 상단 고정: 현재 선택된 사용자 (헤더 빌더 사용) ---
            _buildHeaderItem(
              context,
              currentName,
              currentIconBgColor,
              currentSelectedPersonId == myInfoId, // isMyInfo 전달
            ),
            // Divider(height: 1, thickness: 1, indent: 16, endIndent: 16), // 필요시 구분선

            // --- 2. 스크롤 가능 목록 (사용자 빌더 사용) ---
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final person = displayList[index];
                  bool isMyInfo = person.id == myInfoId;
                  bool isSelected =
                      person.id ==
                      currentSelectedPersonId; // 선택 여부 (현재 UI에선 미사용)

                  // 사용자 항목 빌더 호출
                  return _buildPersonItem(
                    context,
                    person,
                    isMyInfo,
                    isSelected,
                  );
                },
              ),
            ),
            // Divider(height: 1, thickness: 1, indent: 16, endIndent: 16), // 필요시 구분선

            // --- 3. 추가 버튼 (추가 버튼 빌더 사용) ---
            _buildAddItem(context),
          ],
        ),
      ),
    );
  }
}
