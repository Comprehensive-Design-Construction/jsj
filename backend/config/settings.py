import os
from dotenv import load_dotenv

load_dotenv()

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY", "default_api_key")
# 대피소 데이터 루트 경로 설정
SHELTER_ROOT_PATH = os.getenv(
    "SHELTER_ROOT_PATH", "./backend/datasets/shelter"
)  # 원본 데이터 경로 예시
# OSMnx 캐시 설정 (선택 사항)
OSMNX_CACHE_FOLDER = os.getenv("OSMNX_CACHE_FOLDER", "./cache/osmnx")
OSMNX_USE_CACHE = os.getenv("OSMNX_USE_CACHE", "True").lower() == "true"

DEFAULT_LATITUDE = 37.568512
DEFAULT_LONGITUDE = 126.986988
DEFAULT_RADIUS_KM = 2.0
DEFAULT_DISASTER_TYPE = "HEAT_WAVE"

# osmnx 설정 적용
import osmnx as ox

ox.settings.cache_folder = OSMNX_CACHE_FOLDER
ox.settings.use_cache = OSMNX_USE_CACHE
