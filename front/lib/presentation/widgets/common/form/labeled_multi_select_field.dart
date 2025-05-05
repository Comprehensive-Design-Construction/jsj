import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

/// 레이블과 MultiSelectDialogField를 포함하는 공용 위젯
class LabeledMultiSelectField<T> extends StatelessWidget {
  final String label;
  final List<MultiSelectItem<T>> items; // 전체 선택 가능 항목 리스트
  final List<T> initialValue; // 현재 선택된 값 리스트
  final String buttonHint; // 버튼에 표시될 기본 텍스트 (선택 없을 때)
  final String dialogTitle;
  final String searchHint;
  final Function(List<T>) onConfirm; // 최종 확인 시 선택된 값 리스트(List) 콜백
  final Function(T)? onItemTapped; // Chip 탭 시 호출될 콜백 (개별 제거용)
  final bool isRequired;
  final bool isEnabled; // 필드 활성화 여부

  const LabeledMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.initialValue,
    required this.buttonHint,
    required this.dialogTitle,
    required this.searchHint,
    required this.onConfirm,
    this.onItemTapped,
    this.isRequired = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블 텍스트
        Text.rich(
          TextSpan(
            text: label,
            style: Theme.of(context).textTheme.titleSmall,
            children:
                isRequired
                    ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        // 멀티 선택 다이얼로그 필드
        AbsorbPointer(
          // isEnabled가 false이면 터치 막기
          absorbing: !isEnabled,
          child: MultiSelectDialogField<T>(
            items: items,
            initialValue: initialValue,
            title: Text(dialogTitle),
            searchable: true,
            searchHint: searchHint,
            confirmText: const Text('확인'),
            cancelText: const Text('취소'),
            listType: MultiSelectListType.LIST, // 리스트 형태 다이얼로그
            selectedColor: Colors.blueAccent, // 선택 항목 강조색
            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
            buttonText: Text(
              // 버튼 텍스트 로직
              initialValue.isEmpty
                  ? buttonHint
                  : initialValue
                      .map((e) => e.toString())
                      .join(', '), // 선택된 항목 표시
              style: TextStyle(
                color:
                    initialValue.isEmpty
                        ? (isEnabled
                            ? Colors.grey[600]
                            : Colors.grey[400]) // 활성화 상태에 따라 힌트 색상 변경
                        : (isEnabled
                            ? Colors.black87
                            : Colors.grey[500]), // 활성화 상태에 따라 선택값 색상 변경
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            decoration: BoxDecoration(
              // 버튼 모양
              color:
                  isEnabled
                      ? Colors.grey[100]
                      : Colors.grey[200], // 활성화 상태에 따라 배경색 변경
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            onConfirm: onConfirm, // 확인 콜백 연결
            chipDisplay: MultiSelectChipDisplay<T>(
              // 선택된 항목 칩으로 표시
              chipColor: Colors.blueAccent.withOpacity(0.15),
              textStyle: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 13,
              ),
              icon:
                  onItemTapped != null
                      ? const Icon(
                        Icons.close,
                        color: Colors.blueAccent,
                        size: 16,
                      )
                      : null, // 삭제 콜백 있으면 아이콘 표시
              onTap: onItemTapped, // 칩 탭 콜백 연결
              // scrollBar: HorizontalScrollBar(), // 필요시 스크롤바
            ),
            // validator: (value) => ... // 필요시 유효성 검사 추가
          ),
        ),
      ],
    );
  }
}
