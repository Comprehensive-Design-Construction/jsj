"""
모든 미세먼지 데이터를 가져옴.
"""

import requests
import asyncio
import os
from typing import Optional
from dotenv import load_dotenv

load_dotenv()


async def _fetch_fine_dust_sync() -> Optional[dict]:
    """
    :return: {gu: {미세먼지 데이터}}
    """
    FINE_DUST_API_KEY = os.getenv("FINE_DUST_API_KEY")
    results = {}

    url = f"http://openAPI.seoul.go.kr:8088/{FINE_DUST_API_KEY}/json/ListAirQualityByDistrictService/1/51"

    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None, lambda: requests.get(url, timeout=5)
        )
        response.raise_for_status()
        datas = response.json()["ListAirQualityByDistrictService"]["row"]

        for data in datas:
            res = {}
            default = "error"
            res["MAXINDEX"] = data.get("MAXINDEX", default)
            res["GRADE"] = data.get("GRADE", default)
            res["PM10"] = data.get("PM10", default)
            res["PM25"] = data.get("PM25", default)
            results[data["MSRSTENAME"]] = res
            results["error"] = None

        return results
    except requests.exceptions.RequestException as e:
        print(f"미세먼지 API request failed: {e}")
        results["error"] = "API request failed"

        return None
    except Exception as e:
        print(f"미세먼지: request 중 오류가 발생했습니다. {e}")
        results["error"] = "un expected Error"

        return None


if __name__ == "__main__":
    result = asyncio.run(_fetch_fine_dust_sync())
    print(result)
