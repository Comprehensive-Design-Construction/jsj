from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Optional, Any
from pydantic import ValidationError
import logging
import asyncio
from datetime import datetime

# 스키마 및 함수 import (경로 주의)
from app.schemas.request_models import LocationInput  # 요청 파라미터용
from app.schemas.response_models import (  # 수정된 응답 모델 import
    SingleRegionFineDustResponse,
    SingleRegionUvResponse,
    RegionInfo,
    RegionFineDustData,  # 내부 데이터 검증/변환에 사용 가능
    RegionUvData,  # 내부 데이터 검증/변환에 사용 가능
)
from app.cache import get_fine_dust_cache, get_uv_cache  # 캐시 함수
from utils.helpers import get_region  # 지역 조회 함수

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/environment")


# 의존성 주입 함수
def get_location_params(latitude: float, longitude: float) -> LocationInput:
    try:
        return LocationInput(latitude=latitude, longitude=longitude)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=e.errors())


@router.get("/fine_dust", response_model=SingleRegionFineDustResponse)
async def get_regional_fine_dust_data(
    location: LocationInput = Depends(get_location_params),
):
    """
    지정된 위도/경도에 해당하는 지역의 최신 미세먼지 데이터를 반환합니다.
    """
    logger.info(f"Regional fine dust data API request received: {location}")
    request_location_dict = location.model_dump()
    region_info = RegionInfo()  # 기본 빈 객체
    fine_dust_data_for_region = None
    last_updated_iso = None
    error_msg = None

    try:
        # 1. 지역 정보 조회
        try:
            gu, region_name = await get_region(location.latitude, location.longitude)
            region_info = RegionInfo(gu=gu, region=region_name)
            if not gu:
                error_msg = "해당 위치의 지역(구) 정보를 찾을 수 없습니다."
                logger.warning(f"{error_msg} for {location}")
        except Exception as e:
            logger.exception(f"Error getting region info for {location}: {e}")
            error_msg = f"지역 정보 조회 중 오류 발생: {e}"

        # 2. 캐시에서 전체 미세먼지 데이터 가져오기
        cache_content = await asyncio.to_thread(get_fine_dust_cache)
        all_fine_dust_data = cache_content.get("data")
        last_updated_dt = cache_content.get("last_updated")

        if isinstance(last_updated_dt, datetime):
            last_updated_iso = last_updated_dt.isoformat()

        # 3. 해당 지역 데이터 추출 (지역 조회가 성공했고, 캐시 데이터가 있을 때)
        if region_info.gu and all_fine_dust_data:
            regional_data_dict = all_fine_dust_data.get(region_info.gu)
            if regional_data_dict:
                # Pydantic 모델로 변환 시도 (데이터 유효성 검사)
                try:
                    fine_dust_data_for_region = RegionFineDustData(**regional_data_dict)
                    logger.info(f"Found fine dust data for {region_info.gu}")
                except ValidationError as e:
                    logger.error(
                        f"Validation error for cached fine dust data in {region_info.gu}: {e}"
                    )
                    error_msg = (
                        f"{region_info.gu}의 미세먼지 데이터 형식이 올바르지 않습니다."
                    )
            else:
                if not error_msg:  # 지역 조회는 성공했으나 데이터가 없는 경우
                    error_msg = (
                        f"{region_info.gu}에 대한 미세먼지 데이터가 캐시에 없습니다."
                    )
                logger.warning(error_msg)
        elif not all_fine_dust_data and not error_msg:
            error_msg = "미세먼지 데이터가 캐시에 없습니다."
            logger.warning(error_msg)

    except Exception as e:
        logger.exception(f"Error processing fine dust request for {location}: {e}")
        error_msg = f"미세먼지 데이터 처리 중 오류 발생: {e}"

    # response_model 에 맞게 반환
    return SingleRegionFineDustResponse(
        request_location=request_location_dict,
        region_info=region_info,
        fine_dust_data=fine_dust_data_for_region,
        last_updated=last_updated_iso,
        error=error_msg,
    )


@router.get("/uv", response_model=SingleRegionUvResponse)
async def get_regional_uv_index_data(
    location: LocationInput = Depends(get_location_params),
):
    """
    지정된 위도/경도에 해당하는 지역의 최신 자외선 지수 데이터를 반환합니다.
    """
    logger.info(f"Regional UV index data API request received: {location}")
    request_location_dict = location.model_dump()
    region_info = RegionInfo()
    uv_data_for_region = None
    last_updated_iso = None
    error_msg = None

    try:
        # 1. 지역 정보 조회
        try:
            gu, region_name = await get_region(location.latitude, location.longitude)
            region_info = RegionInfo(gu=gu, region=region_name)
            if not gu:
                error_msg = "해당 위치의 지역(구) 정보를 찾을 수 없습니다."
                logger.warning(f"{error_msg} for {location}")
        except Exception as e:
            logger.exception(f"Error getting region info for {location}: {e}")
            error_msg = f"지역 정보 조회 중 오류 발생: {e}"

        # 2. 캐시에서 전체 UV 데이터 가져오기
        cache_content = await asyncio.to_thread(get_uv_cache)
        all_uv_data = cache_content.get("data")
        last_updated_dt = cache_content.get("last_updated")

        if isinstance(last_updated_dt, datetime):
            last_updated_iso = last_updated_dt.isoformat()

        # 3. 해당 지역 데이터 추출
        if region_info.gu and all_uv_data:
            regional_data_dict = all_uv_data.get(region_info.gu)
            if regional_data_dict is not None:
                try:
                    # RegionUvData 모델 사용
                    if isinstance(regional_data_dict, dict):
                        uv_data_for_region = RegionUvData(**regional_data_dict)
                    # 캐시 데이터가 바로 값(int)일 때
                    elif isinstance(regional_data_dict, (int, float)):
                        uv_data_for_region = RegionUvData(
                            uv_index=int(regional_data_dict)
                        )
                    else:
                        raise ValidationError("Invalid data type in UV cache")

                    logger.info(f"Found UV data for {region_info.gu}")
                except ValidationError as e:
                    logger.error(
                        f"Validation error for cached UV data in {region_info.gu}: {e}"
                    )
                    error_msg = (
                        f"{region_info.gu}의 UV 데이터 형식이 올바르지 않습니다."
                    )
            else:
                if not error_msg:
                    error_msg = f"{region_info.gu}에 대한 UV 데이터가 캐시에 없습니다."
                logger.warning(error_msg)
        elif not all_uv_data and not error_msg:
            error_msg = "UV 데이터가 캐시에 없습니다."
            logger.warning(error_msg)

    except Exception as e:
        logger.exception(f"Error processing UV index request for {location}: {e}")
        error_msg = f"UV 지수 데이터 처리 중 오류 발생: {e}"

    # response_model 에 맞게 반환
    return SingleRegionUvResponse(
        request_location=request_location_dict,
        region_info=region_info,
        uv_data=uv_data_for_region,
        last_updated=last_updated_iso,
        error=error_msg,
    )
