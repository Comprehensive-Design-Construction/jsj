import 'package:flutter/material.dart';

/// 레이블과 DropdownButtonFormField를 포함하는 공용 위젯
class LabeledDropdownFormField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isRequired;
  final bool isLoading;
  final String? errorText; // <<< 오류 메시지 파라미터 추가
  final bool isExpanded;

  const LabeledDropdownFormField({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.isLoading = false,
    this.errorText, // <<< 추가
    this.isExpanded = true,
  });

  // 기본 InputDecoration (기존과 동일)
  static InputDecoration get defaultInputDecoration => InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
  );

  @override
  Widget build(BuildContext context) {
    // 에러 상태일 때 테두리 색상 변경 등을 위한 InputDecoration 수정
    final effectiveDecoration = defaultInputDecoration.copyWith(
      // 에러 텍스트가 있으면 에러 상태 스타일 적용 (예: 테두리 색상 변경)
      enabledBorder:
          errorText != null
              ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.redAccent.shade100),
              )
              : defaultInputDecoration.enabledBorder,
      // 힌트 텍스트: 로딩 > 에러 > 기본 힌트 순으로 표시
      hintText: isLoading ? '불러오는 중...' : (errorText ?? hintText),
      hintStyle: TextStyle(
        color:
            errorText != null
                ? Colors.redAccent.shade200
                : Colors.grey[500], // 에러 시 힌트 색상 변경
        fontSize: 14,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블 텍스트 (기존과 동일)
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
        // 드롭다운 폼 필드
        DropdownButtonFormField<T>(
          value: value,
          // hint는 decoration에서 처리하므로 제거
          // hint: Text(isLoading ? '불러오는 중...' : (errorText ?? hintText)),
          isExpanded: isExpanded,
          decoration: effectiveDecoration, // 수정된 데코레이션 적용
          items:
              (isLoading || errorText != null)
                  ? []
                  : items, // 로딩 중 또는 에러 시 아이템 비우기
          onChanged:
              (isLoading || errorText != null)
                  ? null
                  : onChanged, // 로딩 중 또는 에러 시 비활성화
          validator: validator,
          style: TextStyle(fontSize: 15, color: Colors.black87),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[700]),
          dropdownColor: Colors.white,
        ),
        // 필드 아래에 직접 에러 메시지 표시 (선택적) - FormField의 validator가 처리하는 것과 중복될 수 있음
        // if (errorText != null) ...[
        //   const SizedBox(height: 4),
        //   Padding(
        //     padding: const EdgeInsets.only(left: 12.0),
        //     child: Text(errorText!, style: TextStyle(color: Colors.redAccent.shade700, fontSize: 12)),
        //   ),
        // ]
      ],
    );
  }
}
