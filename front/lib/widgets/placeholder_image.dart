// lib/widgets/placeholder_image.dart
import 'package:flutter/material.dart';

/// 지정된 경로의 에셋 이미지를 표시하거나, 없을 경우 기본 아이콘을 보여주는 위젯
class PlaceholderImage extends StatelessWidget {
  final String? imagePath; // 에셋 이미지 경로 (예: 'assets/images/icon.png')
  final double size; // 이미지/아이콘 크기

  const PlaceholderImage({super.key, this.imagePath, this.size = 24});

  @override
  Widget build(BuildContext context) {
    // 이미지 경로가 유효하면 에셋 이미지 로드 시도
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain, // 이미지 비율 유지하며 채우기
        // 이미지 로드 실패 시 대체 위젯 표시
        errorBuilder: (context, error, stackTrace) {
          print("Placeholder 이미지 로드 오류: $imagePath, 오류: $error");
          // 실패 시 기본 아이콘 표시
          return Icon(
            Icons.image_not_supported_outlined,
            size: size,
            color: Colors.grey,
          );
        },
      );
    } else {
      // 이미지 경로가 없으면 기본 도움말 아이콘 표시
      return Icon(Icons.help_outline, size: size, color: Colors.grey);
    }
  }
}
