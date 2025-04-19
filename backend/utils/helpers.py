import requests
import json
import pandas as pd
import os
import logging
from dotenv import load_dotenv

load_dotenv()

from functools import (
    lru_cache,
)  # 간단한 캐싱을 위해 사용 (모듈 로딩 시 한 번만 파일 읽기)

# backend 폴더 기준으로 ../datasets/ 경로 접근
try:
    from backend.core.config import DATASETS_DIR
except ImportError:
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    DATASETS_DIR = os.path.join(PROJECT_ROOT, "datasets")


logger = logging.getLogger(__name__)

# --- 데이터 로딩 및 전처리 ---


@lru_cache(maxsize=1)  # 함수 결과를 캐시하여 파일 I/O 최소화 (최초 호출 시 1회만 실행)
def load_observatory_data() -> pd.DataFrame | None:
    """
    datasets/weather/observatory.csv 파일을 로드하고 전처리합니다.
    결과를 캐시하여 반복적인 파일 읽기를 방지합니다.
    """
    obs_file_path = os.path.join(DATASETS_DIR, "weather", "observatory.csv")
    logger.info(f"Attempting to load observatory data from: {obs_file_path}")

    if not os.path.exists(obs_file_path):
        logger.error(f"Observatory file not found at: {obs_file_path}")
        return None

    try:
        expected_cols = {
            "구": "ward",
            "행정동": "dong",
            "가장 가까운 관측 소(구)": "nearest_observatory",
            "비고": "etc",
        }

        try:
            df = pd.read_csv(obs_file_path, encoding="utf-8")
        except UnicodeDecodeError:
            logger.warning("UTF-8 decoding failed, trying cp949...")
            df = pd.read_csv(obs_file_path, encoding="cp949")

        # 필요한 컬럼만 선택 및 이름 변경
        df.rename(columns=expected_cols, inplace=True)

        # 필수 컬럼 존재 여부 확인
        required_cols = list(expected_cols.values())
        if not all(col in df.columns for col in required_cols):
            logger.error(
                f"Observatory CSV missing required columns. Found: {df.columns}. Expected: {required_cols}"
            )
            return None

        logger.info(f"Successfully loaded and processed {len(df)} observatories.")
        return df[["dong", "nearest_observatory"]]

    except Exception as e:
        logger.error(
            f"Error loading or processing observatory data: {e}", exc_info=True
        )
        return None


def get_region(lat: float, lon: float) -> str:
    KAKAO_API_KEY = os.getenv("KAKAO_API_KEY")
    url = f"https://dapi.kakao.com/v2/local/geo/coord2regioncode.JSON?x={lon}&y={lat}"
    headers = {"Authorization": "KakaoAK " + KAKAO_API_KEY}

    api_json = requests.get(url, headers=headers)
    full_address = json.loads(api_json.text)
    gu = full_address["documents"][1]["region_2depth_name"]
    region = full_address["documents"][1]["region_3depth_name"]

    return gu, region


# --- 핵심 기능: 좌표 -> 관측소 변환 ---


def convert_nearest_observation(lat: float, lon: float) -> str | None:
    """
    주어진 위도, 경도에서 가장 가까운 기상 관측소 코드를 찾아서 반환합니다.
    """
    obs_df = load_observatory_data()  # 캐시된 데이터 사용

    if obs_df is None or obs_df.empty:
        logger.error("Observatory data is not available for coordinate conversion.")
        return None

    region = get_region(lat, lon)
    observatory = obs_df[obs_df["dong"] == region]["nearest_observatory"].values[0]

    if observatory is not None:
        logger.info(
            f"Nearest observatory for ({lat}, {lon}) is {observatory} at {region}"
        )
        return str(observatory)
    else:
        logger.warning(f"Could not find any nearest observatory for ({lat}, {lon}).")
        return None


# --- 테스트 코드 (파일 직접 실행 시) ---
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    # 테스트 좌표 (예: 서울 시청 근처)
    test_lat, test_lon = 37.5665, 126.9780
    print(f"\nTesting coordinate conversion for: ({test_lat}, {test_lon})")
    print(convert_nearest_observation(test_lat, test_lon))

    # 캐시 키 생성 테스트
    print(f"\nTesting cache key generation for: ({test_lat}, {test_lon})")

    # 캐시 동작 확인 (두 번째 호출 시 파일 로드 로그가 없어야 함)
    print("\nCalling coordinate conversion again to test caching...")
    print(convert_nearest_observation(test_lat, test_lon))
