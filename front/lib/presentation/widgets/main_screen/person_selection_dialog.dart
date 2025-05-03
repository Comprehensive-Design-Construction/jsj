import 'package:flutter/material.dart';
import '../../../data/models/added_person.dart';
// import '../../screens/main/main_screen_notifier.dart'; // myInfoId 사용 위해 필요
import '../../../core/constants/app_constants.dart';

// 반환 타입 정의 (선택 사항이지만 명확성 위해)
enum PersonSelectionResult { addNew, selectedPersonId, dismissed }

class PersonSelectionDialog extends StatelessWidget {
  final String currentSelectedPersonId;
  final List<AddedPerson> addedPeople;

  const PersonSelectionDialog({
    super.key,
    required this.currentSelectedPersonId,
    required this.addedPeople,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('사용자 선택', textAlign: TextAlign.center),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      contentPadding: const EdgeInsets.fromLTRB(
        0.0,
        12.0,
        0.0,
        16.0,
      ), // 상하 패딩 조정
      children: [
        // 1. 내 정보 항목
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, myInfoId); // 'MY_INFO' ID 반환
          },
          child: ListTile(
            leading: Icon(Icons.person_pin_circle, color: Colors.blueAccent),
            title: Text(
              "내 정보",
              style: TextStyle(
                fontWeight:
                    currentSelectedPersonId == myInfoId
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
            // 현재 선택된 항목 표시 (선택 사항)
            trailing:
                currentSelectedPersonId == myInfoId
                    ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
          ),
        ),

        // 2. 추가된 사람 목록
        ...addedPeople.map((person) {
          final bool isSelected = person.id == currentSelectedPersonId;
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, person.id); // 선택된 사람 ID 반환
            },
            child: ListTile(
              leading: Icon(Icons.person_outline, color: Colors.grey[700]),
              title: Text(
                person.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing:
                  isSelected
                      ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : null,
              contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
              // TODO: 여기서 X 버튼 눌러 삭제하는 기능 추가 가능
            ),
          );
        }).toList(),

        // 3. 구분선 및 추가 버튼
        const Divider(height: 20, indent: 20, endIndent: 20),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context, 'ADD_NEW'); // '추가' 액션 식별자 반환
          },
          child: ListTile(
            leading: Icon(Icons.add_circle_outline, color: Colors.black54),
            title: const Text(
              '새로운 사람 추가',
              style: TextStyle(color: Colors.black54),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
          ),
        ),
      ],
    );
  }
}
