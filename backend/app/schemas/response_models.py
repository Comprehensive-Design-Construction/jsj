from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, Union


class RegionInfo(BaseModel):
    """지역 정보"""

    gu: Optional[str] = None  # 구
    region: Optional[str] = None  # 동


class WeatherMainInfo(BaseModel):
    temp: Optional[float] = None
    feels_like: Optional[float] = None
    temp_min: Optional[float] = None
    temp_max: Optional[float] = None
    pressure: Optional[float] = None
    humidity: Optional[float] = None
    wind_speed: Optional[float] = None
    wind_deg: Optional[int] = None


class WeatherHourInfo(BaseModel):
    date: Optional[str] = None
    temp: Optional[float] = None
    pop: Optional[float] = None
    main: Optional[str] = None


class WeatherHourInfoList(BaseModel):
    hourly: Optional[List[WeatherHourInfo]] = None


class WeatherCondition(BaseModel):
    main: Optional[str] = None  # 예: Clouds, Rain
    description: Optional[str] = None  # 예: broken clouds
    icon: Optional[str] = None  # 예: 04d


class WeatherDetailResponse(BaseModel):
    """/api/weather 응답 모델"""

    request_location: Dict[str, float]  # 요청 좌표, RegionInfo 스키마 재활용 고려
    weather_condition: Optional[WeatherCondition] = None
    measurements: Optional[WeatherMainInfo] = None
    weather_hour_list: Optional[WeatherHourInfoList] = None
    timestamp: Optional[int] = None  # 데이터 시간 (Unix timestamp)
    timezone: Optional[int] = None  # 타임존 오프셋 (초)
    error: Optional[str] = None  # 오류 메시지


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


class RegionFineDustData(BaseModel):
    """자치구별 미세먼지 상세 정보"""

    GRADE: Optional[str] = None  # 예: "좋음"
    PM10: Optional[int] = None
    PM25: Optional[int] = None
    MAXINDEX: Optional[str] = None  # 예: 통합대기환경지수 등급


class RegionUvData(BaseModel):
    """자치구별 UV 지수 정보"""

    uv_index: Optional[int] = None  # h0 값


class SingleRegionFineDustResponse(BaseModel):
    """/api/environment/fine_dust 응답 모델 (단일 지역)"""

    request_location: Dict[str, float]  # 요청 좌표
    region_info: RegionInfo  # 조회된 지역 정보
    fine_dust_data: Optional[RegionFineDustData] = None  # 해당 지역의 미세먼지 데이터
    last_updated: Optional[str] = None  # 데이터 최종 업데이트 시간 (ISO 형식)
    error: Optional[str] = None


class SingleRegionUvResponse(BaseModel):
    """/api/environment/uv 응답 모델 (단일 지역)"""

    request_location: Dict[str, float]  # 요청 좌표
    region_info: RegionInfo  # 조회된 지역 정보
    uv_data: Optional[RegionUvData] = None  # 해당 지역의 UV 데이터
    last_updated: Optional[str] = None  # 데이터 최종 업데이트 시간 (ISO 형식)
    error: Optional[str] = None


class DistrictsResponse(BaseModel):
    """
    /api/districts 응답 모델
    """

    districts: List[str]
    # error: Optional[str] = None


class DongsResponse(BaseModel):
    """
    /api/dongs 응답 모델
    """

    dongs: List[str]
    # error: Optional[str] = None


class CoordinatesReponse(BaseModel):
    latitude: float
    longitude: float
    # error: Optional[str] = None


class RecommendationResponse(BaseModel):
    recommendation: str = Field(..., description="생성된 행동 요령 텍스트")
    error: Optional[str] = None  # 오류 발생 시 메시지 전달용
