import requests
import asyncio
import logging
from typing import Optional, Dict, Any
from config.settings import settings
import json


logger = logging.getLogger(__name__)

# 상수 정의
FINE_DUST_API_URL_TEMPLATE = "http://openAPI.seoul.go.kr:8088/{api_key}/json/ListAirQualityByDistrictService/1/51"


class FineDustError(Exception):
    """Custom exception for fine dust data fetching errors."""

    pass


async def fetch_fine_dust_data() -> Dict[str, Dict[str, Any]]:
    """
    서울시 열린데이터 광장 API를 사용하여 자치구별 대기질 정보를 비동기적으로 가져옵니다.

    Returns:
        Dict[str, Dict[str, Any]]: {측정소(구) 이름: 대기질 정보} 딕셔너리.
                                     대기질 정보 예: {"MAXINDEX": "좋음", "GRADE": "1", "PM10": 15, "PM25": 8}
    Raises:
        FineDustError: API 키가 없거나 API 요청/처리에 실패했을 때.
    """
    if not settings.FINE_DUST_API_KEY:
        logger.error("FINE_DUST_API_KEY is not configured in settings.")
        raise FineDustError("API key for fine dust is not configured.")

    url = FINE_DUST_API_URL_TEMPLATE.format(api_key=settings.FINE_DUST_API_KEY)
    results = {}
    default_value = "N/A"

    logger.info("Fetching fine dust data...")
    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None, lambda: requests.get(url, timeout=10)
        )
        response.raise_for_status()  # HTTP 오류 발생 시 예외 발생
        data = response.json()

        # API 응답 구조 확인 및 데이터 추출
        service_data = data.get("ListAirQualityByDistrictService")
        if not service_data or "row" not in service_data:
            logger.error(f"Unexpected API response structure: {data}")
            raise FineDustError("Unexpected API response structure for fine dust data.")

        rows = service_data["row"]
        if not rows:
            logger.warning("No fine dust data rows found in API response.")
            return {}

        for item in rows:
            district_name = item.get("MSRSTENAME")
            if not district_name:
                logger.warning(f"Missing district name (MSRSTENAME) in item: {item}")
                continue

            pm10_val = item.get("PM10")
            pm25_val = item.get("PM25")
            try:
                pm10 = int(pm10_val) if pm10_val is not None else None
                pm25 = int(pm25_val) if pm25_val is not None else None
            except (ValueError, TypeError):
                logger.warning(
                    f"Could not convert PM10/PM25 values for {district_name}: PM10={pm10_val}, PM25={pm25_val}"
                )
                pm10 = None
                pm25 = None

            results[district_name] = {
                "MAXINDEX": item.get("MAXINDEX", default_value),
                "GRADE": item.get("GRADE", default_value),
                "PM10": pm10,
                "PM25": pm25,
            }
        logger.info(
            f"Successfully fetched fine dust data for {len(results)} districts."
        )
        return results

    except requests.exceptions.Timeout:
        logger.error("Fine dust API request timed out.")
        raise FineDustError("API request timed out.")
    except requests.exceptions.RequestException as e:
        logger.error(f"Fine dust API request failed: {e}")
        raise FineDustError(f"API request failed: {e}")
    except (KeyError, TypeError, json.JSONDecodeError) as e:
        logger.error(f"Failed to parse fine dust API response: {e}")
        raise FineDustError(f"Failed to parse API response: {e}")
    except Exception as e:
        logger.exception(f"Unexpected error fetching fine dust data: {e}")
        raise FineDustError(f"An unexpected error occurred: {e}")
