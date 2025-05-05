# core/indexing/get_data.py
import asyncio
import aiohttp  # 변경: aiohttp 임포트
from typing import Optional

# import requests # 제거: requests 대신 aiohttp 사용
from config.settings import settings
import logging  # 로깅 추가

logger = logging.getLogger(__name__)  # 로거 추가
url = "https://api.openweathermap.org/data/3.0/onecall"


async def fetch_weather_data(lat: float, lon: float) -> Optional[dict]:
    """
    OpenWeatherMap API를 사용해 날씨 데이터를 비동기로 가져옵니다. (aiohttp 사용)

    :param lat: 위도
    :param lon: 경도
    :return: {"weather": {날씨 정보}, "main": {온도, 기압, 습도 등}} 또는 None (실패 시)
    """
    api_key = settings.OPENWEATHERMAP_API_KEY
    if not api_key:
        logger.error(
            "OPENWEATHERMAP_API_KEY가 설정되지 않았습니다."
        )  # print 대신 logger 사용
        return None

    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": "metric",
        "lang": "kr",  # 결과 한국어 설명 추가 (선택 사항)
    }

    # 변경: aiohttp 사용
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(
                url, params=params, timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                response.raise_for_status()  # HTTP 오류 발생 시 예외 발생
                data = await response.json()

                # weather 정보 추출
                current_dict = data.get("current", {})
                weather_list = current_dict.get("weather", [])
                weather_info = weather_list[0] if weather_list else {}
                main_weather = weather_info.get("main", "")
                description = weather_info.get("description", "")

                daily_list = data.get("daily", {})
                daily_dict = daily_list[0] if daily_list else {}

                results = {
                    # 참고: 원본 코드와 동일한 구조 유지. 필요시 response_models.py 스키마 활용 가능
                    "weather": {
                        "main": main_weather,
                        "description": description,
                        "icon": weather_info.get(
                            "icon"
                        ),  # 아이콘 정보 추가 (선택 사항)
                    },
                    "main": {
                        "temp": current_dict.get("temp"),
                        "feels_like": current_dict.get("feels_like"),
                        "temp_min": daily_dict.get("temp", {}).get("min"),
                        "temp_max": daily_dict.get("temp", {}).get("max"),
                        "pressure": current_dict.get("pressure"),
                        "humidity": current_dict.get("humidity"),
                        "wind_speed": current_dict.get("wind_speed"),
                        "wind_deg": current_dict.get(
                            "wind_deg"
                        ),  # 풍향 정보 추가 (선택 사항)
                    },
                }

                # 필수 값 존재 여부 확인 (예시)
                if (
                    results["main"]["temp"] is None
                    or results["main"]["humidity"] is None
                ):
                    logger.warning(f"Weather data missing essential fields: {results}")
                    # 필수 값 없으면 None 반환 또는 기본값 처리 등 결정 필요
                    # return None # 여기서는 일단 데이터 반환

                return results

        except aiohttp.ClientResponseError as err:
            logger.error(
                f"OpenWeatherMap API request failed (aiohttp): {err.status} {err.message}"
            )
            return None
        except asyncio.TimeoutError:
            logger.error("OpenWeatherMap API request timed out (aiohttp).")
            return None
        except Exception as err:
            logger.exception(
                f"Unexpected error occurred fetching weather data (aiohttp): {err}"
            )  # 상세 로깅
            return None


if __name__ == "__main__":
    import time

    async def main():
        start_time = time.time()
        # data = await fetch_weather_data(37.589026, 127.003779) # 종로구청 좌표 예시
        data = await fetch_weather_data(35.198362, 126.851430)  # 광주광역시청 좌표 예시
        print(data)
        print("실행시간:", time.time() - start_time)

    asyncio.run(main())
