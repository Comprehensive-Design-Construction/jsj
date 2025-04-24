from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from pathlib import Path
import os

# 프로젝트 루트 디렉토리 설정 (settings.py 파일의 상위 디렉토리)
BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    # .env 파일 로드 설정
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",  # .env 파일 경로 명시
        env_file_encoding="utf-8",
        extra="ignore",  # .env 파일 외의 추가 필드 무시
    )

    # API Keys
    KAKAO_API_KEY: str = Field(..., alias="KAKAO_API_KEY")
    FINE_DUST_API_KEY: str = Field(..., alias="FINE_DUST_API_KEY")
    OPENWEATHERMAP_API_KEY: str = Field(..., alias="OPENWEATHERMAP_API_KEY")
    TMAP_API_KEY: str = Field(..., alias="TMAP_API_KEY")
    OPEN_DATA_API_KEY: str = Field(..., alias="OPEN_DATA_API_KEY")

    # Paths
    # 환경 변수가 없으면 기본 경로 사용
    SHELTER_ROOT_PATH: Path = Field(
        default=BASE_DIR / "datasets/shelter", alias="SHELTER_ROOT_PATH"
    )

    # Application Defaults (환경 변수 X)
    DEFAULT_LATITUDE: float = 37.568512
    DEFAULT_LONGITUDE: float = 126.986988
    DEFAULT_RADIUS_KM: float = 2.0
    DEFAULT_DISASTER_TYPE: str = "HEAT_WAVE"


settings = Settings()
