import asyncio
import os
from typing import Optional
import requests
from dotenv import load_dotenv

load_dotenv()


async def _fetch_weather_data(lat: float, lon: float) -> Optional[dict]:
    """
    OpenWeatherMap API를 사용해 날씨 데이터를 가져옵니다.

    :param lat: 위도
    :param lon: 경도
    :return: {"weather": {날씨 정보}, "main": {온도, 기압, 습도 등}} 또는 None (실패 시)
    """
    api_key = os.getenv("OPENWEATHERMAP_API_KEY")
    if not api_key:
        print("OPENWEATHERMAP_API_KEY가 설정되지 않았습니다.")
        return None

    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": "metric",
    }

    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None, lambda: requests.get(url, params=params, timeout=5)
        )
        response.raise_for_status()
        data = response.json()

        # weather 정보 추출
        weather_list = data.get("weather", [])
        if weather_list:
            weather_info = weather_list[0]
            main_weather = weather_info.get("main", "error")
            description = weather_info.get("description", "error")
        else:
            main_weather, description = "error", "error"

        # main 데이터 추출
        main_data = data.get("main", {})
        results = {
            "weather": {
                "main": main_weather,
                "description": description,
            },
            "main": {
                "temp": main_data.get("temp", 0),
                "feels_like": main_data.get("feels_like", 0),
                "min_temp": main_data.get("temp_min", 0),
                "max_temp": main_data.get("temp_max", 0),
                "pressure": main_data.get("pressure", 0),
                "humidity": main_data.get("humidity", 0),
            },
        }

        # wind 정보 추가
        wind = data.get("wind", {})
        results["main"]["wind_speed"] = wind.get("speed", 0)

        return results

    except requests.exceptions.RequestException as err:
        print(f"OpenWeatherMap API request failed: {err}")
        return None
    except Exception as err:
        print(f"Unexpected error occurred: {err}")
        return None


if __name__ == "__main__":
    import time

    start_time = time.time()
    data = asyncio.run(_fetch_weather_data(37.589026, 127.003779))
    print(data)
    print("실행시간:", time.time() - start_time)
