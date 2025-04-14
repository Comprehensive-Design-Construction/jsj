from flask import Blueprint, request, jsonify
from pydantic import ValidationError
import traceback
from typing import Optional, List

# 정확한 사용자 제공 모델 임포트
from app.schemas.request_models import ApiRequest, LocationInput, UserInput
from app.schemas.response_models import (
    MapApiResponse,
)

from core.shelter.service import generate_shelter_map_html

from config import settings

bp = Blueprint("map", __name__, url_prefix="/api")

@bp.route("/map", methods=["GET"])
async def get_map():
    """
    API 엔드포인트: 위치, 재난 유형 및 선택적 사용자 정보/반경을 받아
    크롤링 기반 날씨/지수, 식중독 정보, 대피소 지도 HTML 등을 반환합니다.
    """
    request_data_for_response = {}
    input_radius_km = settings.DEFAULT_RADIUS_KM
    validated_input: Optional[ApiRequest] = None
    
    try:
        lat_str = request.args.get("latitude")
        lon_str = request.args.get("longitude")
        disaster_str = request.args.get(
            "disaster_type", default=settings.DEFAULT_DISASTER_TYPE
        )
        radius_str = request.args.get("radius_km")

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
            
        validated_input = ApiRequest(
            request_location=LocationInput(latitude=lat, longitude=lon),
            user_input=UserInput(),  # age=None, disease=[] 가능
            disaster_type=disaster_str,  # 모델의 validator가 처리
        )

        request_data_for_response = validated_input.model_dump()
        request_data_for_response["radius_km"] = input_radius_km

    except ValidationError as e:
        return (
            jsonify({"error": "Invalid input parameters", "details": e.errors()}),
            400,
        )
    
    try:
        print("Starting tasks: Shelter Map HTML...")

        shelter_map_task = generate_shelter_map_html(
            latitude=validated_input.request_location.latitude,
            longitude=validated_input.request_location.longitude,
            disaster_type=validated_input.disaster_type,
            radius_km=input_radius_km,
        )

        result = shelter_map_task
        print("Shelter Map HTML generation complete.")
        
        final_shelter_map_html: Optional[str] = None
        overall_error_parts = []

        if isinstance(result, Exception):
            print(f"Error generating shelter map HTML: {result}")
            final_shelter_map_html = (
                f"<h2>지도 생성 중 오류 발생: {result}</h2>"
            )
            overall_error_parts.append(f"Shelter map generation failed.")
        elif isinstance(result, str):
            final_shelter_map_html = result
        else:
            final_shelter_map_html = (
                "<h2>알 수 없는 오류로 지도 생성에 실패했습니다.</h2>"
            )
            overall_error_parts.append(
                "Shelter map generation returned unexpected result."
            )
        
        response_data = MapApiResponse(
            request_info=request_data_for_response,
            shelter_map_html=final_shelter_map_html,
            error="; ".join(overall_error_parts) if overall_error_parts else None,
        )
        
        return jsonify(response_data.model_dump(exclude_none=True))
    
    except Exception as e:
        print(f"Error in /api/map: {e}")
        traceback.print_exc()
        return (
            jsonify({"error": "An internal server error occurred during processing."}),
            500,
        )
