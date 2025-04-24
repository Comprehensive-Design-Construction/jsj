from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, Union


class RegionInfo(BaseModel):
    """지역 정보"""

    gu: Optional[str] = None  # 구
    region: Optional[str] = None  # 동


class WeatherData(BaseModel):
    temperature: Optional[float] = None
    pressure: Optional[float] = None
    humidity: Optional[float] = None
    wind_speed: Optional[float] = None
    temp_min: Optional[float] = None
    temp_max: Optional[float] = None
    description: Optional[str] = None
    city: Optional[str] = None
    error: Optional[str] = None  # API 오류 시 메시지


class IndexCalculationResult(BaseModel):
    """건강 지수 계산 결과 상세"""

    apparent_temperature: Optional[float] = None
    apparent_temp_risk_status: Optional[str] = None  # 체감 온도 위험도
    ali_score: Optional[float] = None
    ali_level: Optional[int] = None  # 천식/폐질환 지수 등급 (1~4)
    stroke_index_score: Optional[float] = None
    stroke_index_level: Optional[int] = None  # 뇌졸증 지수 등급 (1~4)
    cold_index_score: Optional[float] = None
    cold_index_level: Optional[int] = None  # 감기 지수 등급 (1~4)
    food_poisoning_index: Optional[str] = None
    food_poisoning_risk: Optional[str] = None  # 식중독 위험도 ('관심', '주의' 등)
    food_poisoning_error: Optional[str] = None  # 식중독 정보 조회 오류 시 메시지


class HealthIndexResponse(BaseModel):
    """/api/index 최종 응답 모델"""

    request: Dict[str, Any]  # 요청 파라미터 정보 그대로 포함
    region: RegionInfo  # 지역 정보
    indices: IndexCalculationResult  # 계산된 지수 결과
    errors: Optional[List[str]] = None  # 처리 중 발생한 오류 목록


class MapApiResponse(BaseModel):
    request_info: Dict[str, Any]  # 요청 정보
    shelter_map_html: Optional[str] = None  # 지도 HTML
    error: Optional[str] = None


class EnvMapApiResponse(BaseModel):
    request_info: Dict[str, Any]
    env_map_html: Optional[str] = None
    env_type: str
    last_updated: Optional[str] = None
    error: Optional[str] = None
