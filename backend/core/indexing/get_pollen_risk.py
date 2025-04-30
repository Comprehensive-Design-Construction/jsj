import requests
import asyncio
import aiohttp
import logging
from typing import Optional, Dict, Any

# from config.settings import settings
import json

logger = logging.getLogger(__name__)

POLLEN_API_URL_TEMPLATE = "http://apis.data.go.kr/1360000/HealthWthrIdxServiceV3"


async def fetch_pollen_index() -> Dict[str, Optional[int]]:
    async with aiohttp.ClientSession() as session:
        params = {
            "dataType": "JSON",
            "ServiceKey": "KZGRQt4tnEQvqQAvTvrXVPGbnkQj9lBQPBGi2MKCxa8EHZzxuWd+dubBeG7SPFPQydjDRwuJuLo6R3A7aIHLAQ==",
            "areaNo": "1100000000",
            "time": "2025042418",
        }
        response = await asyncio.run(
            session.get(
                "http://apis.data.go.kr/1360000/HealthWthrIdxServiceV3/getOakPollenRiskIdxV3",
                params=params,
            )
        )
    data = response.json()
    print(data)


if __name__ == "__main__":
    asyncio.run(fetch_pollen_index())
