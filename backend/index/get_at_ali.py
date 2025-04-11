import numpy as np
from datetime import datetime
from backend.index.crawling import (
    get_values,
)  # 절대경로 사용, crawling.py가 backend/index 내에 있음
from backend.config.weights_config import weights  # 절대경로 사용

# 사용자의 환경 조건 (예시)
user_types = ["노인", "비닐하우스"]

# 상수: 위도, 경도 (추후 프론트 입력으로 변경 가능)
latitude = "37.575251"
longitude = "126.928484"


def compute_tw(ta, rh):
    """
    습구온도 계산 공식
    """
    return (
        ta * np.arctan(0.151977 * np.sqrt(rh + 8.313659))
        + np.arctan(ta + rh)
        - np.arctan(rh - 1.67633)
        + (0.00391838 * rh**1.5) * np.arctan(0.023101 * rh)
        - 4.686035
    )


def get_time_slot():
    """
    현재 시간을 3, 6, 9, ... 24 형태로 반환.
    """
    current_hour = datetime.now().hour
    return (current_hour // 3) * 3 or 24


def weh(user_types, time_slot):
    """
    선택된 사용자 환경에 따른 시간대별 가중치 합산.
    """
    total_weight = 0
    for user_type in user_types:
        if user_type in weights:
            total_weight += weights[user_type].get(time_slot, 0)
    return total_weight


def merge_eftem(ta, v, rh, tw, user_types, time_slot):
    """
    현재 월에 따라 겨울/여름용 체감온도를 계산.

    - 겨울 (10월 ~ 4월): 기온, 풍속 조건에 따라 winter 공식 적용
    - 여름 (5월 ~ 9월): summer 공식 적용 (개인별 가중치 포함)
    """
    current_month = datetime.now().month

    if current_month in [10, 11, 12, 1, 2, 3, 4]:
        if ta <= 10 and v >= 1.3:
            eftem = (
                13.12
                + 0.6215 * ta
                - 11.37 * ((v * 3.6) ** 0.16)
                + 0.3965 * ((v * 3.6) ** 0.16) * ta
            )
            return round(eftem, 2)
        else:
            return ta
    elif current_month in [5, 6, 7, 8, 9]:
        weight_result = weh(user_types, time_slot)
        eftem = (
            -0.2442
            + 0.55399 * tw
            + 0.45535 * ta
            - 0.0022 * (tw**2)
            + 0.00278 * tw * ta
            + weight_result
            + 3.0
        )
        return round(eftem, 2)
    else:
        raise ValueError("월은 1에서 12 사이의 값이어야 합니다.")


def check_risk(user_types, eftem):
    """
    사용자 위험 상태를 평가.
      - 노인, 어린이, 취약거주환경: 기준 A
      - 농촌, 비닐하우스: 기준 B
      - 기타: 기준 C
    """
    applicable_types = {"노인", "어린이", "취약거주환경"}
    applicable_types2 = {"농촌", "비닐하우스"}

    if any(user_type in applicable_types for user_type in user_types):
        if eftem >= 37:
            return "위험"
        elif 34 <= eftem < 37:
            return "경고"
        elif 31 <= eftem < 34:
            return "주의"
        elif 29 <= eftem < 31:
            return "관심"
        else:
            return "안전"
    elif any(user_type in applicable_types2 for user_type in user_types):
        if eftem >= 38:
            return "위험"
        elif 35 <= eftem < 38:
            return "경고"
        elif 33 <= eftem < 35:
            return "주의"
        elif 31 <= eftem < 33:
            return "관심"
        else:
            return "안전"
    else:
        if eftem >= 38:
            return "위험"
        elif 35 <= eftem < 38:
            return "경고"
        elif 33 <= eftem < 35:
            return "주의"
        elif 31 <= eftem < 33:
            return "관심"
        else:
            return "안전"


def calculate_score(column_name, value):
    """
    서울 기준 항목별 점수 계산.
    """
    criteria = {
        "최저기온": {
            4: (-float("inf"), -8.1),
            3: (-8.1, 0.6),
            2: (0.6, 13.5),
            1: (13.5, float("inf")),
        },
        "일교차": {
            4: (12.5, float("inf")),
            3: (9.9, 12.5),
            2: (7.3, 9.9),
            1: (-float("inf"), 7.3),
        },
        "현지기압": {
            4: (1017.9, float("inf")),
            3: (1011.9, 1017.9),
            2: (1003.5, 1011.9),
            1: (-float("inf"), 1003.5),
        },
        "상대습도": {
            4: (-float("inf"), 37.4),
            3: (37.4, 50.0),
            2: (50.0, 65.9),
            1: (65.9, float("inf")),
        },
    }

    for score, (lower, upper) in criteria[column_name].items():
        if lower <= value < upper:
            return score
    return None


def check_ali_level(ALI):
    """
    천식, 폐질환 가능 지수(ALI)에 따른 등급 산출.
    """
    if ALI >= 3.0525:
        return "매우 높음"
    elif 2.6452 <= ALI < 3.0525:
        return "높음"
    elif 1.5354 <= ALI < 2.6452:
        return "보통"
    elif 1.0 <= ALI < 1.5354:
        return "낮음"
    else:
        return "잘못된 값"


def get_at_ali():
    # 1. 기상 데이터 수집
    pressure_value, temperature, humidity, wind_speed, min_tem, max_tem = get_values(
        latitude, longitude
    )
    # 기압 값(문자열)을 숫자로 변환 (쉼표 제거 후 보정)
    lpressure = float(pressure_value.replace(",", "")) - 10.4
    drhythm = max_tem - min_tem  # 일교차 계산

    # 2. 체감온도 계산
    ta = temperature
    rh = humidity
    v = wind_speed

    tw = compute_tw(ta, rh)
    time_slot = get_time_slot()
    apparent_temperature = merge_eftem(ta, v, rh, tw, user_types, time_slot)
    risk_status = check_risk(user_types, apparent_temperature)

    # 3. 천식, 폐질환 가능 지수(ALI) 계산
    data = {
        "최저기온": min_tem,
        "일교차": drhythm,
        "현지기압": lpressure,
        "상대습도": rh,
    }
    scores = {key: calculate_score(key, value) for key, value in data.items()}
    ALI = (
        0.443 * scores["최저기온"]
        + 0.202 * scores["일교차"]
        + 0.315 * scores["현지기압"]
        + 0.04 * scores["상대습도"]
    )
    ali_level = check_ali_level(ALI)

    return apparent_temperature, risk_status, ALI, ali_level
