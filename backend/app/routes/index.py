from flask import Blueprint, request, jsonify
import asyncio
import traceback
import logging
from pydantic import ValidationError
from typing import Optional, Dict, Any, Tuple, List

# 모델 및 스키마 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import (
    IndicesApiResponse,
    WeatherData,  # 날씨 API 결과용
    RiskIndex,  # 사용자 위험도 평가용 (추후 구현)
    IndexingData,  # 크롤링 기반 지수 결과용
)

# 서비스 함수 임포트
from utils.helpers import get_region

from core.indexing.calculator import (
    calculate_apparent_temp_ali,
    calculate_stroke_index,
    calculate_cold_index,
    get_food_poisoning_risk_for_region,
)
from core.indexing.get_data import _fetch_weather_data
from app.cache import get_food_poisoning_cache
from config import settings

# 로깅 설정
logger = logging.getLogger(__name__)

bp = Blueprint("index", __name__, url_prefix="/api")


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


async def validate_request_parameters(
    request_args,
) -> Tuple[Optional[ApiRequest], Optional[str], Optional[str], List[str]]:
    """요청 파라미터 검증 및 모델 생성

    Args:
        request_args: Flask 요청 인자

    Returns:
        Tuple: (ApiRequest 모델, 구 이름, 지역, 에러 메시지 리스트)
    """
    try:
        lat_str = request_args.get("latitude")
        lon_str = request_args.get("longitude")
        age_str = request_args.get("age")
        diseases = request_args.getlist("disease")

        # 필수 파라미터 검증
        if lat_str is None or lon_str is None:
            missing = [
                m
                for m, v in [("latitude", lat_str), ("longitude", lon_str)]
                if v is None
            ]
            raise ValidationError(
                [{"loc": ["query", m], "msg": "field required"} for m in missing],
                ApiRequest,
            )

        try:
            lat = float(lat_str)
            lon = float(lon_str)
        except ValueError:
            raise ValidationError(
                [{"loc": ["query", "lat/lon"], "msg": "value is not a valid float"}],
                ApiRequest,
            )

        # 선택적 파라미터: 나이
        user_age: Optional[int] = None
        if age_str is not None:
            try:
                user_age = int(age_str)
                if user_age < 0:
                    raise ValueError("Age cannot be negative")
            except ValueError:
                raise ValidationError(
                    [
                        {
                            "loc": ["query", "age"],
                            "msg": "value is not a valid non-negative integer",
                        }
                    ],
                    ApiRequest,
                )

        # Pydantic 모델 생성
        validated_input = ApiRequest(
            request_location=LocationInput(latitude=lat, longitude=lon),
            user_input=UserInput(age=user_age, disease=diseases),
            disaster_type=settings.DEFAULT_DISASTER_TYPE,
        )

        # 사용자 지역(구) 조회 (식중독 지수 계산에 사용)
        gu, region = await get_region(lat, lon)

        return validated_input, gu, region, []

    except ValidationError as e:
        logger.error(f"Validation error: {e.errors()}")
        return None, None, None, e.errors()
    except Exception as e:
        logger.error(f"Error during request validation: {e}")
        traceback.print_exc()
        return None, None, None, [{"msg": str(e)}]


def calculate_health_indices(
    weather_data: Dict[str, Any], user_data: Dict[str, Any]
) -> Dict[str, Any]:
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


@bp.route("/index", methods=["GET"])
async def get_indices():
    """
    /index API:
      - 건강 관련 지수(날씨/감기, 식중독 등)를 계산하여 반환합니다.
      - 입력 파라미터: latitude, longitude, (선택) age, disease
      - 날씨 스크래핑과 식중독 캐시 조회를 비동기적으로 병렬 처리합니다.
    """
    # 입력 파라미터 검증 및 모델 생성
    validated_input, gu, region, validation_errors = await validate_request_parameters(
        request.args
    )
    if validation_errors:
        return (
            jsonify(
                {"error": "Invalid input parameters", "details": validation_errors}
            ),
            400,
        )

    # 비동기 작업: 날씨 스크래핑 및 식중독 캐시 조회 병렬 처리
    try:
        logger.info(
            "Starting async tasks: Weather scraping and Food poisoning cache lookup"
        )

        # 비동기 작업 생성
        weather_task = asyncio.create_task(
            fetch_weather_and_pressure_data(
                validated_input.request_location.latitude,
                validated_input.request_location.longitude,
            )
        )
        poison_cache_task = asyncio.to_thread(get_food_poisoning_cache)

        # 병렬 처리
        weather_result, cached_poison_data = await asyncio.gather(
            weather_task, poison_cache_task, return_exceptions=True
        )
        print(cached_poison_data)

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
                weather_result, validated_input.user_input.model_dump()
            )
            calculated_indices.update(indices)
            overall_error_parts.extend(error_parts)
        else:
            calculated_indices["error"] = "날씨/기압 정보를 가져오지 못했습니다."
            overall_error_parts.append("날씨 데이터 조회 결과 형식 오류")

        # 식중독 데이터 처리
        food_poisoning_data = {}
        if isinstance(cached_poison_data, Exception):
            logger.error(f"Error fetching food poisoning cache: {cached_poison_data}")
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
                    f"Region (gu) not determined for coords: {validated_input.request_location}"
                )
                calculated_indices["food_poisoning_error"] = (
                    "지역 확인 불가, 식중독 정보 조회 실패"
                )
                overall_error_parts.append("지역 확인 불가")

        # 응답 생성
        response = {
            "request": validated_input.model_dump(),
            "region": {"gu": gu, "region": region},
            "indices": calculated_indices,
        }

        if overall_error_parts:
            response["errors"] = overall_error_parts

        return jsonify(response)

    except Exception as e:
        logger.error(f"Unhandled error in get_indices: {e}")
        traceback.print_exc()
        return jsonify({"error": "Internal server error", "message": str(e)}), 500


# 여기에 추가 API 라우트 정의
