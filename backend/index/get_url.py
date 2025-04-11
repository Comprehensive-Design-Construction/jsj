from dotenv import load_dotenv
import os
import requests
import json
import pandas as pd
import datetime
from backend.config.region_config import region_ids  # 절대 경로 사용

load_dotenv()

"""
우선은 위 경도 고정, 추후 flask 등에서 좌표를 입력받을 수 있도록 수정.
"""


def get_region(latitude: str, longitude: str) -> str:
    KAKAO_API_KEY = os.getenv("KAKAO_API_KEY")
    url = f"https://dapi.kakao.com/v2/local/geo/coord2regioncode.JSON?x={longitude}&y={latitude}"
    headers = {"Authorization": "KakaoAK " + KAKAO_API_KEY}

    api_json = requests.get(url, headers=headers)
    full_address = json.loads(api_json.text)
    region = full_address["documents"][1]["region_3depth_name"]

    return region


def get_observatory(region: str) -> str:
    import os

    base_dir = os.path.dirname(__file__)
    csv_path = os.path.abspath(
        os.path.join(base_dir, "..", "..", "datasets", "weather", "observatory.csv")
    )

    df = pd.read_csv(csv_path)
    observatory = df[df["행정동"] == region]["가장 가까운 관측 소(구)"]
    return observatory.values[0]


def generate_weather_url(latitude: str, longitude: str) -> str:
    admin_code = 1171067000
    url = f"https://www.weather.go.kr/w/index.do#dong/{admin_code}/{latitude}/{longitude}/"
    return url


def generate_pressure_url(latitude: str, longitude: str) -> str:
    region = get_region(latitude, longitude)
    observatory = get_observatory(region)

    base_url = "https://www.weather.go.kr/w/observation/land/aws-obs.do"
    now = datetime.datetime.now()
    current_time = now.strftime("%Y.%m.%d%%20%H%%3A%M")  # 예: 2025.04.02%2021%3A57

    """상세 관측 URL 생성"""
    if observatory in region_ids:
        stnId = region_ids[observatory]
        final_url = f"{base_url}?db=MINDB_01M&tm={current_time}&stnId={stnId}&sidoCode=1100000000&sort=&config="
    else:
        print("해당 지역명은 데이터에 없습니다.")
        final_url = ""
    return final_url
