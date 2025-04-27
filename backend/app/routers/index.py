from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Dict, Any, Optional
import asyncio
import traceback
import logging
import time

from pydantic import ValidationError

from app.schemas.request_models import IndexRequestParams
from app.schemas.response_models import (
    HealthIndexResponse,
    RegionInfo,
    IndexCalculationResult,
)

from utils.helpers import get_region
from core.indexing.calculator import (
    calculate_apparent_temp_ali,
    calculate_stroke_index,
    calculate_cold_index,
    get_food_poisoning_risk_for_region,
)
from core.indexing.get_data import fetch_weather_data

from app.cache import get_food_poisoning_cache

from config.settings import settings

# 로깅 설정
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")


def get_index_request_params(
    latitude: float,
    longitude: float,
    age: Optional[int] = None,
    disease: Optional[List[str]] = Query(None),
) -> IndexRequestParams:
    try:
        return IndexRequestParams(
            latitude=latitude, longitude=longitude, age=age, disease=disease or []
        )
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())


@router.get("/index", response_model=HealthIndexResponse)
async def get_indices(params: IndexRequestParams = Depends(get_index_request_params)):
    """
    건강 지수 API: 날씨 및 건강 관련 지수를 계산하여 반환합니다.
    """
    start_time = time.time()
    logger.info(f"Index API request received: {params}")

    errors = []

    # 사용자 입력 데이터 준비
    user_data_for_calc = {"age": params.age, "disease": params.disease}

    # 1. 지역 정보 조회
    try:
        gu, region_name = await get_region(params.latitude, params.longitude)
        region_info = RegionInfo(gu=gu, region=region_name)
        if not gu:
            errors.append("지역 정보 조회 실패 (gu 없음)")
            logger.warning(
                f"Region lookup failed for lat={params.latitude}, lon={params.longitude}"
            )
    except Exception as e:
        logger.exception(f"Error getting region info: {e}")
        errors.append(f"지역 정보 조회 오류: {e}")
        region_info = RegionInfo()

    # 2. 날씨 정보 조회
    weather_data = None
    try:
        weather_data = await fetch_weather_data(params.latitude, params.longitude)
    except Exception as e:
        logger.exception(f"Unexpected error fetching weather data: {e}")
        errors.append(f"날씨 정보 조회 중 예상 못한 오류: {e}")

    # 3. 식중독 정보 조회
    food_poisoning_data = None
    try:
        poison_cache = await asyncio.to_thread(
            get_food_poisoning_cache
        )  # 캐시 비동기 호출
        food_poisoning_data = poison_cache.get("data", {})
        if not food_poisoning_data:
            logger.warning("Food poisoning cache is empty.")
            errors.append("식중독 정보 없음 (캐시 비어 있음)")
    except Exception as e:
        logger.exception(f"Error fetching food poisoning cache: {e}")
        errors.append(f"식중독 정보 조회 실패: {e}")

    # 4. 지수 계산 (날씨 데이터가 있을 때만 수행)
    index_results = IndexCalculationResult()  # 빈 결과 객체로 시작
    if weather_data:
        try:
            # 체감 온도 및 ALI 계산
            apparent_temp_ali_res = calculate_apparent_temp_ali(
                weather_data["main"], user_data_for_calc
            )
            index_results.apparent_temperature = apparent_temp_ali_res.get(
                "apparent_temperature"
            )
            index_results.apparent_temp_risk_status = apparent_temp_ali_res.get(
                "risk_status"
            )
            index_results.ali_score = apparent_temp_ali_res.get("ali_score")
            index_results.ali_level = apparent_temp_ali_res.get("ali_level")

            # 뇌졸증 지수 계산
            stroke_res = calculate_stroke_index(weather_data["main"])
            index_results.stroke_index_score = stroke_res.get("stroke_index_score")
            index_results.stroke_index_level = stroke_res.get("stroke_index_level")

            # 감기 지수 계산
            cold_res = calculate_cold_index(weather_data["main"])
            index_results.cold_index_score = cold_res.get("cold_index_score")
            index_results.cold_index_level = cold_res.get("cold_index_level")

        except KeyError as e:
            logger.error(f"Missing expected key in weather data for calculation: {e}")
            errors.append(f"계산에 필요한 날씨 데이터 누락: {e}")
        except Exception as e:  # 예상 못한 오류
            logger.exception(f"Unexpected error during index calculation: {e}")
            errors.append(f"건강 지수 계산 중 예상 못한 오류: {e}")

    # 5. 식중독 지수 결과 통합
    if food_poisoning_data and region_info.gu:
        try:
            poison_info = get_food_poisoning_risk_for_region(
                food_poisoning_data, region_info.gu
            )
            if poison_info:
                index_results.food_poisoning_index = poison_info.get("poison_index")
                index_results.food_poisoning_risk = poison_info.get("poison_level")
            else:
                logger.info(
                    f"No food poisoning data found for region: {region_info.gu}"
                )
                index_results.food_poisoning_error = (
                    f"해당 지역({region_info.gu}) 식중독 정보 없음"
                )
        except Exception as e:
            logger.exception(f"Error processing food poisoning data: {e}")
            errors.append(f"식중독 정보 처리 오류: {e}")
            index_results.food_poisoning_error = f"식중독 정보 처리 오류: {e}"
    elif not region_info.gu and food_poisoning_data:
        errors.append("지역 확인 불가로 식중독 정보 조회 불가")
        index_results.food_poisoning_error = "지역 확인 불가"

    # 최종 응답 생성
    response = HealthIndexResponse(
        request=params.model_dump(),  # 요청 파라미터 포함
        region=region_info,
        indices=index_results,
        errors=errors if errors else None,  # 오류가 있을 때만 포함
    )

    elapsed_time = time.time() - start_time
    logger.info(f"Index API request processed in {elapsed_time:.2f}s")

    return response
