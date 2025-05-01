// lib/features/dashboard/presentation/widgets/health_index_card.dart
import 'package:flutter/material.dart';

class HealthIndexCard extends StatelessWidget {
  final String title; // 예: "체감 온도", "미세먼지"
  final String? displayValue; // 예: "30.5 °C", "보통", "5" (값 + 단위 또는 상태 문자열)
  final int? riskLevel; // 예: 1(위험/매우높음) ~ 4(낮음/관심) 또는 5(안전)
  final String? riskLevelString; // 예: "경고", "주의" (level과 둘 중 하나 또는 둘 다 사용)
  final String? pictureKey; // 예: "apparent_temp", "fine_dust" (이미지 에셋 매핑용)
  final bool isHighestRisk; // 이 카드가 가장 위험한 지수인지 여부

  const HealthIndexCard({
    super.key,
    required this.title,
    this.displayValue,
    this.riskLevel,
    this.riskLevelString,
    this.pictureKey,
    this.isHighestRisk = false, // 기본값은 false
  });

  // 위험 레벨에 따라 색상 반환 (예시)
  Color _getLevelColor(int? level) {
    switch (level) {
      case 1:
        return Colors.red.shade300; // 위험/매우높음
      case 2:
        return Colors.orange.shade300; // 경고/높음
      case 3:
        return Colors.yellow.shade300; // 주의/보통
      case 4:
        return Colors.blue.shade200; // 관심/낮음
      default:
        return Colors.grey.shade300; // 안전 또는 알 수 없음
    }
    // TODO: riskLevelString 기준으로 색상 매핑도 가능
  }

  // 사진 키에 따라 이미지 에셋 경로 반환 (예시)
  String _getPictureAssetPath(String? key) {
    // TODO: pictureKey 값에 따라 이미지 경로 반환 로직 구현
    return 'assets/images/index_placeholder.png'; // 임시 플레이스홀더
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(riskLevel);
    final picturePath = _getPictureAssetPath(pictureKey);

    return Card(
      elevation: isHighestRisk ? 4.0 : 1.0, // 가장 위험한 지수 카드 강조
      shape: RoundedRectangleBorder(
        side:
            isHighestRisk
                ? BorderSide(color: Colors.redAccent, width: 2.0) // 강조 테두리
                : BorderSide.none,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 지수 이미지 (에셋 기반)
            Image.asset(
              picturePath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            // TODO: 실제 이미지 로딩
            // CircleAvatar(
            //   radius: 20,
            //   backgroundColor: Colors.grey[200],
            //   backgroundImage: AssetImage(picturePath),
            // ),
            const SizedBox(width: 12),
            // 지수 정보 (이름, 값)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    displayValue ?? 'N/A', // 현재 값 표시
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 위험 등급 표시
            if (riskLevelString != null || riskLevel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskLevelString ?? 'Level $riskLevel', // 문자열 우선 표시
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
