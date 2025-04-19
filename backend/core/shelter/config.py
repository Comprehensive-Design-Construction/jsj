import os
from dotenv import load_dotenv

load_dotenv()

TMAP_API_KEY = os.getenv("TMAP_API_KEY")

SHELTER_ROOT_PATH = os.getenv("SHELTER_ROOT_PATH", "./backend/datasets/shelter")

# TMAP API 엔드포인트
TMAP_PEDESTRIAN_ROUTE_URL = (
    "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1"
)

# 지원하는 재난 유형 목록
ALL_DISASTER_TYPES = ["COLD_WAVE", "HEAT_WAVE", "FINE_DUST", "FLOOD", "EARTHQUAKE"]

# 재난 유형별 대피소 파일 매핑
SHELTER_FILE_MAPPING = {
    "COLD_WAVE": "cold_wave.csv",
    "HEAT_WAVE": "heat_wave.csv",
    "FINE_DUST": "fine_dust_prepared.csv",
    "FLOOD": "flood_prepared.csv",
    "EARTHQUAKE": "earthquake.csv",
}

# GeoDataFrame 생성 시 사용할 위경도 컬럼명 (데이터에 따라 다를 수 있음)
DEFAULT_LON_COL = "경도"
DEFAULT_LAT_COL = "위도"

if TMAP_API_KEY == "YOUR_FALLBACK_TMAP_API_KEY":
    print(
        "경고: TMAP_APP_KEY가 설정되지 않았습니다. config.py 또는 환경 변수를 확인하세요."
    )
