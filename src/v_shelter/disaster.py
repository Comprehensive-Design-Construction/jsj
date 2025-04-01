from typing import Dict, List, Optional
from enum import Enum, auto
from datetime import datetime
from shapely.geometry import Point


class DisasterType(Enum):
    """재난 유형 열거형"""

    COLD_WAVE = auto()
    HEAT_WAVE = auto()
    FINE_DUST = auto()
    FLOOD = auto()
    EARTHQUAKE = auto()


class DisasterLevel(Enum):
    """재난 심각도 수준 열거형"""

    NORMAL = auto()
    WATCH = auto()
    WARNING = auto()
    SEVERE = auto()


class Disaster:
    """재난 정보를 처리하는 클래스"""

    def __init__(self, type: DisasterType):
        """재난 객체를 초기화합니다.

        Args:
            type: 재난 유형
        """
        self.type = type
        self.level: DisasterLevel = DisasterLevel.NORMAL
        self.timestamp: datetime = datetime.now()
        self.region: Optional[str] = None
        self.details: Dict[str, str] = {}

    def update_level(self, level: DisasterLevel) -> None:
        """재난 경보 수준을 업데이트합니다.

        Args:
            level: 새로운 재난 경보 수준
        """
        self.level = level
        self.timestamp = datetime.now()

    def set_region(self, region: str) -> None:
        """재난 영향 지역을 설정합니다.

        Args:
            region: 지역명
        """
        self.region = region

    def add_detail(self, key: str, value: str) -> None:
        """재난 상세 정보를 추가합니다.

        Args:
            key: 정보 항목 이름
            value: 정보 항목 값
        """
        self.details[key] = value


class DisasterManager:
    """재난 정보 관리 클래스"""

    def __init__(self):
        """재난 관리자를 초기화합니다."""
        self.active_disasters: List[Disaster] = []

    def add_disaster(self, disaster: Disaster) -> None:
        """새로운 재난 정보를 추가합니다.

        Args:
            disaster: 재난 객체
        """
        self.active_disasters.append(disaster)

    def get_disasters_by_type(self, type: DisasterType) -> List[Disaster]:
        """특정 유형의 재난 정보만 필터링하여 반환합니다.

        Args:
            type: 재난 유형

        Returns:
            List[Disaster]: 해당 유형의 재난 객체 목록
        """
        return [d for d in self.active_disasters if d.type == type]

    def get_disasters_by_level(self, level: DisasterLevel) -> List[Disaster]:
        """특정 수준 이상의 재난 정보만 필터링하여 반환합니다.

        Args:
            level: 재난 경보 수준

        Returns:
            List[Disaster]: 해당 수준 이상의 재난 객체 목록
        """
        return [d for d in self.active_disasters if d.level.value >= level.value]

    def recommend_shelter_type(self) -> DisasterType:
        """현재 활성화된 재난 정보를 기반으로 대피소 유형을 추천합니다.

        Args:
            location_point: 사용자 위치

        Returns:
            DisasterType: 추천된 대피소 유형
        """
        # 현재 가장 심각한 재난 찾기
        if not self.active_disasters:
            return None

        # 심각도 순으로 정렬
        sorted_disasters = sorted(
            self.active_disasters, key=lambda d: d.level.value, reverse=True
        )

        # 가장 심각한 재난 유형 반환
        return sorted_disasters[0].type
