import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/added_person.dart';

class PersonSelectionDialogContent extends StatelessWidget {
  final String currentSelectedPersonId;
  final List<AddedPerson> addedPeople;

  const PersonSelectionDialogContent({
    super.key,
    required this.currentSelectedPersonId,
    required this.addedPeople,
  });

  // 삭제 확인 다이얼로그 표시 함수
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
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // 각 리스트 아이템 빌더 (스타일 조정)
  Widget _buildListItem({
    required BuildContext context,
    required IconData iconData,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
    String? personId,
    bool isMyInfo = false,
    bool isSelected = false,
    bool showTrailing = true,
    bool isAddButton = false,
    bool isHeader = false, // 상단 헤더 스타일 구분용
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isHeader ? 12.0 : 8.0,
        ), // 헤더와 항목 패딩 다르게
        child: Row(
          children: [
            // 아이콘 (헤더/일반/추가 구분)
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: isHeader ? 20 : 18, // 헤더 아이콘 크게
                  backgroundColor: isAddButton ? Colors.grey[200] : iconBgColor,
                  child: Icon(
                    iconData,
                    size: isAddButton ? 20 : (isHeader ? 24 : 20), // 아이콘 크기 조정
                    color: isAddButton ? Colors.grey[700] : Colors.white,
                  ),
                ),
                // 현재 선택된 항목(isSelected)이고 '내 정보'일 때 녹색 점 표시
                if (isMyInfo && isSelected)
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
                style: TextStyle(
                  fontSize: isHeader ? 16 : 15, // 헤더 폰트 크게
                  fontWeight:
                      isHeader ? FontWeight.bold : FontWeight.normal, // 헤더만 볼드
                  color: isAddButton ? Colors.grey[700] : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 삭제 버튼 또는 빈 공간
            if (showTrailing)
              SizedBox(
                width: 40,
                height: 40,
                child:
                    isHeader
                        ? Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                        ) // 헤더에는 드롭다운 아이콘
                        : (isMyInfo || personId == null || isAddButton)
                        ? null // 내 정보, 추가 버튼에는 삭제 아이콘 없음
                        : IconButton(
                          // 삭제 버튼 (목업 스타일 적용)
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirmDelete =
                                await _showDeleteConfirmDialog(context, title);
                            if (confirmDelete && context.mounted) {
                              Navigator.pop(context, 'DELETE:$personId');
                            }
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 사용자 정보
    final AddedPerson? currentPerson =
        (currentSelectedPersonId != myInfoId)
            ? addedPeople.firstWhere(
              (p) => p.id == currentSelectedPersonId,
              orElse: () => AddedPerson(id: '', name: '사용자'),
            )
            : null;
    final String currentName =
        (currentSelectedPersonId == myInfoId) ? "내 정보" : currentPerson!.name;
    final Color currentIconBgColor = Colors.purple[400]!; // 목업 색상 적용

    // 표시될 사용자 리스트 ('내 정보' 포함)
    final myInfo = AddedPerson(id: myInfoId, name: "내 정보");
    final List<AddedPerson> displayList = [myInfo, ...addedPeople];

    return Container(
      // 다이얼로그 전체 컨테이너 (목업 카드 스타일)
      margin: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 8.0,
        left: 16.0,
        right: 16.0,
      ), // AppBar 아래 위치 + 좌우 여백
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
            // --- 1. 상단 고정: 현재 선택된 사용자 (목업 HeaderCard 스타일) ---
            _buildListItem(
              context: context,
              iconData: Icons.person, // 아이콘 통일
              iconBgColor: currentIconBgColor,
              title: currentName,
              isMyInfo: currentSelectedPersonId == myInfoId,
              isSelected: true, // 항상 현재 선택된 상태
              showTrailing: true, // 드롭다운 아이콘 표시
              isHeader: true, // 헤더 스타일 적용
              onTap: () => Navigator.of(context).pop(), // 탭하면 닫기
            ),
            // 구분선 필요 시 추가
            // const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

            // --- 2. 스크롤 가능 목록 ---
            ConstrainedBox(
              // 최대 높이 제한
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5, // 화면 절반 정도
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0), // 목록 상하 여백
                itemCount: displayList.length, // '내 정보' 포함
                itemBuilder: (context, index) {
                  final person = displayList[index];
                  bool isMyInfo = person.id == myInfoId;
                  bool isSelected =
                      person.id == currentSelectedPersonId; // 현재 선택 여부

                  return _buildListItem(
                    context: context,
                    iconData: isMyInfo ? Icons.person : Icons.person_outline,
                    iconBgColor: Colors.purple[400]!, // 목업 색상
                    title: person.name,
                    personId: person.id,
                    isMyInfo: isMyInfo,
                    isSelected: isSelected, // 선택 상태 전달 (현재는 사용 안 함)
                    showTrailing: true, // 삭제 버튼 영역 표시
                    onTap:
                        () => Navigator.pop(context, person.id), // 선택 시 ID 반환
                  );
                },
              ),
            ),

            // 구분선 필요 시 추가
            // const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

            // --- 3. 추가 버튼 (목업 AddItem 스타일) ---
            _buildListItem(
              context: context,
              iconData: Icons.add,
              iconBgColor: Colors.grey[200]!,
              title: '추가',
              isAddButton: true, // 추가 버튼 스타일 적용
              showTrailing: false, // 오른쪽 아이콘 없음
              onTap: () => Navigator.pop(context, 'ADD_NEW'),
            ),
          ],
        ),
      ),
    );
  }
}
