from flask import Blueprint, request, jsonify
import asyncio
from pydantic import ValidationError
import asyncio
import traceback
from datetime import datetime, timezone, timedelta
from typing import Optional, List

# 정확한 사용자 제공 모델 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import (
    IndicesApiResponse,
    WeatherData,  # 날씨 API 결과용
    RiskIndex,  # 사용자 위험도 평가용 (별도 정의/구현 필요)
    IndexingData,  # 크롤링 기반 지수 결과용
)

# 서비스 임포트
from core.indexing.crawler import (
    fetch_weather_and_pressure_data,
    _get_region_from_coords,  # 카카오 API 호출 포함
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
    API 엔드포인트: 위치, 재난 유형 및 선택적 사용자 정보/반경을 받아
    크롤링 기반 날씨/지수, 식중독 정보, 대피소 지도 HTML 등을 반환합니다.
    """
    request_data_for_response = {}
    validated_input: Optional[ApiRequest] = None
    user_region: Optional[str] = None
    user_gu: Optional[str] = None

    try:
        # 1. 입력 파라미터 가져오기
        lat_str = request.args.get("latitude")
        lon_str = request.args.get("longitude")
        age_str = request.args.get("age")
        diseases = request.args.getlist("disease")

        # 2. 필수 파라미터 (위도, 경도) 검증 및 변환
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

        # 3. 선택적 파라미터 (나이, 반경) 변환
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

        # 4. Pydantic 모델 생성 및 유효성 검사 (disaster_type 포함)
        validated_input = ApiRequest(
            request_location=LocationInput(latitude=lat, longitude=lon),
            user_input=UserInput(age=user_age, disease=diseases),
            disaster_type=settings.DEFAULT_DISASTER_TYPE,
        )

        request_data_for_response = validated_input.model_dump()

        # 5. 사용자 지역(구) 이름 얻기 (식중독 지수 조회용, 비동기)
        gu, region = await _get_region_from_coords(lat, lon)

    except ValidationError as e:
        # Pydantic 유효성 검사 실패
        return (
            jsonify({"error": "Invalid input parameters", "details": e.errors()}),
            400,
        )
    except Exception as e:
        # 기타 파싱 또는 지역 조회 오류
        print(f"Error during request parsing or getting region: {e}")
        traceback.print_exc()
        return (
            jsonify({"error": "Failed to process request input or determine region"}),
            400,
        )

    # --- 6. 작업 실행 ---
    try:
        print("Starting tasks: Scraped Weather/Pressure and Food Poisoning")
        # 작업 정의
        weather_and_pressure = fetch_weather_and_pressure_data(
            validated_input.request_location.latitude,
            validated_input.request_location.longitude,
        )
        weather_pydantic = WeatherData(
            temperature=weather_and_pressure["temperature"],
            pressure=weather_and_pressure["pressure"],
            humidity=weather_and_pressure["humidity"],
            wind_speed=weather_and_pressure["wind_speed"],
            temp_min=weather_and_pressure["min_temp"],
            temp_max=weather_and_pressure["max_temp"],
            city=region,
            error=weather_and_pressure["error"],
        )
        cached_poison_data = get_food_poisoning_cache()
        food_poisoning_data = cached_poison_data.get("data", {})
        cache_last_updated = cached_poison_data.get("last_updated")
        print(
            f"Retrieved food poisoning data from cache (Last updated: {cache_last_updated})"
        )

        indexing_pydantic: Optional[IndexingData] = None  # 타입 힌트
        risk_pydantic: Optional[RiskIndex] = None  # 타입 힌트
        overall_error_parts = []

        calculated_indices = {}
        if isinstance(weather_and_pressure, Exception) or (
            isinstance(weather_and_pressure, dict) and weather_and_pressure.get("error")
        ):
            error_msg = (
                weather_and_pressure.get("error")
                if isinstance(weather_and_pressure, dict)
                else str(weather_and_pressure)
            )
            print(f"Error fetching scraped weather/pressure data: {error_msg}")
            calculated_indices["error"] = f"날씨/기압 정보 조회 실패: {error_msg}"
            overall_error_parts.append("Scraped weather fetch failed.")
        elif isinstance(weather_and_pressure, dict):
            print("Calculating indices based on scraped weather data...")
            # UserInput 객체 자체를 전달하거나, model_dump()로 딕셔너리 전달
            apparent_temp_ali_res = calculate_apparent_temp_ali(
                weather_and_pressure, validated_input.user_input.model_dump()
            )
            stroke_res = calculate_stroke_index(weather_and_pressure)
            cold_res = calculate_cold_index(weather_and_pressure)
            calculated_indices.update(apparent_temp_ali_res)
            calculated_indices.update(stroke_res)
            calculated_indices.update(cold_res)
            # 오류 확인
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

        # 8.2 식중독 지수 처리
        if not food_poisoning_data:
            print("Food poisoning cache is empty.")
            calculated_indices["error"] = (
                calculated_indices.get("error") or ""
            ) + "; 식중독 정보 없음(캐시)"
            overall_error_parts.append("Food poisoning cache empty.")
        elif gu:  # 사용자 지역(구) 정보가 있을 때만 조회
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

        indexing_pydantic = IndexingData(**calculated_indices)
        risk_pydantic = None  # 임시
        alerts_pydantic = []

        response_data = IndicesApiResponse(
            request_info=request_data_for_response,
            weather=weather_pydantic,
            indexing_result=indexing_pydantic,
            risk_assessment=risk_pydantic,
            alerts=alerts_pydantic,
            error="; ".join(overall_error_parts) if overall_error_parts else None,
        )

        return jsonify(response_data.model_dump(exclude_none=True))

    except Exception as e:
        print(f"Critical error in /api/info processing: {e}")
        traceback.print_exc()
        error_response = IndicesApiResponse(
            request_info=request_data_for_response,
            error="An internal server error occurred during processing.",
        )
        # 실패 시에도 500 상태 코드와 함께 JSON 응답 반환
        return jsonify(error_response.model_dump(exclude_none=True)), 500
