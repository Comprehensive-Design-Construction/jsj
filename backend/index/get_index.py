import numpy as np
from datetime import datetime
from backend.config.weights_config import weights  # 절대경로 사용


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
    사용자 위험 상태 평가
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


def get_at_ali(
    pressure_value, temperature, humidity, wind_speed, min_tem, max_tem, user_types
):
    """
    체감온도와 ALI(천식, 폐질환 가능 지수) 계산.
    각 기상 요소를 등급화한 후 계산하며,
    user_types를 활용해 위험 상태도 판별.
    """
    # pressure_value는 문자열일 수 있으므로 float 변환 및 보정 적용
    if isinstance(pressure_value, str):
        lpressure = float(pressure_value.replace(",", "")) - 10.4
    else:
        lpressure = pressure_value - 10.4

    dtr = max_tem - min_tem  # 일교차
    ta = temperature
    rh = humidity
    v = wind_speed

    tw = compute_tw(ta, rh)
    time_slot = get_time_slot()
    apparent_temperature = merge_eftem(ta, v, rh, tw, user_types, time_slot)
    risk_status = check_risk(user_types, apparent_temperature)

    # ALI 계산 시 점수화를 위해 각 값을 등급화
    data = {
        "최저기온": min_tem,
        "일교차": dtr,
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


def get_TI(pressure_value, temperature, humidity, wind_speed, min_tem, max_tem):
    """
    뇌졸증 지수(TI) 및 등급 계산.
    각 기상 요소를 등급화하여 TI를 계산한 후, 등급(1~4)을 반환.
    """
    # pressure 값 변환
    if isinstance(pressure_value, str):
        ap_val = float(pressure_value.replace(",", ""))
    else:
        ap_val = pressure_value

    dtr_val = max_tem - min_tem
    lt_val = min_tem
    rh_val = humidity

    # dtr 등급 (동일 기준)
    if dtr_val >= 17.8:
        dtr_grade = 4
    elif dtr_val >= 14:
        dtr_grade = 3
    elif dtr_val >= 10.1:
        dtr_grade = 2
    else:
        dtr_grade = 1

    # 최저기온 등급
    if lt_val >= 10.7:
        lt_grade = 1
    elif lt_val >= -2.8:
        lt_grade = 2
    elif lt_val >= -12.4:
        lt_grade = 3
    else:
        lt_grade = 4

    # 상대습도 등급 (TI 기준)
    if rh_val >= 89.8:
        rh_grade = 4
    elif rh_val >= 78.8:
        rh_grade = 3
    elif rh_val >= 66.4:
        rh_grade = 2
    else:
        rh_grade = 1

    # 현지기압 등급
    if ap_val >= 1019.2:
        ap_grade = 4
    elif ap_val >= 1012.9:
        ap_grade = 3
    elif ap_val >= 1004.8:
        ap_grade = 2
    else:
        ap_grade = 1

    TI = 0.627 * lt_grade + 0.012 * dtr_grade + 0.276 * ap_grade + 0.085 * rh_grade
    if TI >= 3.213:
        TI_level = 1  # 매우 높음
    elif TI >= 2.7731:
        TI_level = 2  # 높음
    elif TI >= 1.3877:
        TI_level = 3  # 보통
    elif TI >= 1:
        TI_level = 4  # 낮음
    else:
        TI_level = None

    return TI, TI_level


def get_CI(pressure_value, temperature, humidity, wind_speed, min_tem, max_tem):
    """
    감기가능 지수(CI) 및 등급 계산.
    TI와 유사하게 기상 수치를 등급화하여 CI를 계산한 후,
    CI 기준에 따라 등급(1: 매우 높음, 2: 높음, 3: 보통, 4: 낮음)을 반환.

    다만, CI의 상대습도 등급은 다른 기준을 사용합니다.
    """
    # pressure 값 변환
    if isinstance(pressure_value, str):
        ap_val = float(pressure_value.replace(",", ""))
    else:
        ap_val = pressure_value

    dtr_val = max_tem - min_tem
    lt_val = min_tem
    rh_val = humidity

    # dtr 등급 (동일 기준 TI와 동일)
    if dtr_val >= 17.8:
        dtr_grade = 4
    elif dtr_val >= 14:
        dtr_grade = 3
    elif dtr_val >= 10.1:
        dtr_grade = 2
    else:
        dtr_grade = 1

    # 최저기온 등급 (TI와 동일)
    if lt_val >= 10.7:
        lt_grade = 1
    elif lt_val >= -2.8:
        lt_grade = 2
    elif lt_val >= -12.4:
        lt_grade = 3
    else:
        lt_grade = 4

    # 상대습도 등급 (CI 전용: 낮을수록 높은 등급)
    if rh_val >= 74:
        rh_grade = 1
    elif rh_val >= 59.3:
        rh_grade = 2
    elif rh_val >= 43.9:
        rh_grade = 3
    else:
        rh_grade = 4

    # 현지기압 등급 (TI와 동일)
    if ap_val >= 1019.2:
        ap_grade = 4
    elif ap_val >= 1012.9:
        ap_grade = 3
    elif ap_val >= 1004.8:
        ap_grade = 2
    else:
        ap_grade = 1

    CI = 0.46 * lt_grade + 0.177 * dtr_grade + 0.319 * ap_grade + 0.044 * rh_grade

    if CI >= 3.1316:
        CI_level = 1  # 매우 높음
    elif CI >= 2.6918:
        CI_level = 2  # 높음
    elif CI >= 1.4759:
        CI_level = 3  # 보통
    elif CI >= 1:
        CI_level = 4  # 낮음
    else:
        CI_level = None

    return CI, CI_level
