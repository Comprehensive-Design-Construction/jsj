from pydantic import BaseModel, Field
from typing import List, Optional, Any


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


class RiskIndex(BaseModel):
    discomfort_index: Optional[float] = None
    overall_risk_score: Optional[float] = None
    # 사용자 입력 정보를 반영한 요인
    factors_considered: Optional[dict] = (
        None  # 예: {"age": 65, "diseases": ["hypertension"]}
    )
    error: Optional[str] = None  # 계산 오류 시 메시지


class AlertInfo(BaseModel):
    type: str
    message: str


# --- Indexing 결과 모델 상세화 ---
class IndexingData(BaseModel):
    # 체감온도 및 관련 위험도
    apparent_temperature: Optional[float] = None
    apparent_temp_risk_status: Optional[str] = None  # 예: "주의", "경고", "위험"

    # 천식/폐질환 지수 (ALI)
    ali_score: Optional[float] = None
    ali_level: Optional[int] = None  # 예: 1(매우 높음) ~ 4(낮음)

    # 뇌졸증 지수 (TI)
    stroke_index_score: Optional[float] = None
    stroke_index_level: Optional[int] = None  # 예: 1(매우 높음) ~ 4(낮음)

    # 감기 가능 지수 (CI)
    cold_index_score: Optional[float] = None
    cold_index_level: Optional[int] = None  # 예: 1(매우 높음) ~ 4(낮음)

    # 식중독 지수 (사용자 지역구 기준)
    food_poisoning_score: Optional[float] = None
    food_poisoning_risk: Optional[str] = None  # 예: "관심", "주의", "경고", "위험"

    # 계산 오류 메시지
    error: Optional[str] = None


# --- API 응답 스키마 ---
class ApiResponse(BaseModel):
    request_info: dict
    weather: Optional[WeatherData] = None
    shelter_map_html: Optional[str] = None
    indexing_result: Optional[IndexingData] = None  # 상세화된 IndexingData 사용
    risk_assessment: Optional[RiskIndex] = (
        None  # RiskIndex는 사용자 전반적 위험도 (별도 정의 필요 시 수정)
    )
    alerts: List[AlertInfo] = []
    error: Optional[str] = None
