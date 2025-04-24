from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse
from pydantic import ValidationError
import traceback
import logging
import asyncio
import time
from typing import Optional, Dict, Any, Tuple, List

# 모델 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import MapApiResponse

from core.shelter.service import _generate_single_map_html

from config.settings import settings

# 로깅 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(prefix="/api")

# 캐시 데이터 (간단한 인메모리 캐싱)
shelter_map_cache = {}


@router.get("/map", response_model=MapApiResponse)
async def get_map(
    latitude: float,
    longitude: float,
    disaster_type: str = settings.DEFAULT_DISASTER_TYPE,
    radius_km: float = settings.DEFAULT_RADIUS_KM,
    force_refresh: bool = False,
):
    """
    API 엔드포인트: 위치, 재난 유형 및 선택적 사용자 정보/반경을 받아
    대피소 지도 HTML 등을 반환합니다.

    - **latitude**: 위도 좌표
    - **longitude**: 경도 좌표
    - **disaster_type**: 재난 유형 (기본값: HEAT_WAVE)
    - **radius_km**: 대피소 검색 반경 (기본값: 2.0km)
    - **force_refresh**: 캐시 무시하고 새로 데이터 가져올지 여부
    """
    # 요청 처리 시작 시간 (성능 측정용)
    start_time = time.time()

    request_data_for_response = {}

    try:
        logger.info(
            f"Received shelter map request: lat={latitude}, lon={longitude}, disaster={disaster_type}, radius={radius_km}"
        )

        # 반경 파라미터 검증
        if radius_km <= 0:
            raise HTTPException(status_code=400, detail="반경은 양수여야 합니다")

        # API 요청 모델 생성
        try:
            validated_input = ApiRequest(
                request_location=LocationInput(latitude=latitude, longitude=longitude),
                user_input=UserInput(),
                disaster_type=disaster_type,
            )
        except ValidationError as e:
            raise HTTPException(
                status_code=400,
                detail={
                    "error": "입력 파라미터 유효성 검증 실패",
                    "details": e.errors(),
                },
            )

        # 응답용 요청 데이터 준비
        request_data_for_response = validated_input.model_dump()
        request_data_for_response["radius_km"] = radius_km

        # 캐시 키 생성 (위치 + 재난 유형 + 반경 기준)
        cache_key = f"{latitude:.6f}_{longitude:.6f}_{disaster_type}_{radius_km:.1f}"

        # 캐시 확인 (강제 갱신이 아닌 경우)
        if not force_refresh and cache_key in shelter_map_cache:
            logger.info(f"Returning shelter map from cache for {cache_key}")
            response_data = MapApiResponse(
                request_info=request_data_for_response,
                shelter_map_html=shelter_map_cache[cache_key],
                error=None,
            )

            # 실행 시간 측정 및 로깅
            elapsed_time = time.time() - start_time
            logger.info(
                f"Shelter map request processed from cache in {elapsed_time:.2f}s"
            )

            return response_data.model_dump(exclude_none=True)

        # 타임아웃 설정 (10초)
        timeout_seconds = 10

        try:
            # 지도 생성 (타임아웃 적용)
            logger.info(f"Generating shelter map for {cache_key}")
            _, shelter_map_html = await asyncio.wait_for(
                _generate_single_map_html(
                    latitude=validated_input.request_location.latitude,
                    longitude=validated_input.request_location.longitude,
                    disaster_type=validated_input.disaster_type,
                    radius_km=radius_km,
                ),
                timeout=timeout_seconds,
            )

            # 결과 처리
            if not shelter_map_html:
                raise Exception("No shelter map HTML generated")

            # 캐시에 결과 저장
            shelter_map_cache[cache_key] = shelter_map_html

            # 응답 생성
            response_data = MapApiResponse(
                request_info=request_data_for_response,
                shelter_map_html=shelter_map_html,
                error=None,
            )

            # 실행 시간 측정 및 로깅
            elapsed_time = time.time() - start_time
            logger.info(f"Shelter map request processed in {elapsed_time:.2f}s")

            return response_data.model_dump(exclude_none=True)

        except asyncio.TimeoutError:
            logger.error(
                f"Timeout error ({timeout_seconds}s) when generating shelter map"
            )
            raise HTTPException(
                status_code=408,  # 408 Request Timeout
                detail={
                    "error": f"대피소 지도 생성 시간이 초과되었습니다 ({timeout_seconds}초)",
                    "request_info": request_data_for_response,
                },
            )

    except HTTPException:
        # 이미 처리된 HTTP 예외는 그대로 전달
        raise

    except Exception as e:
        logger.error(f"Error in /api/map: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail={
                "error": "서버 내부 오류가 발생했습니다",
                "message": str(e),
                "request_info": request_data_for_response,
            },
        )
