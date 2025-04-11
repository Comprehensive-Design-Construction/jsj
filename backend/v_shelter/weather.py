import random
from datetime import datetime
from typing import Dict, Any, Tuple


class WeatherData:
    """날씨 데이터를 시뮬레이션하는 클래스"""

    def __init__(self):
        """날씨 데이터 객체를 초기화합니다."""
        self.temperature = 0.0
        self.humidity = 0.0
        self.fine_dust = 0
        self.precipitation = 0.0
        self.wind_speed = 0.0

    def simulate_current_weather(self) -> Dict[str, Any]:
        """현재 날씨 데이터를 시뮬레이션합니다.

        Returns:
            Dict[str, Any]: 시뮬레이션된 날씨 데이터
        """
        # 계절에 따른 기온 범위 조정
        month = datetime.now().month
        if 3 <= month <= 5:  # 봄
            temp_range = (10, 25)
        elif 6 <= month <= 8:  # 여름
            temp_range = (25, 38)
        elif 9 <= month <= 11:  # 가을
            temp_range = (10, 25)
        else:  # 겨울
            temp_range = (-10, 5)

        self.temperature = random.uniform(*temp_range)
        self.humidity = random.uniform(30, 90)
        self.fine_dust = random.randint(150, 200)
        self.precipitation = random.uniform(0, 50) if random.random() < 0.3 else 0
        self.wind_speed = random.uniform(0, 20)

        return {
            "temperature": self.temperature,
            "humidity": self.humidity,
            "fine_dust": self.fine_dust,
            "precipitation": self.precipitation,
            "wind_speed": self.wind_speed,
            "timestamp": datetime.now().isoformat(),
        }

    def check_disaster_conditions(self) -> Tuple[bool, str, Dict[str, Any]]:
        """현재 날씨가 재난 조건에 해당하는지 확인합니다.

        Returns:
            Tuple[bool, str, Dict[str, Any]]:
                - 재난 조건 충족 여부
                - 재난 유형
                - 재난 상세 정보
        """
        if self.temperature > 35:
            return (
                True,
                "HEAT_WAVE",
                {
                    "level": "WARNING" if self.temperature > 37 else "WATCH",
                    "details": f"폭염주의보: 현재 기온 {self.temperature:.1f}°C",
                },
            )
        elif self.temperature < -12:
            return (
                True,
                "COLD_WAVE",
                {
                    "level": "WARNING" if self.temperature < -15 else "WATCH",
                    "details": f"한파주의보: 현재 기온 {self.temperature:.1f}°C",
                },
            )
        elif self.fine_dust > 150:
            return (
                True,
                "FINE_DUST",
                {
                    "level": "WARNING" if self.fine_dust > 180 else "WATCH",
                    "details": f"미세먼지 경보: 현재 농도 {self.fine_dust}µg/m³",
                },
            )
        elif self.precipitation > 30:
            return (
                True,
                "FLOOD",
                {
                    "level": "WARNING" if self.precipitation > 40 else "WATCH",
                    "details": f"집중호우 경보: 현재 강수량 {self.precipitation:.1f}mm/h",
                },
            )
        else:
            return False, "NORMAL", {"level": "NORMAL", "details": "정상 기상 상태"}
