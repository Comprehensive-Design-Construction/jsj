# app/routers/index.py
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Dict, Any, Optional, Tuple
import asyncio
import traceback
import logging
import time

from pydantic import ValidationError

# --- 모델 및 설정 임포트 ---
from app.schemas.request_models import IndexRequestParams
from app.schemas.response_models import (
    HealthIndexResponse,
    RegionInfo,
    IndexCalculationResult,
)
from utils.helpers import get_region  # 주의: get_region 구현 확인 필요
from core.indexing.calculator import (
    calculate_apparent_temp_ali,
    calculate_stroke_index,
    calculate_cold_index,
    get_food_poisoning_risk_for_region,
)
from core.indexing.get_data import fetch_weather_data  # 수정된 fetch_weather_data 사용
from app.cache import get_food_poisoning_cache
from config.settings import settings

# 로깅 설정
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")


# --- 의존성 주입 함수 (기존과 동일) ---
def get_index_request_params(
    latitude: float,
    longitude: float,
    age: Optional[int] = None,
    user_type: Optional[List[str]] = Query(None),
    disease: Optional[List[str]] = Query(None),
) -> IndexRequestParams:
    try:
        return IndexRequestParams(
            latitude=latitude,
            longitude=longitude,
            age=age,
            user_type=user_type or [],
            disease=disease or [],
        )
    except ValidationError as e:
        # FastAPI가 자동으로 422 응답 처리하지만, 명시적으로 남겨둘 수 있음
        raise HTTPException(status_code=422, detail=e.errors())


# --- 헬퍼 함수들 ---


async def _fetch_initial_data(latitude: float, longitude: float) -> tuple:
    """지역, 날씨, 식중독 캐시 데이터를 병렬로 조회합니다."""
    logger.info("Starting parallel fetch for initial data...")
    start_fetch = time.time()
    try:
        # --- 중요: get_region이 동기 함수라고 가정하고 to_thread 사용 ---
        region_task = asyncio.create_task(get_region(latitude, longitude))
        # ----------------------------------------------------------
        weather_task = asyncio.create_task(fetch_weather_data(latitude, longitude))
        poison_cache_task = asyncio.create_task(
            asyncio.to_thread(get_food_poisoning_cache)
        )

        results = await asyncio.gather(
            region_task,
            weather_task,
            poison_cache_task,
            return_exceptions=True,  # 개별 작업 오류 시 None 대신 예외 반환받기
        )
        fetch_duration = time.time() - start_fetch
        logger.info(f"Finished parallel fetch in {fetch_duration:.4f}s")

        # 결과 처리 및 오류 확인
        region_result = results[0] if not isinstance(results[0], Exception) else None
        weather_data = results[1] if not isinstance(results[1], Exception) else None
        poison_cache = results[2] if not isinstance(results[2], Exception) else None

        errors = []
        if isinstance(results[0], Exception):
            logger.error(f"Error in get_region task: {results[0]}")
            errors.append(f"지역 정보 조회 오류: {results[0]}")
        if isinstance(results[1], Exception):
            logger.error(f"Error in fetch_weather_data task: {results[1]}")
            errors.append(f"날씨 정보 조회 오류: {results[1]}")
        if isinstance(results[2], Exception):
            logger.error(f"Error in get_food_poisoning_cache task: {results[2]}")
            errors.append(f"식중독 정보 조회 오류: {results[2]}")

        return region_result, weather_data, poison_cache, errors

    except Exception as e:
        # gather 자체에서 예상 못한 오류 발생 시 (거의 없음)
        logger.exception(f"Unexpected error during concurrent data fetching: {e}")
        return None, None, None, [f"데이터 조회 중 시스템 오류: {e}"]


async def _calculate_health_indices(
    weather_data: Dict[str, Any],  # Optional 제거 (호출 전에 None 체크)
    user_data_for_calc: Dict[str, Any],
) -> Tuple[Dict, List[str]]:
    """건강 지수들을 병렬로 계산합니다."""
    logger.info("Starting parallel calculation for health indices...")
    start_calc = time.time()
    calc_errors = []
    calculation_results = {}

    try:
        # 계산 함수들을 스레드에서 실행하도록 태스크 생성
        calc_tasks = [
            asyncio.to_thread(
                calculate_apparent_temp_ali, weather_data["main"], user_data_for_calc
            ),
            asyncio.to_thread(calculate_stroke_index, weather_data["main"]),
            asyncio.to_thread(calculate_cold_index, weather_data["main"]),
        ]
        # 병렬 실행 및 결과 취합
        results_list = await asyncio.gather(*calc_tasks, return_exceptions=True)
        calc_duration = time.time() - start_calc
        logger.info(f"Finished parallel calculations in {calc_duration:.4f}s")

        # 결과 처리 및 오류 확인
        apparent_temp_ali_res = (
            results_list[0] if not isinstance(results_list[0], Exception) else None
        )
        stroke_res = (
            results_list[1] if not isinstance(results_list[1], Exception) else None
        )
        cold_res = (
            results_list[2] if not isinstance(results_list[2], Exception) else None
        )

        if isinstance(results_list[0], Exception):
            logger.error(
                f"Error in calculate_apparent_temp_ali task: {results_list[0]}"
            )
            calc_errors.append(f"체감온도/ALI 계산 오류: {results_list[0]}")
        if isinstance(results_list[1], Exception):
            logger.error(f"Error in calculate_stroke_index task: {results_list[1]}")
            calc_errors.append(f"뇌졸중 지수 계산 오류: {results_list[1]}")
        if isinstance(results_list[2], Exception):
            logger.error(f"Error in calculate_cold_index task: {results_list[2]}")
            calc_errors.append(f"감기 지수 계산 오류: {results_list[2]}")

        # 성공한 결과만 취합
        if apparent_temp_ali_res:
            calculation_results.update(apparent_temp_ali_res)
        if stroke_res:
            calculation_results.update(stroke_res)
        if cold_res:
            calculation_results.update(cold_res)

        # 계산 중 발생한 내부 오류(예: calculator 내부의 error 필드)는 별도 처리 가능
        for res_dict in [apparent_temp_ali_res, stroke_res, cold_res]:
            if res_dict and res_dict.get("error"):
                logger.warning(f"Internal calculation warning: {res_dict.get('error')}")
                # calc_errors.append(f"계산 내부 경고: {res_dict.get('error')}") # 필요 시 추가

    except Exception as e:
        logger.exception(f"Unexpected error during parallel calculations: {e}")
        calc_errors.append(f"지수 계산 중 시스템 오류: {e}")

    return calculation_results, calc_errors


def _integrate_poison_data(
    index_results: IndexCalculationResult,  # 수정 대상 객체
    food_poisoning_data: Optional[Dict[str, Any]],
    region_info: RegionInfo,
) -> List[str]:
    """식중독 지수 결과를 통합하고 발생한 오류를 반환합니다."""
    poison_errors = []
    if food_poisoning_data and region_info.gu:
        try:
            # calculator.py 함수 사용 유지
            poison_info = get_food_poisoning_risk_for_region(
                food_poisoning_data, region_info.gu
            )
            if poison_info:
                # --- 중요: poison_info 구조 확인 필요 ---
                # calculator.py의 반환 값이 risk 문자열인 경우 아래 수정 필요
                # 예: poison_info가 {"poison_index": "55", "poison_level": "관심"} 형태라고 가정
                index_results.food_poisoning_index = poison_info.get("poison_index")
                index_results.food_poisoning_risk = poison_info.get("poison_level")
                # ------------------------------------
                if not index_results.food_poisoning_risk:  # 만약 level만 반환한다면
                    index_results.food_poisoning_risk = poison_info  # 직접 할당
            else:
                logger.info(
                    f"No food poisoning data found for region: {region_info.gu}"
                )
                index_results.food_poisoning_error = (
                    f"해당 지역({region_info.gu}) 식중독 정보 없음"
                )
        except Exception as e:
            logger.exception(f"Error processing food poisoning data: {e}")
            poison_errors.append(f"식중독 정보 처리 오류: {e}")
            index_results.food_poisoning_error = f"식중독 정보 처리 오류: {e}"
    elif not region_info.gu and food_poisoning_data:
        poison_errors.append("지역 확인 불가로 식중독 정보 조회 불가")
        index_results.food_poisoning_error = "지역 확인 불가"
    elif not food_poisoning_data:
        # poison_errors.append("식중독 캐시 데이터 없음") # fetch_initial_data에서 이미 처리됨
        pass

    return poison_errors


# --- 메인 라우트 핸들러 ---
@router.get("/index", response_model=HealthIndexResponse)
async def get_indices(params: IndexRequestParams = Depends(get_index_request_params)):
    """
    건강 지수 API: 날씨 및 건강 관련 지수를 병렬 처리하여 계산하고 반환합니다.
    """
    start_time = time.time()
    logger.info(
        f"Index API request received: {params.model_dump()}"
    )  # model_dump() 사용 권장

    all_errors = []

    # 1. 초기 데이터 병렬 조회 (지역, 날씨, 식중독 캐시)
    region_result, weather_data, poison_cache, fetch_errors = await _fetch_initial_data(
        params.latitude, params.longitude
    )
    all_errors.extend(fetch_errors)

    # 지역 정보 설정
    region_info = RegionInfo()
    if region_result:
        gu, region_name = region_result
        region_info.gu = gu
        region_info.region = region_name
        if not gu:
            logger.warning(
                f"Region lookup failed for lat={params.latitude}, lon={params.longitude} (gu missing)"
            )
            # fetch_errors에 이미 포함되었을 수 있으므로 중복 추가 방지 고려
            if "지역 정보 조회 오류" not in str(all_errors):
                all_errors.append("지역 정보 조회 실패 (gu 없음)")

    # 식중독 데이터 추출
    food_poisoning_data = poison_cache.get("data", {}) if poison_cache else {}
    if (
        not food_poisoning_data and poison_cache is not None
    ):  # 캐시는 존재하나 데이터가 비어있는 경우
        logger.warning("Food poisoning cache exists but data is empty.")
        if "식중독 정보 조회 오류" not in str(all_errors):  # 이미 오류 목록에 없다면
            all_errors.append("식중독 정보 없음 (캐시 비어 있음)")

    # 2. 건강 지수 병렬 계산 (날씨 데이터가 있을 때만)
    index_results = IndexCalculationResult()  # 빈 결과 객체로 시작
    if weather_data:
        user_data_for_calc = {
            "age": params.age,
            "user_type": params.user_type,
            "disease": params.disease,
        }
        calculation_output, calc_errors = await _calculate_health_indices(
            weather_data, user_data_for_calc
        )
        all_errors.extend(calc_errors)

        # 계산 결과 반영 (오류 발생 가능성 고려)
        try:
            # 계산된 값들을 IndexCalculationResult 모델에 안전하게 할당
            # Pydantic 모델은 추가 필드를 무시하므로 update 사용 가능, 혹은 개별 할당
            # index_results = IndexCalculationResult(**calculation_output) # 이렇게 하면 누락 필드는 None

            # 개별 할당 방식 (더 명시적)
            index_results.apparent_temperature = calculation_output.get(
                "apparent_temperature"
            )
            index_results.apparent_temp_risk_status = calculation_output.get(
                "risk_status"
            )
            index_results.ali_score = calculation_output.get("ali_score")
            index_results.ali_level = calculation_output.get("ali_level")
            index_results.stroke_index_score = calculation_output.get(
                "stroke_index_score"
            )
            index_results.stroke_index_level = calculation_output.get(
                "stroke_index_level"
            )
            index_results.cold_index_score = calculation_output.get("cold_index_score")
            index_results.cold_index_level = calculation_output.get("cold_index_level")

        except Exception as e:
            logger.exception(f"Error assigning calculation results to model: {e}")
            all_errors.append(f"계산 결과 통합 오류: {e}")
    else:
        logger.warning("Weather data is unavailable, skipping index calculations.")
        if "날씨 정보 조회 오류" not in str(all_errors):  # 이미 오류 목록에 없다면
            all_errors.append("날씨 정보 없음으로 지수 계산 불가")

    # 3. 식중독 지수 결과 통합
    poison_errors = _integrate_poison_data(
        index_results, food_poisoning_data, region_info
    )
    all_errors.extend(poison_errors)

    # 4. 최종 응답 생성
    response = HealthIndexResponse(
        request=params.model_dump(),
        region=region_info,
        indices=index_results,
        errors=all_errors if all_errors else None,
    )

    elapsed_time = time.time() - start_time
    logger.info(f"Index API request processed in {elapsed_time:.4f}s")  # 초 정밀도 증가

    return response
