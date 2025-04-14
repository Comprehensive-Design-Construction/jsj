from flask import Blueprint, request, jsonify
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

def _fetch_poison_data():
    
    error = ""

    cached_poison_data = get_food_poisoning_cache()
    food_poisoning_data = cached_poison_data.get("data", {})
    cache_last_updated = cached_poison_data.get("last_updated")
    print(
        f"Retrieved food poisoning data from cache (Last updated: {cache_last_updated})"
    )
    if not food_poisoning_data:
        print("Food poisoning cache is empty.")
        return None, None
    return food_poisoning_data, cache_last_updated
    

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
                        {"loc": ["query", "age"],
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
    
    # --- 6. 비동기 작업 실행 ---   
    try:
        print("Starting async tasks: Scraped Weather/Pressure")
        # 작업 정의
        scraped_weather_task = fetch_weather_and_pressure_data(
            validated_input.request_location.latitude,
            validated_input.request_location.longitude,
        )
        cached_poison_data = get_food_poisoning_cache()
        food_poisoning_data = cached_poison_data.get("data", {})
        cache_last_updated = cached_poison_data.get("last_updated")
        print(
            f"Retrieved food poisoning data from cache (Last updated: {cache_last_updated})"
        )
        
        

