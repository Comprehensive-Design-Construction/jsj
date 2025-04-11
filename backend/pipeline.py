import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.index.crawling import get_values
from backend.index.get_index import get_at_ali, get_CI, get_TI


def get_all_index(latitude, longitude, user_types=[]):
    # URL 관련 처리
    pressure_value, temperature, humidity, wind_speed, min_tem, max_tem = get_values(
        latitude, longitude
    )

    # get_at_ali 결과 호출
    apparent_temperature, risk_status, ALI, ali_level = get_at_ali(
        pressure_value, temperature, humidity, wind_speed, min_tem, max_tem, user_types
    )
    CI, CI_level = get_CI(
        pressure_value, temperature, humidity, wind_speed, min_tem, max_tem
    )
    TI, TI_level = get_TI(
        pressure_value, temperature, humidity, wind_speed, min_tem, max_tem
    )

    print("Apparent Temperature:", apparent_temperature)
    print("Risk Status:", risk_status)
    print("ALI:", ALI)
    print("ALI Level:", ali_level)

    return apparent_temperature, risk_status, ALI, ali_level, CI, CI_level, TI, TI_level


if __name__ == "__main__":
    latitude = "37.5665"
    longitude = "126.9780"
    user_types = ["노인", "비닐하우스"]
    print(get_all_index(latitude, longitude, user_types))
