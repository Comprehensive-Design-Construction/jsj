import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 지도 타입 선택 드롭다운 공용 위젯
class MapTypeDropdownWidget extends ConsumerWidget {
  final Map<String, String> mapTypes; // 드롭다운 아이템 (Value: Label)
  final String selectedValue; // 현재 선택된 값
  final ValueChanged<String?> onChanged; // 값 변경 시 호출될 콜백
  final bool isLoading; // 로딩 상태 (비활성화 처리용)

  const MapTypeDropdownWidget({
    super.key,
    required this.mapTypes,
    required this.selectedValue,
    required this.onChanged,
    this.isLoading = false, // 기본값 false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: Colors.grey.shade700,
          ),
          elevation: 2,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontFamily:
                Theme.of(context).textTheme.bodyLarge?.fontFamily, // 테마 폰트 사용
          ),
          dropdownColor: Colors.white,
          items:
              mapTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
          // 로딩 중이거나 콜백이 null이면 비활성화
          onChanged: isLoading ? null : onChanged,
        ),
      ),
    );
  }
}
