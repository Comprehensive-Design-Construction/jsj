// lib/screens/loading_error/error_message.dart
import 'package:flutter/material.dart';

/// 에러 메시지와 재시도 버튼을 표시하는 위젯
class ErrorMessage extends StatelessWidget {
  final String message; // 표시할 에러 메시지
  final VoidCallback? onRetry; // 재시도 버튼 클릭 시 실행될 콜백 함수 (Optional)

  const ErrorMessage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ), // 에러 아이콘
            const SizedBox(height: 16),
            Text(
              message, // 전달받은 에러 메시지
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            // 재시도 콜백 함수가 제공된 경우에만 버튼 표시
            if (onRetry != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                onPressed: onRetry, // 재시도 함수 연결
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700, // 버튼 색상 조정
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
