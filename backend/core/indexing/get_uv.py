import requests
from datetime import datetime
import asyncio
import json
import pandas as pd
from typing import Optional, Dict
from config.settings import settings
import logging
from pathlib import Path
import aiohttp

logger = logging.getLogger(__name__)

UV_API_BASE_URL = "http://apis.data.go.kr/1360000/LivingWthrIdxServiceV4/getUVIdxV4"
OBSERVATORY_UV_FILE = settings.DATASETS_DIR / "weather" / "observatory_UV.csv"


class UVDataError(Exception):
    """Custom exception for UV data fetching errors."""

    pass


async def fetch_uv_index() -> Dict[str, Optional[int]]:
    """
    공공데이터포털 API를 사용하여 지역별 자외선 지수(h0 값)를 비동기적으로 가져옵니다.

    Returns:
        Dict[str, Optional[int]]: {구 이름: 자외선 지수(h0)} 딕셔너리. 오류 발생 시 해당 구 값은 None.
    Raises:
        FileNotFoundError: 관측소 정보 파일을 찾을 수 없을 때.
        ValueError: 관측소 정보 파일 처리 중 오류 발생 시.
        UVDataError: API 호출 또는 데이터 처리 중 심각한 오류 발생 시.
    """
    logger.info(f"Attempting to load observatory UV data from: {OBSERVATORY_UV_FILE}")
    if not OBSERVATORY_UV_FILE.exists():
        logger.error(f"Observatory UV file not found: {OBSERVATORY_UV_FILE}")
        raise FileNotFoundError(f"Observatory UV file not found: {OBSERVATORY_UV_FILE}")

    try:
        df = pd.read_csv(OBSERVATORY_UV_FILE)
        code_gu = zip(df["행정구역코드"].values, df["2단계"].values)
    except Exception as e:
        logger.exception(f"Failed to load or process observatory UV file: {e}")
        raise ValueError(f"Failed to load or process observatory UV file: {e}")

    now = datetime.now()
    # API는 3시간 단위 예보 -> 현재 시간에 가장 가까운 과거 3시간 배수 시간 사용
    hour = (now.hour // 3) * 3
    time_str = f"{now.strftime('%Y%m%d')}{hour:02d}"
    logger.info(f"Fetching UV index for time: {time_str}")

    results = {}
    tasks = []

    async with aiohttp.ClientSession() as session:
        for code, gu in code_gu:
            params = {
                "dataType": "JSON",
                "ServiceKey": settings.OPEN_DATA_API_KEY,
                "areaNo": str(code),
                "time": time_str,
            }
            # 각 지역별 API 호출 작업을 비동기 task로 생성
            tasks.append(asyncio.create_task(fetch_single_uv(session, gu, params)))

        # 모든 task가 완료될 때까지 기다리고 결과 취합
        task_results = await asyncio.gather(*tasks)
        for gu, uv_index in task_results:
            results[gu] = uv_index

    if not results:
        raise UVDataError("Failed to fetch UV data for all regions.")

    return results


async def fetch_single_uv(
    session: aiohttp.ClientSession, gu: str, params: dict
) -> tuple[str, Optional[int]]:
    """지정된 지역의 UV 지수를 비동기적으로 가져옵니다."""
    logger.debug(f"Fetching UV index for {gu} (Code: {params.get('areaNo')})...")
    try:
        async with session.get(UV_API_BASE_URL, params=params, timeout=10) as response:
            response.raise_for_status()  # HTTP 에러 발생 시 예외 발생
            data = await response.json()

            items = (
                data.get("response", {}).get("body", {}).get("items", {}).get("item")
            )
            if items and isinstance(items, list) and items:
                uv_index_str = items[0].get("h0")
                if uv_index_str is not None and uv_index_str != "":
                    try:
                        uv_index = int(uv_index_str)
                        logger.info(f"Success: {gu} UV Index (h0) = {uv_index}")
                        return gu, uv_index
                    except ValueError:
                        logger.warning(
                            f"Could not convert UV index '{uv_index_str}' for {gu}."
                        )
                        return gu, None
                else:
                    logger.info(f"UV index ('h0') value not found or empty for {gu}.")
                    return gu, None
            else:
                logger.info(f"No UV index items found for {gu}.")
                return gu, None

    except asyncio.TimeoutError:
        logger.error(f"Request timed out for {gu} ({params.get('areaNo')}).")
        return gu, None
    except aiohttp.ClientResponseError as http_err:
        logger.error(
            f"HTTP error occurred for {gu} ({params.get('areaNo')}): {http_err.status} {http_err.message}"
        )
        return gu, None
    except aiohttp.ClientError as client_err:
        logger.error(
            f"Client request failed for {gu} ({params.get('areaNo')}): {client_err}"
        )
        return gu, None
    except json.JSONDecodeError:
        logger.error(
            f"Failed to decode JSON response for {gu} ({params.get('areaNo')})."
        )
        return gu, None
    except Exception as e:
        logger.exception(
            f"An unexpected error occurred for {gu} ({params.get('areaNo')}): {e}"
        )
        return gu, None
