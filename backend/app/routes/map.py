from flask import Blueprint, request, jsonify
from pydantic import ValidationError
import traceback
import logging
import asyncio
import time
from typing import Optional, Dict, Any, Tuple

# 정확한 사용자 제공 모델 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import (
    MapApiResponse,
)

from core.shelter.service import _generate_single_map_html

from config import settings

# 로깅 설정
logger = logging.getLogger(__name__)

bp = Blueprint("map", __name__, url_prefix="/api")

# 캐시 데이터 (간단한 인메모리 캐싱)
shelter_map_cache = {}


@bp.route("/map", methods=["GET"])
async def get_map():
    """
    API 엔드포인트: 위치, 재난 유형 및 선택적 사용자 정보/반경을 받아
    대피소 지도 HTML 등을 반환합니다.
    """
    # 요청 처리 시작 시간 (성능 측정용)
    start_time = time.time()

    request_data_for_response = {}
    input_radius_km = settings.DEFAULT_RADIUS_KM
    validated_input: Optional[ApiRequest] = None

    try:
        lat_str = request.args.get("latitude")
        lon_str = request.args.get("longitude")
        disaster_str = request.args.get(
            "disaster_type", default=settings.DEFAULT_DISASTER_TYPE
        )
        radius_str = request.args.get(
            "radius_km", default=str(settings.DEFAULT_RADIUS_KM)
        )
        force_refresh = request.args.get("force_refresh", "false").lower() == "true"

        logger.info(
            f"Received shelter map request: lat={lat_str}, lon={lon_str}, disaster={disaster_str}, radius={radius_str}"
        )

        # 필수 파라미터 검증
        if lat_str is None or lon_str is None:
            missing = [
                m
                for m, v in [("latitude", lat_str), ("longitude", lon_str)]
                if v is None
            ]
            return (
                jsonify(
                    {
                        "error": "필수 파라미터가 누락되었습니다",
                        "details": f"다음 파라미터가 필요합니다: {', '.join(missing)}",
                    }
                ),
                400,
            )

        # 파라미터 변환
        try:
            lat = float(lat_str)
            lon = float(lon_str)
        except ValueError:
            return (
                jsonify(
                    {
                        "error": "좌표 형식이 올바르지 않습니다",
                        "details": "위도와 경도는 숫자(float)여야 합니다",
                    }
                ),
                400,
            )

        # 반경 파라미터 처리
        try:
            input_radius_km = float(radius_str)
            if input_radius_km <= 0:
                raise ValueError("반경은 양수여야 합니다")
        except ValueError as e:
            return (
                jsonify(
                    {"error": "반경 파라미터가 올바르지 않습니다", "details": str(e)}
                ),
                400,
            )

        # API 요청 모델 생성
        try:
            validated_input = ApiRequest(
                request_location=LocationInput(latitude=lat, longitude=lon),
                user_input=UserInput(),
                disaster_type=disaster_str,
            )
        except ValidationError as e:
            return (
                jsonify(
                    {"error": "입력 파라미터 유효성 검증 실패", "details": e.errors()}
                ),
                400,
            )

        # 응답용 요청 데이터 준비
        request_data_for_response = validated_input.model_dump()
        request_data_for_response["radius_km"] = input_radius_km

        # 캐시 키 생성 (위치 + 재난 유형 + 반경 기준)
        cache_key = f"{lat:.6f}_{lon:.6f}_{disaster_str}_{input_radius_km:.1f}"

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

            return jsonify(response_data.model_dump(exclude_none=True))

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
                    radius_km=input_radius_km,
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

            return jsonify(response_data.model_dump(exclude_none=True))

        except asyncio.TimeoutError:
            logger.error(
                f"Timeout error ({timeout_seconds}s) when generating shelter map"
            )
            return (
                jsonify(
                    {
                        "error": f"대피소 지도 생성 시간이 초과되었습니다 ({timeout_seconds}초)",
                        "request_info": request_data_for_response,
                    }
                ),
                408,
            )  # 408 Request Timeout

    except Exception as e:
        logger.error(f"Error in /api/map: {e}")
        traceback.print_exc()
        return (
            jsonify(
                {
                    "error": "서버 내부 오류가 발생했습니다",
                    "message": str(e),
                    "request_info": request_data_for_response,
                }
            ),
            500,
        )
