# app/routes/main.py
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
    MapApiResponse,
    WeatherData,  # 날씨 API 결과용
    RiskIndex,  # 사용자 위험도 평가용 (별도 정의/구현 필요)
    AlertInfo,
    IndexingData,  # 크롤링 기반 지수 결과용
)

# 서비스 임포트
from core.shelter.service import generate_shelter_map_html
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

# from core.alerting.service import check_and_send_alerts # 알림 서비스 (필요시 활성화)

# 캐시 임포트
from app.cache import get_food_poisoning_cache  # 캐시 경로 확인 필요
from config import settings

bp = Blueprint("main", __name__, url_prefix="/api")


@bp.route("/info", methods=["GET"])
async def get_info():
    """
    API 엔드포인트: 위치, 재난 유형 및 선택적 사용자 정보/반경을 받아
    크롤링 기반 날씨/지수, 식중독 정보, 대피소 지도 HTML 등을 반환합니다.
    """
    request_data_for_response = {}
    input_radius_km = settings.DEFAULT_RADIUS_KM
    validated_input: Optional[ApiRequest] = None  # 타입 힌트
    user_region_gu: Optional[str] = None

    try:
        # 1. 입력 파라미터 가져오기
        lat_str = request.args.get("latitude")
        lon_str = request.args.get("longitude")
        age_str = request.args.get("age")  # Optional
        diseases = request.args.getlist("disease")  # Optional, 없으면 빈 리스트 반환
        disaster_str = request.args.get(
            "disaster_type", default=settings.DEFAULT_DISASTER_TYPE
        )
        radius_str = request.args.get("radius_km")  # Optional

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
        if age_str is not None:  # age 파라미터가 제공된 경우에만 변환 시도
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

        if radius_str is not None:  # radius_km 파라미터가 제공된 경우에만 변환 시도
            try:
                input_radius_km = float(radius_str)
                if input_radius_km <= 0:
                    raise ValueError("Radius must be positive")
            except ValueError:
                raise ValidationError(
                    [
                        {
                            "loc": ["query", "radius_km"],
                            "msg": "value is not a valid positive float",
                        }
                    ],
                    ApiRequest,
                )

        # 4. Pydantic 모델 생성 및 유효성 검사 (disaster_type 포함)
        #    - LocationInput: lat, lon (필수)
        #    - UserInput: age (Optional), disease (Optional, default=[])
        #    - ApiRequest: disaster_type (필수, 모델 내 검증)
        validated_input = ApiRequest(
            request_location=LocationInput(latitude=lat, longitude=lon),
            user_input=UserInput(
                age=user_age, disease=diseases
            ),  # age=None, disease=[] 가능
            disaster_type=disaster_str,  # 모델의 validator가 처리
        )

        # 응답에 포함할 최종 요청 정보 (반경 포함)
        request_data_for_response = validated_input.model_dump()
        request_data_for_response["radius_km"] = input_radius_km

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
        print("Starting async tasks: Scraped Weather/Pressure, Shelter Map HTML...")
        # 작업 정의
        scraped_weather_task = fetch_weather_and_pressure_data(
            validated_input.request_location.latitude,
            validated_input.request_location.longitude,
        )
        shelter_map_task = generate_shelter_map_html(
            latitude=validated_input.request_location.latitude,
            longitude=validated_input.request_location.longitude,
            disaster_type=validated_input.disaster_type,
            radius_km=input_radius_km,  # 검증된 반경 값 사용
        )

        # 동시 실행 및 결과 기다리기
        results = await asyncio.gather(
            scraped_weather_task, shelter_map_task, return_exceptions=True
        )
        print("Async tasks finished.")

        # --- 7. 캐시에서 식중독 지수 데이터 가져오기 ---
        cached_poison_data = get_food_poisoning_cache()
        food_poisoning_data = cached_poison_data.get("data", {})
        cache_last_updated = cached_poison_data.get("last_updated")
        print(
            f"Retrieved food poisoning data from cache (Last updated: {cache_last_updated})"
        )

        # 결과 분리
        scraped_weather_result = results[0]
        shelter_map_html_result = results[1]

        # --- 8. 결과 처리 및 후속 동기 작업 ---
        indexing_pydantic: Optional[IndexingData] = None  # 타입 힌트
        risk_pydantic: Optional[RiskIndex] = None  # 타입 힌트
        alerts_pydantic: List[AlertInfo] = []  # 타입 힌트
        final_shelter_map_html: Optional[str] = None  # 타입 힌트
        overall_error_parts = []  # 오류 메시지 수집

        # 8.1 크롤링된 날씨 데이터 및 지수 계산 처리
        calculated_indices = {}
        if isinstance(scraped_weather_result, Exception) or (
            isinstance(scraped_weather_result, dict)
            and scraped_weather_result.get("error")
        ):
            error_msg = (
                scraped_weather_result.get("error")
                if isinstance(scraped_weather_result, dict)
                else str(scraped_weather_result)
            )
            print(f"Error fetching scraped weather/pressure data: {error_msg}")
            calculated_indices["error"] = f"날씨/기압 정보 조회 실패: {error_msg}"
            overall_error_parts.append("Scraped weather fetch failed.")
        elif isinstance(scraped_weather_result, dict):
            print("Calculating indices based on scraped weather data...")
            # UserInput 객체 자체를 전달하거나, model_dump()로 딕셔너리 전달
            apparent_temp_ali_res = calculate_apparent_temp_ali(
                scraped_weather_result, validated_input.user_input.model_dump()
            )
            stroke_res = calculate_stroke_index(scraped_weather_result)
            cold_res = calculate_cold_index(scraped_weather_result)
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

        # 계산된 지수 결과를 IndexingData 모델로 변환
        indexing_pydantic = IndexingData(**calculated_indices)

        # 8.3 지도 HTML 처리
        if isinstance(shelter_map_html_result, Exception):
            print(f"Error generating shelter map HTML: {shelter_map_html_result}")
            final_shelter_map_html = (
                f"<h2>지도 생성 중 오류 발생: {shelter_map_html_result}</h2>"
            )
            overall_error_parts.append(f"Shelter map generation failed.")
        elif isinstance(shelter_map_html_result, str):
            final_shelter_map_html = shelter_map_html_result
        else:
            final_shelter_map_html = (
                "<h2>알 수 없는 오류로 지도 생성에 실패했습니다.</h2>"
            )
            overall_error_parts.append(
                "Shelter map generation returned unexpected result."
            )

        # 8.4 위험도 평가 및 알림 생성 (별도 로직 필요)
        risk_pydantic = None  # 임시
        alerts_pydantic = []  # 임시

        # 9. 최종 응답 생성
        response_data = ApiResponse(
            request_info=request_data_for_response,
            weather=None,  # 크롤링 기반이므로 날씨 API 결과는 제외
            shelter_map_html=final_shelter_map_html,
            indexing_result=indexing_pydantic,  # 계산된 지수
            risk_assessment=risk_pydantic,  # 전체 위험도
            alerts=alerts_pydantic,
            error="; ".join(overall_error_parts) if overall_error_parts else None,
        )

        return jsonify(response_data.model_dump(exclude_none=True))

    except Exception as e:
        # 전체 프로세스 오류 처리
        print(f"Critical error in /api/info processing: {e}")
        traceback.print_exc()
        error_response = ApiResponse(
            request_info=request_data_for_response,
            error="An internal server error occurred during processing.",
        )
        # 실패 시에도 500 상태 코드와 함께 JSON 응답 반환
        return jsonify(error_response.model_dump(exclude_none=True)), 500
