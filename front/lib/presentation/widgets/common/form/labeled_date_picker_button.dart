import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:intl/intl.dart';

/// 레이블과 날짜 선택 버튼을 포함하는 공용 위젯
class LabeledDatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onConfirm; // 날짜 확정 시 호출될 콜백
  final bool isRequired;
  final bool isEnabled; // 버튼 활성화 여부 (예: 저장 중 비활성화)
  final DateTime? minTime;
  final DateTime? maxTime;
  final DateTime? initialTime; // DatePicker 초기 시간

  const LabeledDatePickerButton({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onConfirm,
    this.isRequired = false,
    this.isEnabled = true, // 기본값 활성화
    this.minTime,
    this.maxTime,
    this.initialTime,
  });

  @override
  Widget build(BuildContext context) {
    // --- 수정 시작: 버튼에 표시될 텍스트 포맷 정의 (힌트에서 "(선택)" 제거) ---
    final String buttonText =
        selectedDate == null
            ? label // 날짜가 선택되지 않았을 때 레이블 텍스트만 표시 (예: '생년월일')
            : '$label: ${DateFormat('yyyy.MM.dd').format(selectedDate!)}'; // 선택된 날짜 표시
    // --- 수정 종료 ---

    // 힌트 텍스트 색상 로직은 그대로 유지 (selectedDate == null 일 때 회색)
    final Color textColor =
        selectedDate == null ? Colors.grey[600]! : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블 (버튼 텍스트에 포함되므로 별도 Text 위젯은 제거 가능하나, 일관성을 위해 남겨둘 수 있음)
        // Text.rich(...) // 현재 코드는 이 부분 주석 처리되어 있음. 그대로 둡니다.

        // 날짜 선택 버튼
        TextButton.icon(
          icon: Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
          label: Text(
            buttonText, // 수정된 buttonText 사용
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            foregroundColor: Colors.black87, // 아이콘 색상 등에 영향
            disabledForegroundColor: Colors.grey.shade400, // 비활성화 시 색상
            disabledBackgroundColor: Colors.grey.shade200,
          ),
          onPressed:
              !isEnabled // 활성화 상태가 아닐 때 null 전달하여 비활성화
                  ? null
                  : () {
                    picker.DatePicker.showDatePicker(
                      context,
                      showTitleActions: true,
                      minTime: minTime ?? DateTime(1900, 1, 1),
                      maxTime: maxTime ?? DateTime.now(),
                      onConfirm: onConfirm, // 전달받은 콜백 실행
                      currentTime:
                          selectedDate ??
                          initialTime ??
                          DateTime.now().subtract(
                            const Duration(days: 365 * 30),
                          ),
                      locale: picker.LocaleType.ko,
                      theme: const picker.DatePickerTheme(
                        // 기본 테마 (필요시 외부에서 주입 가능)
                        headerColor: Colors.white,
                        backgroundColor: Colors.white,
                        itemStyle: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        doneStyle: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        cancelStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
        ),
      ],
    );
  }
}
