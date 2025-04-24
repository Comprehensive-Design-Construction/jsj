from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List, Dict, Any, Tuple
import asyncio
import traceback
import logging

from pydantic import ValidationError

from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from utils.helpers import get_region
from core.indexing.calculator import (
    calculate_apparent_temp_ali,
    calculate_stroke_index,
    calculate_cold_index,
    get_food_poisoning_risk_for_region,
)
from core.indexing.get_data import _fetch_weather_data
from app.cache import get_food_poisoning_cache

from config.settings import settings

# 로깅 설정
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")


async def fetch_weather_and_pressure_data(lat: float, lon: float) -> Dict[str, Any]:
    """날씨 및 기압 데이터를 비동기로 가져오는 함수

    Args:
        lat: 위도
        lon: 경도

    Returns:
        Dict[str, Any]: 날씨 및 기압 데이터 또는 에러 정보
    """
    try:
        logger.info(f"Fetching weather data for location: {lat}, {lon}")
        return await _fetch_weather_data(lat, lon)
    except Exception as e:
        error_message = f"Error fetching weather data: {str(e)}"
        logger.error(error_message)
        traceback.print_exc()
        return {"error": error_message}


def calculate_health_indices(
    weather_data: Dict[str, Any], user_data: Dict[str, Any]
) -> Tuple[Dict[str, Any], List[str]]:
    """날씨 데이터를 기반으로 건강 지수 계산

    Args:
        weather_data: 날씨 데이터
        user_data: 사용자 입력 데이터

    Returns:
        Dict[str, Any]: 계산된 지수 결과
    """
    indices = {}
    error_parts = []

    try:
        # 체감 온도 및 ALI 지수 계산
        apparent_temp_ali_res = calculate_apparent_temp_ali(
            weather_data["main"], user_data
        )
        indices.update(apparent_temp_ali_res)
        if apparent_temp_ali_res.get("error"):
            error_parts.append("체감 온도/ALI 계산 실패")

        # 열사병 지수 계산
        stroke_res = calculate_stroke_index(weather_data["main"])
        indices.update(stroke_res)
        if stroke_res.get("error"):
            error_parts.append("열사병 지수 계산 실패")

        # 감기 지수 계산
        cold_res = calculate_cold_index(weather_data["main"])
        indices.update(cold_res)
        if cold_res.get("error"):
            error_parts.append("감기 지수 계산 실패")

    except Exception as e:
        logger.error(f"Error calculating health indices: {e}")
        indices["error"] = f"건강 지수 계산 실패: {str(e)}"
        error_parts.append("건강 지수 계산 중 예외 발생")

    return indices, error_parts


@router.get("/index")
async def get_indices(
    latitude: float,
    longitude: float,
    age: Optional[int] = None,
    disease: Optional[List[str]] = Query(None),
):
    """
    건강 지수 API:
      - 날씨 및 건강 관련 지수(감기, 식중독 등)를 계산하여 반환합니다.

    파라미터:
      - **latitude**: 위도 좌표
      - **longitude**: 경도 좌표
      - **age**: 사용자 나이 (선택)
      - **disease**: 사용자 질병 정보 (선택, 복수 가능)
    """
    try:
        logger.info(f"Index API request: lat={latitude}, lon={longitude}, age={age}")

        # 사용자 입력 데이터 준비
        user_data = {"age": age, "disease": disease or []}

        # 사용자 지역 조회
        gu, region = await get_region(latitude, longitude)

        # 비동기 작업: 날씨 스크래핑 및 식중독 캐시 조회 병렬 처리
        try:
            logger.info(
                "Starting async tasks: Weather scraping and Food poisoning cache lookup"
            )

            # 비동기 작업 생성
            weather_task = asyncio.create_task(
                fetch_weather_and_pressure_data(latitude, longitude)
            )
            poison_cache_task = asyncio.to_thread(get_food_poisoning_cache)

            # 병렬 처리
            weather_result, cached_poison_data = await asyncio.gather(
                weather_task, poison_cache_task, return_exceptions=True
            )

            # 날씨 데이터 처리 및 건강 지수 계산
            calculated_indices = {}
            overall_error_parts = []

            # 날씨 데이터 처리
            if isinstance(weather_result, Exception) or (
                isinstance(weather_result, dict) and weather_result.get("error")
            ):
                error_msg = (
                    weather_result.get("error")
                    if isinstance(weather_result, dict)
                    else str(weather_result)
                )
                logger.error(f"Error fetching weather data: {error_msg}")
                calculated_indices["error"] = f"날씨/기압 정보 조회 실패: {error_msg}"
                overall_error_parts.append("날씨 데이터 조회 실패")
            elif isinstance(weather_result, dict):
                # 날씨 기반 지수 계산
                logger.info("Calculating indices based on weather data...")
                indices, error_parts = calculate_health_indices(
                    weather_result, user_data
                )
                calculated_indices.update(indices)
                overall_error_parts.extend(error_parts)
            else:
                calculated_indices["error"] = "날씨/기압 정보를 가져오지 못했습니다."
                overall_error_parts.append("날씨 데이터 조회 결과 형식 오류")

            # 식중독 데이터 처리
            food_poisoning_data = {}
            if isinstance(cached_poison_data, Exception):
                logger.error(
                    f"Error fetching food poisoning cache: {cached_poison_data}"
                )
                calculated_indices["food_poisoning_error"] = (
                    f"식중독 정보 조회 실패: {str(cached_poison_data)}"
                )
                overall_error_parts.append("식중독 캐시 조회 실패")
            else:
                food_poisoning_data = cached_poison_data.get("data", {})
                cache_last_updated = cached_poison_data.get("last_updated")
                logger.info(
                    f"Retrieved food poisoning data (Last updated: {cache_last_updated})"
                )

                if not food_poisoning_data:
                    logger.warning("Food poisoning cache is empty.")
                    calculated_indices["food_poisoning_error"] = (
                        "식중독 정보 없음 (캐시 비어 있음)"
                    )
                    overall_error_parts.append("식중독 캐시 비어 있음")
                elif gu:
                    poison_info = get_food_poisoning_risk_for_region(
                        food_poisoning_data, gu
                    )
                    if poison_info:
                        calculated_indices["food_poisoning_index"] = poison_info.get(
                            "poison_index"
                        )
                        calculated_indices["food_poisoning_risk"] = poison_info.get(
                            "poison_level"
                        )
                    else:
                        logger.warning(f"No food poisoning data for region: {gu}")
                        calculated_indices["food_poisoning_error"] = (
                            f"해당 지역({gu})의 식중독 정보 없음"
                        )
                        overall_error_parts.append(f"지역({gu}) 식중독 정보 없음")
                else:
                    logger.warning(
                        f"Region (gu) not determined for coords: {latitude}, {longitude}"
                    )
                    calculated_indices["food_poisoning_error"] = (
                        "지역 확인 불가, 식중독 정보 조회 실패"
                    )
                    overall_error_parts.append("지역 확인 불가")

            # 응답 생성
            response = {
                "request": {
                    "latitude": latitude,
                    "longitude": longitude,
                    "age": age,
                    "disease": disease or [],
                },
                "region": {"gu": gu, "region": region},
                "indices": calculated_indices,
            }

            if overall_error_parts:
                response["errors"] = overall_error_parts

            return response
        except Exception as e:
            logger.error(f"Error processing request: {e}")
            traceback.print_exc()
            raise HTTPException(
                status_code=500,
                detail={"error": "Internal server error", "message": str(e)},
            )

    except Exception as e:
        logger.error(f"Unhandled error in get_indices: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail={"error": "Internal server error", "message": str(e)},
        )
