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
    food_poisoning_index: Optional[float] = None
    food_poisoning_risk: Optional[str] = None  # 예: "관심", "주의", "경고", "위험"

    # 계산 오류 메시지
    error: Optional[str] = None


# --- API 응답 스키마 ---
class IndicesApiResponse(BaseModel):
    """/api/indices 엔드포인트 응답 모델"""

    request_info: dict
    weather: Optional[WeatherData] = None
    indexing_result: Optional[IndexingData] = None
    alerts: List[AlertInfo] = []
    error: Optional[str] = None  # 지수 계산/크롤링 중 발생한 오류 요약


class MapApiResponse(BaseModel):
    """/api/map 엔드포인트 응답 모델"""

    request_info: dict
    shelter_map_html: Optional[str] = None
    error: Optional[str] = None  # 지도 생성 중 발생한 오류


class EnvMapApiResponse(BaseModel):
    """환경 관련 지도 API 응답 모델"""

    request_info: dict
    env_map_html: Optional[str] = None
    env_type: str  # 어떤 환경 지도인지 (fine_dust, uv)
    last_updated: Optional[str] = None  # 데이터 최종 업데이트 시간
    error: Optional[str] = None


class FineDustData(BaseModel):
    """미세먼지 데이터 모델"""

    region: str  # 지역명
    grade: Optional[str] = None  # 등급
    pm10: Optional[float] = None  # 미세먼지 농도
    pm25: Optional[float] = None  # 초미세먼지 농도
    max_index: Optional[float] = None  # 통합 대기 환경 지수


class UvData(BaseModel):
    """자외선 지수 데이터 모델"""

    region: str  # 지역명
    uv_index: Optional[int] = None  # 자외선 지수
    uv_grade: Optional[str] = None  # 자외선 등급
