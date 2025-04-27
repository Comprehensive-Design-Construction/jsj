from pydantic import BaseModel, Field, validator, field_validator
from typing import List, Optional


class LocationInput(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="위도")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="경도")


class UserInput(BaseModel):
    age: Optional[int] = Field(None, ge=0, description="사용자 나이")
    disease: List[str] = Field(
        default=[],
        description="사용자 보유 질병 목록 (쉼표로 구분된 문자열 대신 리스트 사용)",
    )

    @field_validator("disease", mode="before")
    @classmethod
    def split_string(cls, v):
        if isinstance(v, str):
            return [item.strip() for item in v.split(",") if item.strip()]
        if isinstance(v, list):
            return [
                item.strip() for item in v if isinstance(item, str) and item.strip()
            ]
        return []


class IndexRequestParams(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    age: Optional[int] = Field(None, ge=0)
    disease: List[str] = Field(default=[])


class MapRequestParams(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    disaster_type: str = Field(..., description="재난 유형")
    radius_km: float = Field(gt=0, description="검색 반경(km)")
    force_refresh: bool = False

    @field_validator("disaster_type")
    @classmethod
    def validate_disaster_type(cls, v: str):
        allowed_types = {"COLD_WAVE", "HEAT_WAVE", "FINE_DUST", "FLOOD", "EARTHQUAKE"}
        upper_v = v.upper()
        if upper_v not in allowed_types:
            raise ValueError(
                f"Invalid disaster_type. Allowed: {', '.join(allowed_types)}"
            )
        return upper_v


class EnvMapRequestParams(BaseModel):
    env_type: str = Field(..., description="환경 유형")
    force_refresh: bool = False

    @field_validator("env_type")
    @classmethod
    def validate_env_type(cls, v: str):
        allowed_types = {"fine_dust", "uv", "flood_trace"}
        lower_v = v.lower()
        if lower_v not in allowed_types:
            raise ValueError(f"Invalid env_type. Allowed: {', '.join(allowed_types)}")
        return lower_v
