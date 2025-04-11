import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.index.get_url import (
    get_region,
    get_observatory,
    generate_weather_url,
    generate_pressure_url,
)
from backend.index.get_at_ali import get_at_ali


def main():
    # 테스트용 임의 좌표 (서울)
    latitude = "37.5665"
    longitude = "126.9780"

    # URL 관련 처리
    region = get_region(latitude, longitude)
    print("Region:", region)

    observatory = get_observatory(region)
    print("Observatory:", observatory)

    weather_url = generate_weather_url(latitude, longitude)
    print("Weather URL:", weather_url)

    pressure_url = generate_pressure_url(latitude, longitude)
    print("Pressure URL:", pressure_url)

    # get_at_ali 결과 호출
    apparent_temperature, risk_status, ALI, ali_level = get_at_ali()

    print("Apparent Temperature:", apparent_temperature)
    print("Risk Status:", risk_status)
    print("ALI:", ALI)
    print("ALI Level:", ali_level)

    return apparent_temperature, risk_status, ALI, ali_level


if __name__ == "__main__":
    print(main())
