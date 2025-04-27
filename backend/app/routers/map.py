from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import ValidationError
import traceback
import logging
import asyncio
import time
from typing import Optional, Dict, Any

# 수정된 스키마 import
from app.schemas.request_models import MapRequestParams
from app.schemas.response_models import MapApiResponse

from core.shelter.service import _generate_single_map_html
from config.settings import settings

# 로깅 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(prefix="/api")

# 캐시 데이터 (간단한 인메모리 캐싱) - 유지
shelter_map_cache = {}


# 의존성 주입 함수 (GET 파라미터 처리)
def get_map_request_params(
    latitude: float,
    longitude: float,
    disaster_type: str = settings.DEFAULT_DISASTER_TYPE,  # 기본값 사용
    radius_km: float = settings.DEFAULT_RADIUS_KM,  # 기본값 사용
    force_refresh: bool = False,
) -> MapRequestParams:
    try:
        # MapRequestParams 모델로 유효성 검사 및 객체 생성
        params = MapRequestParams(
            latitude=latitude,
            longitude=longitude,
            disaster_type=disaster_type,
            radius_km=radius_km,
            force_refresh=force_refresh,
        )
        # 추가적인 반경 값 검증 (모델에서 gt=0 했으므로 중복될 수 있음)
        if params.radius_km <= 0:
            raise ValueError("반경은 양수여야 합니다")
        return params
    except ValidationError as e:
        # Pydantic 유효성 검사 오류 처리
        raise HTTPException(status_code=422, detail=e.errors())
    except ValueError as e:
        # 직접 발생시킨 오류 처리
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/map", response_model=MapApiResponse)
async def get_map(params: MapRequestParams = Depends(get_map_request_params)):
    """
    대피소 지도 API: 위치, 재난 유형 등을 받아 대피소 지도 HTML을 반환합니다. (스키마 적용됨)
    """
    start_time = time.time()
    logger.info(f"Shelter map request received: {params}")

    request_data_for_response = params.model_dump()

    # 캐시 키 생성
    cache_key = f"{params.latitude:.6f}_{params.longitude:.6f}_{params.disaster_type}_{params.radius_km:.1f}"

    # 캐시 확인
    if not params.force_refresh and cache_key in shelter_map_cache:
        logger.info(f"Returning shelter map from cache for {cache_key}")
        elapsed_time = time.time() - start_time
        logger.info(f"Shelter map request processed from cache in {elapsed_time:.2f}s")
        # response_model에 맞게 반환
        return MapApiResponse(
            request_info=request_data_for_response,
            shelter_map_html=shelter_map_cache[cache_key],
            error=None,
        )

    # 타임아웃 설정
    timeout_seconds = 10
    shelter_map_html = None
    error_detail = None

    try:
        logger.info(f"Generating shelter map for {cache_key}")
        # 서비스 함수 호출 시 파라미터 전달
        _, shelter_map_html = await asyncio.wait_for(
            _generate_single_map_html(
                latitude=params.latitude,
                longitude=params.longitude,
                disaster_type=params.disaster_type,
                radius_km=params.radius_km,
            ),
            timeout=timeout_seconds,
        )

        if not shelter_map_html:
            # 서비스 함수가 None을 반환한 경우 (예외 없이)
            error_detail = "지도 생성에 실패했습니다 (결과 없음)."
            logger.warning(f"Map generation returned None for {cache_key}")
            # 이 경우 500 에러 또는 다른 상태 코드 고려 가능
            raise HTTPException(status_code=500, detail=error_detail)

        # 성공 시 캐시에 저장
        shelter_map_cache[cache_key] = shelter_map_html

    except asyncio.TimeoutError:
        logger.error(
            f"Timeout error ({timeout_seconds}s) generating shelter map for {cache_key}"
        )
        error_detail = f"대피소 지도 생성 시간이 초과되었습니다 ({timeout_seconds}초)"
        # 타임아웃 시 408 에러 발생
        raise HTTPException(status_code=408, detail=error_detail)
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Error generating shelter map for {cache_key}: {e}")
        error_detail = f"지도 생성 중 오류 발생: {e}"
        raise HTTPException(status_code=500, detail=error_detail)

    # 성공 응답 반환
    elapsed_time = time.time() - start_time
    logger.info(f"Shelter map request processed in {elapsed_time:.2f}s")
    return MapApiResponse(
        request_info=request_data_for_response,
        shelter_map_html=shelter_map_html,
        error=None,  # 성공 시 error는 None
    )
