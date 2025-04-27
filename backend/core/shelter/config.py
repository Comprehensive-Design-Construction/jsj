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

# GeoDataFrame 생성 시 사용할 위경도 컬럼명
DEFAULT_LON_COL = "경도"
DEFAULT_LAT_COL = "위도"
