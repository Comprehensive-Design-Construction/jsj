from pydantic import BaseModel, Field, validator
from typing import List, Optional, Any
from config.settings import settings


class LocationInput(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="위도")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="경도")


class UserInput(BaseModel):
    # 나이는 숫자로 받거나, 특정 문자열(예: 'child', 'adult', 'elderly')로 받을 수도 있음
    age: Optional[int] = Field(None, ge=0, description="사용자 나이")
    # 질병 목록은 문자열 리스트로 받음
    disease: List[str] = Field(default=[], description="사용자 보유 질병 목록")


class ShelterInput(BaseModel):
    # disaster_type의 기본값은 config에서 가져오도록 수정하거나 모델 내 유지
    disaster_type: str = Field(..., description="재난 유형 (예: EARTHQUAKE, FLOOD 등)")
    radius_km: float = Field(default=settings.DEFAULT_RADIUS_KM, gt=0)

    @validator("disaster_type")
    def validate_disaster_type(cls, v):
        # 유효성 검사 및 대문자 변환
        allowed_types = ["COLD_WAVE", "HEAT_WAVE", "FINE_DUST", "FLOOD", "EARTHQUAKE"]
        upper_v = v.upper()
        if upper_v not in allowed_types:
            raise ValueError(
                f"Invalid disaster_type. Allowed types are: {', '.join(allowed_types)}"
            )
        return upper_v


class EnvironmentInput(BaseModel):
    env_type: str = Field(..., description="환경 유형 (fine_dust, uv, flood trace)")

    @validator("env_type")
    def validate_env_type(cls, v):
        allowed_types = ["fine_dust", "uv", "flood_trace"]
        lower_v = v.lower()
        if lower_v not in allowed_types:
            raise ValueError(
                f"Invalid env_type. Allowed types are: {', '.join(allowed_types)}"
            )
        return lower_v


class ApiRequest(BaseModel):
    # API 요청 전체 구조 정의
    request_location: LocationInput
    user_input: UserInput
    # disaster_type을 직접 포함하도록 구조 변경 (ShelterInput 중첩 제거)
    disaster_type: str
    env_type: Optional[str] = None

    # ApiRequest 레벨에서 disaster_type 유효성 검사 (선택 사항)
    @validator("disaster_type")
    def validate_api_disaster_type(cls, v):
        allowed_types = ["COLD_WAVE", "HEAT_WAVE", "FINE_DUST", "FLOOD", "EARTHQUAKE"]
        upper_v = v.upper()
        if upper_v not in allowed_types:
            raise ValueError(
                f"Invalid disaster_type in ApiRequest. Allowed types are: {', '.join(allowed_types)}"
            )
        return upper_v

    @validator("env_type")
    def validate_api_env_type(cls, v):
        if v is None:
            return v

        allowed_types = ["fine_dust", "uv", "flood_trace"]
        lower_v = v.lower()
        if lower_v not in allowed_types:
            raise ValueError(
                f"Invalid env_type in ApiRequest. Allowed types are: {', '.join(allowed_types)}"
            )
        return lower_v
