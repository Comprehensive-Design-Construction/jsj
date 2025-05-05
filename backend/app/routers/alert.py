from fastapi import APIRouter, HTTPException, Body
from typing import List, Optional
import logging

from app.schemas.request_models import RecommendationRequest
from app.schemas.response_models import RecommendationResponse

from core.alerting.alert import get_recommendation_for_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api")


@router.get("/recommendation", response_model=RecommendationResponse)
async def create_recommendation(request_data: RecommendationRequest = Body(...)):
    """
    지수 정보와 사용자 프로필을 받아 맞춤형 행동 요령을 생성하여 반환합니다.
    """
    try:
        recommendation_text = get_recommendation_for_user(
            index_type=request_data.index_type,
            index_level=request_data.index_level,
            age=request_data.age,
            working_type=request_data.working_type,
            diseases=request_data.diseases,
            is_pregnant=request_data.is_pregnant,
        )
        print(recommendation_text)

        if not recommendation_text or recommendation_text.startswith("❓"):
            # 매핑되는 조건이 없거나 알 수 없는 타입일 경우 기본 메시지 또는 에러 처리
            print(
                f"Warning: No specific recommendation found for {request_data.model_dump()}"
            )
            # 기본 메시지를 반환하거나, 클라이언트에게 알릴 내용 정의
            # recommendation_text = "현재 상황에 맞는 특별한 행동 요령은 없습니다. 일반적인 건강 관리에 유의하세요."
            # 또는 오류 응답 반환 고려
            # raise HTTPException(status_code=404, detail="Recommendation not found for the given conditions")

        return RecommendationResponse(recommendation=recommendation_text)

    except Exception as e:
        print(f"Error generating recommendation: {e}")
        # 실제 운영 환경에서는 에러 로깅 및 좀 더 상세한 오류 처리 필요
        raise HTTPException(
            status_code=500, detail="행동 요령 생성 중 오류가 발생했습니다."
        )
