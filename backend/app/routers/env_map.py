from fastapi import APIRouter, HTTPException, Query, Depends
from typing import Optional, Dict, Any, Tuple
import logging
from datetime import datetime
from tzlocal import get_localzone
from pydantic import ValidationError
import traceback
import asyncio
import time

from app.schemas.request_models import EnvMapRequestParams
from app.schemas.response_models import EnvMapApiResponse

from app.cache import (
    get_fine_dust_map_cache,
    get_uv_map_cache,
    get_flood_trace_map_cache,
)

# 로깅 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(prefix="/api")

# 캐시 타임아웃 설정 (유지)
CACHE_TIMEOUT_SECONDS = 3600


# 의존성 주입 함수 (GET 파라미터 처리)
def get_env_map_request_params(
    env_type: str,
    force_refresh: bool = False,
) -> EnvMapRequestParams:
    try:
        # EnvMapRequestParams 모델로 유효성 검사 및 객체 생성
        return EnvMapRequestParams(env_type=env_type, force_refresh=force_refresh)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())


# 캐시된 지도 가져오는 함수
async def _get_cached_map(env_type: str) -> Tuple[Optional[str], Optional[str]]:
    """주어진 타입의 캐시된 지도와 업데이트 시간을 반환"""
    cache_getter = None
    if env_type == "fine_dust":
        cache_getter = get_fine_dust_map_cache
    elif env_type == "uv":
        cache_getter = get_uv_map_cache
    elif env_type == "flood_trace":
        cache_getter = get_flood_trace_map_cache

    if cache_getter:
        cache_data = await asyncio.to_thread(cache_getter)
        map_html = cache_data.get("data")
        last_updated_dt = cache_data.get("last_updated")
        last_updated_iso = (
            last_updated_dt.isoformat()
            if isinstance(last_updated_dt, datetime)
            else None
        )
        return map_html, last_updated_iso
    return None, None


# 캐시 업데이트 트리거 함수 (예시, 실제 구현은 scheduler 등에서)
async def _trigger_cache_update(env_type: str):
    logger.warning(
        f"Cache update for {env_type} should be triggered (implementation needed)."
    )


@router.get("/env_map", response_model=EnvMapApiResponse)
async def get_env_map(
    params: EnvMapRequestParams = Depends(get_env_map_request_params),
):
    """
    환경 관련 지도 API: 환경 유형을 받아 캐시된 지도 HTML을 반환합니다. (스키마 적용됨)
    """
    start_time = time.time()
    logger.info(f"Env map request received: {params}")

    request_info = params.model_dump()
    env_map_html = None
    last_updated = None
    error_msg = None

    try:
        # 1. 캐시에서 데이터 가져오기 시도
        if not params.force_refresh:
            env_map_html, last_updated = await _get_cached_map(params.env_type)
            if env_map_html:
                logger.info(f"Returning {params.env_type} map from cache.")
            else:
                logger.info(f"Cache miss or empty for {params.env_type} map.")
                error_msg = f"{params.env_type} 지도를 현재 사용할 수 없습니다. 잠시 후 다시 시도해주세요."

        # 2. 강제 새로고침 요청 시
        if params.force_refresh:
            logger.warning(
                f"Force refresh requested for {params.env_type}, returning current cache status."
            )
            env_map_html, last_updated = await _get_cached_map(params.env_type)
            if not env_map_html:
                error_msg = (
                    f"{params.env_type} 지도를 생성 중이거나 사용할 수 없습니다."
                )

        # 최종 응답 생성
        response = EnvMapApiResponse(
            request_info=request_info,
            env_map_html=env_map_html,
            env_type=params.env_type,
            last_updated=last_updated,
            error=error_msg,  # 오류 메시지 설정
        )

    except HTTPException:
        raise  # FastAPI 예외는 그대로 전달
    except Exception as e:
        logger.exception(f"Error processing env_map request for {params.env_type}: {e}")
        # 최종 단계에서 예외 발생 시 500 오류 반환
        raise HTTPException(status_code=500, detail=f"환경 지도 처리 중 오류 발생: {e}")

    elapsed_time = time.time() - start_time
    logger.info(f"Env map request processed in {elapsed_time:.2f}s")

    return response
