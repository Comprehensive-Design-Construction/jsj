from fastapi import APIRouter, Depends, HTTPException
from pydantic import ValidationError
from typing import Dict, Any
import logging
import traceback
import time

from app.schemas.request_models import LocationInput
from app.schemas.response_models import (
    WeatherDetailResponse,
    WeatherCondition,
    WeatherMainInfo,
)
from core.indexing.get_data import fetch_weather_data

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api")


def get_location_params(latitude: float, longitude: float) -> LocationInput:
    try:
        return LocationInput(latitude=latitude, longitude=longitude)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())


@router.get("/weather", response_model=WeatherDetailResponse)
async def get_detailed_weather(location: LocationInput = Depends(get_location_params)):
    """
    지정된 위도/경도의 상세 날씨 정보를 반환합니다.
    """
    start_time = time.time()
    logger.info(f"Weather API request received: {location}")

    request_location_dict = location.model_dump()
    weather_condition = None
    measurements = None
    timestamp = None
    timezone = None
    error_msg = None

    try:
        # 핵심 로직 호출
        weather_data = await fetch_weather_data(location.latitude, location.longitude)

        # 응답 모델에 맞게 데이터 구성
        if weather_data:
            weather_cond_data = weather_data.get("weather", {})
            measurements_data = weather_data.get("main", {})
            weather_condition = (
                WeatherCondition(**weather_cond_data) if weather_cond_data else None
            )
            measurements = (
                WeatherMainInfo(**measurements_data) if measurements_data else None
            )
            timestamp = weather_data.get("timestamp")
            timezone = weather_data.get("timezone")
        else:
            error_msg = "날씨 데이터를 가져오지 못했습니다."
            logger.warning(error_msg)

    except Exception as e:
        logger.exception(f"Unexpected error fetching weather data for {location}: {e}")
        error_msg = f"날씨 정보 조회 중 예상 못한 오류 발생: {e}"

    elapsed_time = time.time() - start_time
    logger.info(f"Weather API request processed in {elapsed_time:.2f}s")

    # 최종 응답 반환 (response_model 사용)
    return WeatherDetailResponse(
        request_location=request_location_dict,
        weather_condition=weather_condition,
        measurements=measurements,
        timestamp=timestamp,
        timezone=timezone,
        error=error_msg,
    )
