from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any, Tuple
import logging
from datetime import datetime
from tzlocal import get_localzone
from pydantic import ValidationError
import traceback
import asyncio
import time

# 스키마 임포트
from app.schemas.request_models import EnvironmentInput
from app.schemas.response_models import EnvMapApiResponse

# 캐시 및 데이터 로드 함수 임포트
from app.cache import (
    get_fine_dust_map_cache,
    get_uv_map_cache,
    get_flood_trace_map_cache,
)

# 로깅 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(prefix="/api")

# 캐시 타임아웃 설정 (1시간)
CACHE_TIMEOUT_SECONDS = 3600


@router.get("/env_map", response_model=EnvMapApiResponse)
async def get_env_map(env_type: str, force_refresh: bool = False):
    """
    환경 관련 지도 API 엔드포인트:

    - **env_type**: 환경 지도 유형 (fine_dust, uv)
    - **force_refresh**: 캐시를 무시하고 새로 데이터를 가져올지 여부 (기본값: false)

    반환:
    - HTML 형식의 지도 시각화
    """
    try:
        # 요청 처리 시작 시간 (성능 측정용)
        start_time = time.time()

        logger.info(
            f"Received request for {env_type} map (force_refresh={force_refresh})"
        )

        # Pydantic 모델로 유효성 검사
        try:
            validated_input = EnvironmentInput(env_type=env_type)
            env_type = validated_input.env_type  # 검증 및 정규화된 값 사용
        except ValidationError as e:
            raise HTTPException(
                status_code=400,
                detail={"error": "Invalid env_type", "details": e.errors()},
            )

        # 요청 정보 구성
        request_info = {"env_type": env_type, "force_refresh": force_refresh}

        # 응답 생성 준비
        result = None
        last_updated = None
        error_msg = None

        # 타임아웃 설정 (5초)
        timeout_seconds = 5

        try:
            # 환경 지도 가져오기 (타임아웃 적용)
            if env_type == "fine_dust":
                result, last_updated = await asyncio.wait_for(
                    get_fine_dust_map(force_refresh), timeout=timeout_seconds
                )
            elif env_type == "uv":
                result, last_updated = await asyncio.wait_for(
                    get_uv_map(force_refresh), timeout=timeout_seconds
                )
            elif env_type == "flood_trace":
                result, last_updated = await asyncio.wait_for(
                    get_flood_trace_map(force_refresh), timeout=timeout_seconds
                )
            else:
                # 이 부분은 Pydantic 검증으로 걸러져야 하지만 안전장치로 남겨둠
                raise HTTPException(
                    status_code=400,
                    detail={
                        "error": "Invalid env_type",
                        "details": "env_type must be either 'fine_dust' or 'uv' or 'flood_trace'",
                    },
                )

        except asyncio.TimeoutError:
            logger.error(
                f"Timeout error while fetching {env_type} map data (>{timeout_seconds}s)"
            )
            error_msg = f"요청 처리 시간 초과 ({timeout_seconds}초)"

            # 타임아웃 발생 시 캐시에서라도 데이터 가져오기 시도
            if env_type == "fine_dust":
                cache_data = get_fine_dust_map_cache()
                if cache_data["data"] and cache_data["last_updated"]:
                    result = cache_data["data"]
                    last_updated = cache_data["last_updated"].isoformat()
                    logger.info(f"Returning cached fine dust map after timeout")
            elif env_type == "uv":
                cache_data = get_uv_map_cache()
                if cache_data["data"] and cache_data["last_updated"]:
                    result = cache_data["data"]
                    last_updated = cache_data["last_updated"].isoformat()
                    logger.info(f"Returning cached UV map after timeout")
            elif env_type == "flood_trace":
                cache_data = get_flood_trace_map_cache()
                if cache_data["data"] and cache_data["last_updated"]:
                    result = cache_data["data"]
                    last_updated = cache_data["last_updated"].isoformat()
                    logger.info(f"Returning cached flood trace map after timeout")

        # 응답 생성
        response_data = EnvMapApiResponse(
            request_info=request_info,
            env_map_html=result,
            env_type=env_type,
            last_updated=last_updated,
            error=(
                error_msg
                if error_msg
                else (None if result else "지도 생성에 실패했습니다.")
            ),
        )

        # 실행 시간 측정 및 로깅
        elapsed_time = time.time() - start_time
        logger.info(f"Request for {env_type} map processed in {elapsed_time:.2f}s")

        return response_data.model_dump()

    except HTTPException:
        # 이미 처리된 HTTP 예외는 그대로 전달
        raise

    except Exception as e:
        logger.error(f"Error in /api/env_map: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail={"error": "서버 내부 오류가 발생했습니다", "message": str(e)},
        )


async def get_fine_dust_map(
    force_refresh: bool = False,
) -> Tuple[Optional[str], Optional[str]]:
    """미세먼지 지도를 가져오는 함수

    Args:
        force_refresh: 캐시 무시하고 새로 가져올지 여부

    Returns:
        tuple: (지도 HTML, 마지막 업데이트 시간)
    """
    try:
        # 캐시 확인
        if not force_refresh:
            cache_data = get_fine_dust_map_cache()
            last_updated_cache = cache_data.get("last_updated")

            if isinstance(last_updated_cache, datetime):
                local_tz = get_localzone()
                now_aware = datetime.now(tz=local_tz)

                # 캐시 유효성 검사
                if (
                    cache_data["data"]
                    and (now_aware - last_updated_cache).total_seconds()
                    < CACHE_TIMEOUT_SECONDS
                ):
                    logger.info("Returning fine dust map from valid cache")
                    return cache_data["data"], last_updated_cache.isoformat()

            now = datetime.now()

            return cache_data["data"], now.isoformat()

    except Exception as e:
        logger.error(f"Error generating fine dust map: {e}")
        # 오류 발생 시 캐시 확인
        cache_data = get_fine_dust_map_cache()
        if cache_data["data"] and cache_data["last_updated"]:
            logger.info("Falling back to cached fine dust map data after exception")
            return cache_data["data"], cache_data["last_updated"].isoformat()
        return None, None


async def get_uv_map(
    force_refresh: bool = False,
) -> Tuple[Optional[str], Optional[str]]:
    """자외선 지도를 가져오는 함수

    Args:
        force_refresh: 캐시 무시하고 새로 가져올지 여부

    Returns:
        tuple: (지도 HTML, 마지막 업데이트 시간)
    """
    try:
        # 캐시 확인
        if not force_refresh:
            cache_data = get_uv_map_cache()
            last_update_cache = cache_data.get("last_updated")

            if isinstance(last_update_cache, datetime):
                local_tz = get_localzone()
                now_aware = datetime.now(tz=local_tz)

                # 캐시 유효성 검사
                if (
                    cache_data["data"]
                    and (now_aware - last_update_cache).total_seconds()
                    < CACHE_TIMEOUT_SECONDS
                ):
                    logger.info("Returning UV map from valid cache")
                    return cache_data["data"], last_update_cache.isoformat()

        now = datetime.now()

        return cache_data["data"], now.isoformat()

    except Exception as e:
        logger.error(f"Error generating UV map: {e}")
        # 오류 발생 시 캐시 확인
        cache_data = get_uv_map_cache()
        if cache_data["data"] and cache_data["last_updated"]:
            logger.info("Falling back to cached UV map data after exception")
            return cache_data["data"], cache_data["last_updated"].isoformat()
        return None, None


async def get_flood_trace_map(
    force_refresh: bool = False,
) -> Tuple[Optional[str], Optional[str]]:
    """침수 흔적도를 가져오는 함수

    Args:
        force_refresh: 캐시 무시하고 새로 가져올지 여부

    Returns:
        tuple: (지도 HTML, 마지막 업데이트 시간)
    """
    try:
        # 캐시 확인
        if not force_refresh:
            cache_data = get_flood_trace_map_cache()
            last_update_cache = cache_data.get("last_updated")

            if isinstance(last_update_cache, datetime):
                local_tz = get_localzone()
                now_aware = datetime.now(tz=local_tz)

                # 캐시 유효성 검사
                if (
                    cache_data["data"]
                    and (now_aware - last_update_cache).total_seconds()
                    < CACHE_TIMEOUT_SECONDS
                ):
                    logger.info("Returning flood trace map from valid cache")
                    return cache_data["data"], last_update_cache.isoformat()

        now = datetime.now()

        return cache_data["data"], now.isoformat()

    except Exception as e:
        logger.error(f"Error generating flood trace map: {e}")
        # 오류 발생 시 캐시 확인
        cache_data = get_flood_trace_map_cache()
        if cache_data["data"] and cache_data["last_updated"]:
            logger.info("Falling back to cached flood trace map data after exception")
            return cache_data["data"], cache_data["last_updated"].isoformat()
        return None, None
