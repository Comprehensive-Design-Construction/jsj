// lib/features/dashboard/presentation/widgets/weather_avatar.dart
import 'package:flutter/material.dart';
import '../../../../models/weather_data.dart'; // WeatherCondition 모델 import

class WeatherAvatar extends StatelessWidget {
  final WeatherCondition? condition;
  final double size;

  const WeatherAvatar({super.key, this.condition, this.size = 80.0});

  String _getAvatarAssetPath(String? mainCondition) {
    // 날씨 상태(main) 값에 따라 다른 이미지 경로 반환 (예시)
    // 백엔드에서 제공하는 main 값 확인 필요 ('Clear', 'Clouds', 'Rain' 등)
    switch (mainCondition?.toLowerCase()) {
      case 'clear':
        return 'assets/images/avatar_sunny.png'; // 맑음 아바타
      case 'clouds':
        return 'assets/images/avatar_cloudy.png'; // 구름 아바타
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return 'assets/images/avatar_rainy.png'; // 비 아바타
      case 'snow':
        return 'assets/images/avatar_snowy.png'; // 눈 아바타
      // TODO: 다른 날씨 상태에 대한 아바타 추가 (안개, 연기 등)
      default:
        return 'assets/images/avatar_default.png'; // 기본 아바타
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _getAvatarAssetPath(condition?.main);
    // TODO: 실제 에셋 이미지 로딩 처리 (Image.asset)
    // return Image.asset(imagePath, width: size, height: size, fit: BoxFit.contain);

    // 임시 플레이스홀더
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, size: size * 0.6), // 기본 아이콘
      // backgroundImage: AssetImage(imagePath), // 실제 이미지 로딩
    );
  }
}
