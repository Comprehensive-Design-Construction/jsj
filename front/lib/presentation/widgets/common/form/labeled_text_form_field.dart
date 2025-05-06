import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 레이블과 TextFormField를 포함하는 공용 위젯
class LabeledTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired; // 필수 필드 여부 (레이블에 '*' 표시)
  final int? maxLines;

  const LabeledTextFormField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.isRequired = false,
    this.maxLines = 1, // 기본 한 줄
  });

  // 공용 InputDecoration 정의
  static InputDecoration get defaultInputDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      // 테두리 색상 등 추가 가능
      // borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      // 활성화 시 테두리
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      // 포커스 시 테두리
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14), // 힌트 스타일
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블 텍스트
        Text.rich(
          // '*' 표시를 위해 Text.rich 사용
          TextSpan(
            text: label,
            style: Theme.of(context).textTheme.titleSmall, // 테마 스타일 사용
            children:
                isRequired
                    ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ] // 필수 표시
                    : [],
          ),
        ),
        const SizedBox(height: 8), // 레이블과 필드 사이 간격
        // 텍스트 폼 필드
        TextFormField(
          controller: controller,
          decoration: defaultInputDecoration.copyWith(
            // 기본 데코레이션 사용 및 일부 수정
            hintText: hintText,
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15), // 입력 텍스트 스타일
        ),
      ],
    );
  }
}
