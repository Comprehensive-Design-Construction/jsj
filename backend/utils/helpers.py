import pandas as pd
import os
import logging
import asyncio
import aiohttp
from functools import (
    lru_cache,
)

try:
    from backend.config.settings import settings
except ImportError:
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    DATASETS_DIR = os.path.join(PROJECT_ROOT, "datasets")


logger = logging.getLogger(__name__)
KAKAO_URL = "https://dapi.kakao.com/v2/local/geo/coord2regioncode.JSON"


@lru_cache(maxsize=1)  # 함수 결과를 캐시하여 파일 I/O 최소화 (최초 호출 시 1회만 실행)
def load_observatory_data() -> pd.DataFrame | None:
    """
    datasets/weather/observatory.csv 파일을 로드하고 전처리합니다.
    결과를 캐시하여 반복적인 파일 읽기를 방지합니다.
    """
    file_path = settings.DATASETS_DIR / "weather" / "observatory.csv"
    logger.info(f"Attempting to load observatory data from: {file_path}")

    if not os.path.exists(file_path):
        logger.error(f"Observatory file not found at: {file_path}")
        return None

    try:
        expected_cols = {
            "구": "ward",
            "행정동": "dong",
            "가장 가까운 관측 소(구)": "nearest_observatory",
            "비고": "etc",
        }

        try:
            df = pd.read_csv(file_path, encoding="utf-8")
        except UnicodeDecodeError:
            logger.warning("UTF-8 decoding failed, trying cp949...")
            df = pd.read_csv(file_path, encoding="cp949")

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


# 지역 정보 캐시
# 키: f"{lat:.5f}_{lon:.5f}", 값: (gu, region) 튜플
region_cache = {}
region_cache_limit = 1000  # 캐시 크기 제한
_region_cache_lock = asyncio.Lock()


async def get_region(lat: float, lon: float) -> tuple:
    """
    위도/경도 좌표를 행정구역 정보로 변환 (구, 동)
    결과를 캐싱하여 반복적인 API 호출 방지

    Args:
        lat: 위도
        lon: 경도

    Returns:
        tuple: (구 이름, 동 이름)
    """
    # 캐시 키 생성 (소수점 5자리까지만 고려)
    cache_key = f"{lat:.5f}_{lon:.5f}"

    # 캐시에서 값을 찾으면 바로 반환
    async with _region_cache_lock:
        if cache_key in region_cache:
            logger.debug(f"Region info for ({lat}, {lon}) found in cache")
            return region_cache[cache_key]

    url = f"{KAKAO_URL}?x={lon}&y={lat}"
    headers = {"Authorization": f"KakaoAK {settings.KAKAO_API_KEY}"}

    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers=headers) as response:
                if response.status != 200:
                    logger.error(f"Kakao API error: status code {response.status}")
                    return None, None

                full_address = await response.json()

                if not full_address.get("documents"):
                    logger.error(f"No region data found for coordinates ({lat}, {lon})")
                    return None, None

                gu = full_address["documents"][1]["region_2depth_name"]
                region = full_address["documents"][1]["region_3depth_name"]

                if gu and region:
                    async with _region_cache_lock:

                        region_cache[cache_key] = (gu, region)

                        # 캐시 크기 제한 (FIFO 방식)
                        if len(region_cache) > region_cache_limit:
                            try:
                                oldest_key = next(iter(region_cache))
                                region_cache.pop(oldest_key)
                            except StopIteration:
                                pass

                return gu, region
    except Exception as e:
        logger.error(f"Error getting region info: {e}")
        return None, None
