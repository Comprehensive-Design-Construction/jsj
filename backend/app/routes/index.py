from flask import Blueprint, request, jsonify
import asyncio
import traceback
from pydantic import ValidationError
from typing import Optional

# 모델 및 스키마 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import (
    IndicesApiResponse,
    WeatherData,  # 날씨 API 결과용
    RiskIndex,  # 사용자 위험도 평가용 (추후 구현)
    IndexingData,  # 크롤링 기반 지수 결과용
)

# 서비스 함수 임포트
from core.indexing.crawler import (
    fetch_weather_and_pressure_data,
    _get_region_from_coords,  # 좌표 기반 지역 조회 (비동기)
)
from core.indexing.calculator import (
    calculate_apparent_temp_ali,
    calculate_stroke_index,
    calculate_cold_index,
    get_food_poisoning_risk_for_region,
)
from app.cache import get_food_poisoning_cache
from config import settings

bp = Blueprint("index", __name__, url_prefix="/api")


@bp.route("/index", methods=["GET"])
async def get_indices():
    """
    /index API:
      - 건강 관련 지수(날씨/감기, 식중독 등)를 계산하여 반환합니다.
      - 입력 파라미터: latitude, longitude, (선택) age, disease
      - 날씨 스크래핑과 식중독 캐시 조회를 비동기적으로 병렬 처리합니다.
    """
    request_data_for_response = {}
    validated_input: Optional[ApiRequest] = None
    overall_error_parts = []  # 에러 메시지 조합용 리스트

    # ------------------------------
    # 1. 입력 파라미터 검증 및 모델 생성
    # ------------------------------
    try:
        lat_str = request.args.get("latitude")
        lon_str = request.args.get("longitude")
        age_str = request.args.get("age")
        diseases = request.args.getlist("disease")

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
        request_data_for_response = validated_input.model_dump()

        # 사용자 지역(구) 조회 (식중독 지수 계산에 사용)
        gu, region = await _get_region_from_coords(lat, lon)

    except ValidationError as e:
        return (
            jsonify({"error": "Invalid input parameters", "details": e.errors()}),
            400,
        )
    except Exception as e:
        print(f"Error during request parsing or determining region: {e}")
        traceback.print_exc()
        return (
            jsonify({"error": "Failed to process request input or determine region"}),
            400,
        )

    # ------------------------------
    # 2. 비동기 작업: 날씨 스크래핑 및 식중독 캐시 조회 병렬 처리
    # ------------------------------
    try:
        print("Starting async tasks: Weather scraping and Food poisoning cache lookup")

        # 날씨 스크래핑은 비동기 함수로 바로 호출
        weather_task = asyncio.create_task(
            fetch_weather_and_pressure_data(
                validated_input.request_location.latitude,
                validated_input.request_location.longitude,
            )
        )
        # 캐시 조회는 blocking 함수라면 asyncio.to_thread를 사용
        poison_cache_task = asyncio.to_thread(get_food_poisoning_cache)

        weather_result, cached_poison_data = await asyncio.gather(
            weather_task, poison_cache_task, return_exceptions=True
        )

        # 식중독 캐시 데이터 처리
        food_poisoning_data = {}
        if not isinstance(cached_poison_data, Exception):
            food_poisoning_data = cached_poison_data.get("data", {})
            cache_last_updated = cached_poison_data.get("last_updated")
            print(
                f"Retrieved food poisoning data from cache (Last updated: {cache_last_updated})"
            )
        else:
            print("Error fetching food poisoning cache.")

        # ------------------------------
        # 3. 건강 지수 계산
        # ------------------------------
        calculated_indices = {}
        if isinstance(weather_result, Exception) or (
            isinstance(weather_result, dict) and weather_result.get("error")
        ):
            error_msg = (
                weather_result.get("error")
                if isinstance(weather_result, dict)
                else str(weather_result)
            )
            print(f"Error fetching weather/pressure data: {error_msg}")
            calculated_indices["error"] = f"날씨/기압 정보 조회 실패: {error_msg}"
            overall_error_parts.append("Scraped weather fetch failed.")
        elif isinstance(weather_result, dict):
            # 날씨 기반 지수 계산
            print("Calculating indices based on scraped weather data...")
            apparent_temp_ali_res = calculate_apparent_temp_ali(
                weather_result, validated_input.user_input.model_dump()
            )
            stroke_res = calculate_stroke_index(weather_result)
            cold_res = calculate_cold_index(weather_result)
            calculated_indices.update(apparent_temp_ali_res)
            calculated_indices.update(stroke_res)
            calculated_indices.update(cold_res)
            # 각 계산 단계에서 오류 메시지가 있는 경우 기록
            if apparent_temp_ali_res.get("error"):
                overall_error_parts.append("ApparentTemp/ALI calc failed.")
            if stroke_res.get("error"):
                overall_error_parts.append("Stroke Index calc failed.")
            if cold_res.get("error"):
                overall_error_parts.append("Cold Index calc failed.")
        else:
            calculated_indices["error"] = "날씨/기압 정보를 가져오지 못했습니다."
            overall_error_parts.append(
                "Scraped weather fetch returned unexpected result."
            )

        # 식중독 지수 처리: 사용자의 지역(구)가 확인된 경우에만 처리
        if not food_poisoning_data:
            print("Food poisoning cache is empty.")
            calculated_indices["error"] = (
                calculated_indices.get("error") or ""
            ) + "; 식중독 정보 없음(캐시)"
            overall_error_parts.append("Food poisoning cache empty.")
        elif gu:
            poison_info = get_food_poisoning_risk_for_region(food_poisoning_data, gu)
            if poison_info:
                calculated_indices["food_poisoning_index"] = poison_info.get(
                    "poison_index"
                )
                calculated_indices["food_poisoning_risk"] = poison_info.get(
                    "poison_level"
                )
            else:
                print(f"Food poisoning risk not available for {gu} in cache.")
        else:
            print(
                "User region (district) unknown, cannot get specific food poisoning risk."
            )

        # ------------------------------
        # 4. 응답 생성 및 반환
        # ------------------------------
        indexing_pydantic = IndexingData(**calculated_indices)
        risk_pydantic = None  # 추후 사용자 위험도 평가 로직 추가 예정
        alerts_pydantic = []

        response_data = IndicesApiResponse(
            request_info=request_data_for_response,
            weather=WeatherData(
                temperature=(
                    weather_result.get("temperature")
                    if isinstance(weather_result, dict)
                    else None
                ),
                pressure=(
                    weather_result.get("pressure")
                    if isinstance(weather_result, dict)
                    else None
                ),
                humidity=(
                    weather_result.get("humidity")
                    if isinstance(weather_result, dict)
                    else None
                ),
                wind_speed=(
                    weather_result.get("wind_speed")
                    if isinstance(weather_result, dict)
                    else None
                ),
                temp_min=(
                    weather_result.get("min_temp")
                    if isinstance(weather_result, dict)
                    else None
                ),
                temp_max=(
                    weather_result.get("max_temp")
                    if isinstance(weather_result, dict)
                    else None
                ),
                city=region,
                error=(
                    weather_result.get("error")
                    if isinstance(weather_result, dict)
                    else None
                ),
            ),
            indexing_result=indexing_pydantic,
            risk_assessment=risk_pydantic,
            alerts=alerts_pydantic,
            error="; ".join(overall_error_parts) if overall_error_parts else None,
        )
        return jsonify(response_data.model_dump(exclude_none=True))

    except Exception as e:
        print(f"Critical error in /api/index processing: {e}")
        traceback.print_exc()
        error_response = IndicesApiResponse(
            request_info=request_data_for_response,
            error="An internal server error occurred during processing.",
        )
        return jsonify(error_response.model_dump(exclude_none=True)), 500
