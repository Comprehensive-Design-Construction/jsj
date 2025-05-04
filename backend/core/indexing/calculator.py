import numpy as np
from datetime import datetime
from typing import List, Optional, Dict, Any

from config.weights_config import weights


def _compute_tw(ta: float, rh: float) -> float:
    """습구온도 계산 공식"""
    # 입력 값 유효성 확인
    if not isinstance(ta, (int, float)) or not isinstance(rh, (int, float)):
        raise TypeError("Temperature (ta) and humidity (rh) must be numeric.")
    if not (0 <= rh <= 100):
        rh = max(0, min(100, rh))  # 값 제한

    # np.sqrt 내부 음수 방지 (rh >= 0 이면 발생 안 함)
    rh_term = rh + 8.313659
    if rh_term < 0:
        rh_term = 0  # 혹시 모를 경우 대비

    term1 = ta * np.arctan(0.151977 * np.sqrt(rh_term))
    term2 = np.arctan(ta + rh)
    term3 = np.arctan(rh - 1.67633)
    # np.power 음수 밑 방지 (rh >= 0)
    rh_power_term = rh
    if rh_power_term < 0:
        rh_power_term = 0
    term4 = (0.00391838 * (rh_power_term**1.5)) * np.arctan(0.023101 * rh)
    term5 = -4.686035

    return term1 + term2 - term3 + term4 + term5


def _get_time_slot() -> int:
    """현재 시간을 3, 6, 9, ... 24 형태로 반환."""
    current_hour = datetime.now().hour
    # 0~2시는 24시로 처리
    if 0 <= current_hour < 3:
        return 24
    else:
        return (current_hour // 3) * 3


def _weh(user_types: List[str], time_slot: int) -> float:
    """선택된 사용자 유형에 따른 시간대별 가중치 합산."""
    total_weight = 0.0
    for user_type in user_types:
        if user_type in weights:
            # 해당 시간대 가중치 가져오기 (없으면 0)
            total_weight += weights[user_type].get(time_slot, 0.0)
    return total_weight


def _merge_eftem(
    ta: float, v: float, rh: float, tw: float, user_types: List[str], time_slot: int
) -> Optional[float]:
    """현재 월에 따라 겨울/여름용 체감온도 계산."""
    if None in [ta, v, rh, tw]:  # 입력 값 중 하나라도 None이면 계산 불가
        print("Warning: Missing input value for effective temperature calculation.")
        return None

    current_month = datetime.now().month

    # 겨울철 (10월 ~ 4월)
    if current_month in [10, 11, 12, 1, 2, 3, 4]:
        # 기온 <= 10도, 풍속 >= 1.3 m/s 조건
        if ta <= 10 and v >= 1.3:
            eftem = (
                13.12
                + 0.6215 * ta
                - 11.37 * ((v * 3.6) ** 0.16)  # 풍속 m/s -> km/h 변환
                + 0.3965 * ((v * 3.6) ** 0.16) * ta
            )
            return round(eftem, 2)
        else:
            # 조건 미충족 시 현재 기온(ta)을 체감온도로 사용
            return round(ta, 2)
    # 여름철 (5월 ~ 9월)
    elif current_month in [5, 6, 7, 8, 9]:
        weight_result = _weh(user_types, time_slot)
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
        print(f"Error: Invalid current month {current_month}")
        return None


def _check_risk(user_types: List[str], eftem: Optional[float]) -> Optional[str]:
    """사용자 유형과 체감온도 기반 위험 상태 평가"""
    if eftem is None:
        return None

    # 사용자 유형 그룹 정의
    group1 = {"노인", "어린이", "취약거주환경"}
    group2 = {"농촌", "비닐하우스"}
    group3 = {"실외작업자"}

    risk_level = "안전"  # 기본값

    if any(ut in group1 for ut in user_types):  # 그룹1 (노인, 어린이 등) 기준
        if eftem >= 37:
            risk_level = "위험"
        elif 34 <= eftem < 37:
            risk_level = "경고"
        elif 31 <= eftem < 34:
            risk_level = "주의"
        elif 29 <= eftem < 31:
            risk_level = "관심"
    elif any(ut in group2 for ut in user_types):  # 그룹2 (농촌 등) 기준
        if eftem >= 38:
            risk_level = "위험"
        elif 35 <= eftem < 38:
            risk_level = "경고"
        elif 33 <= eftem < 35:
            risk_level = "주의"
        elif 29 <= eftem < 33:
            risk_level = "관심"
    elif any(ut in group3 for ut in user_types):
        if eftem >= 38:
            risk_level = "위험"
        elif 35 <= eftem < 38:
            risk_level = "경고"
        elif 33 <= eftem < 35:
            risk_level = "주의"
        elif 31 <= eftem < 33:
            risk_level = "관심"
    else:
        risk_level = "일반인"

    return risk_level


def _calculate_score(column_name: str, value: Optional[float]) -> Optional[int]:
    """서울 기준 항목별 점수 계산 (ALI, TI, CI 용)"""
    if value is None:
        return None

    # 기준값 정의
    criteria = {
        "최저기온": {  # ALI
            4: (-float("inf"), -8.1),
            3: (-8.1, 0.6),
            2: (0.6, 13.5),
            1: (13.5, float("inf")),
        },
        "최저기온_TI_CI": {  # ALI
            4: (-float("inf"), -12.4),
            3: (-12.4, -2.8),
            2: (-2.8, 10.7),
            1: (10.7, float("inf")),
        },
        "일교차": {  # ALI
            4: (12.5, float("inf")),
            3: (9.9, 12.5),
            2: (7.3, 9.9),
            1: (-float("inf"), 7.3),
        },
        "일교차_TI_CI": {
            4: (17.8, float("inf")),
            3: (14, 17.8),
            2: (10.1, 14),
            1: (-float("inf"), 10.1),
        },
        "현지기압": {  # ALI
            4: (1017.9, float("inf")),
            3: (1011.9, 1017.9),
            2: (1003.5, 1011.9),
            1: (-float("inf"), 1003.5),
        },
        "현지기압_TI_CI": {
            4: (1019.2, float("inf")),
            3: (1012.9, 1019.2),
            2: (1004.8, 1012.9),
            1: (-float("inf"), 1004.8),
        },
        "상대습도": {  # ALI 기준
            4: (-float("inf"), 37.4),
            3: (37.4, 50.0),
            2: (50.0, 65.9),
            1: (65.9, float("inf")),
        },
        "상대습도_TI": {  # TI 기준
            4: (89.8, float("inf")),
            3: (78.8, 89.8),
            2: (66.4, 78.8),
            1: (-float("inf"), 66.4),
        },
        "상대습도_CI": {  # CI 기준 (값이 낮을수록 등급 높음)
            4: (-float("inf"), 43.9),
            3: (43.9, 59.3),
            2: (59.3, 74.0),
            1: (74.0, float("inf")),
        },
    }

    if column_name not in criteria:
        print(f"Warning: Unknown column name '{column_name}' for score calculation.")
        return None

    for score, (lower, upper) in criteria[column_name].items():
        if lower <= value < upper or (upper == float("inf") and value >= lower):
            return score
    return None


def _check_ali_level(ali_score: Optional[float]) -> Optional[str]:
    """ALI 점수에 따른 등급 산출"""
    if ali_score is None:
        return None
    if ali_score >= 3.0525:
        return 1  # "매우 높음"
    elif 2.6452 <= ali_score < 3.0525:
        return 2  # "높음"
    elif 1.5354 <= ali_score < 2.6452:
        return 3  # "보통"
    elif 1.0 <= ali_score < 1.5354:
        return 4  # "낮음"
    else:
        return None  # "잘못된 값"


def _get_ti_level(ti_score: Optional[float]) -> Optional[int]:
    """TI 점수에 따른 등급(1~4) 산출"""
    if ti_score is None:
        return None
    if ti_score >= 3.213:
        return 1  # 매우 높음
    elif ti_score >= 2.7731:
        return 2  # 높음
    elif ti_score >= 1.3877:
        return 3  # 보통
    elif ti_score >= 1:
        return 4  # 낮음
    else:
        return None


def _get_ci_level(ci_score: Optional[float]) -> Optional[int]:
    """CI 점수에 따른 등급(1~4) 산출"""
    if ci_score is None:
        return None
    if ci_score >= 3.1316:
        return 1  # 매우 높음
    elif ci_score >= 2.6918:
        return 2  # 높음
    elif ci_score >= 1.4759:
        return 3  # 보통
    elif ci_score >= 1:
        return 4  # 낮음
    else:
        return None


# --- Main Calculation Functions ---


def calculate_apparent_temp_ali(
    weather_data: Dict[str, Optional[float]], user_input: Dict[str, Any]
) -> Dict[str, Any]:
    """체감온도와 ALI(천식, 폐질환 가능 지수) 계산"""
    results = {
        "apparent_temperature": None,
        "risk_status": None,
        "ali_score": None,
        "ali_level": None,
        "error": None,
    }
    try:
        # 입력 데이터 추출 및 유효성 검사
        pressure = weather_data.get("pressure")
        temp = weather_data.get("temp")
        humidity = weather_data.get("humidity")
        wind = weather_data.get("wind_speed")
        min_temp = weather_data.get("temp_min")
        max_temp = weather_data.get("temp_max")

        if None in [pressure, temp, humidity, wind, min_temp, max_temp]:
            results["error"] = (
                "Missing required weather data for ApparentTemp/ALI calculation."
            )
            return results

        # 사용자 유형 결정 로직
        user_types = []
        age = user_input.get("age")
        diseases = user_input.get("disease", [])
        # if age is not None:
        #     if age >= 65:
        #         user_types.append("노인")
        #     if age <= 7:
        #         user_types.append("어린이")
        # We Need To Do !!!!!!!!!!!!

        # 계산 수행
        tw = _compute_tw(temp, humidity)
        time_slot = _get_time_slot()
        apparent_temperature = _merge_eftem(
            temp, wind, humidity, tw, user_types, time_slot
        )
        results["apparent_temperature"] = apparent_temperature
        results["risk_status"] = _check_risk(user_types, apparent_temperature)

        # ALI 계산
        lpressure = pressure - 10.4  # 현지 기압 보정, 확인 필요 !!!!!!
        dtr = max_temp - min_temp  # 일교차

        score_min_temp = _calculate_score("최저기온", min_temp)
        score_dtr = _calculate_score("일교차", dtr)
        score_pressure = _calculate_score("현지기압", lpressure)
        score_humidity = _calculate_score("상대습도", humidity)  # ALI 기준 습도 점수

        if None in [score_min_temp, score_dtr, score_pressure, score_humidity]:
            results["error"] = (
                results.get("error") or ""
            ) + " Could not calculate all scores for ALI."
            # ALI 계산 불가하더라도 체감온도는 반환 가능
        else:
            ali_score = (
                0.443 * score_min_temp
                + 0.202 * score_dtr
                + 0.315 * score_pressure
                + 0.04 * score_humidity
            )
            results["ali_score"] = round(ali_score, 4)
            results["ali_level"] = _check_ali_level(ali_score)

        print(
            f"Calculated Apparent Temp: {results['apparent_temperature']}, Risk: {results['risk_status']}, ALI Score: {results['ali_score']}, ALI Level: {results['ali_level']}"
        )

    except TypeError as te:
        results["error"] = f"Calculation error (TypeError): {te}"
        print(results["error"])
    except Exception as e:
        results["error"] = f"Unexpected error in ApparentTemp/ALI calculation: {e}"
        print(results["error"])

    return results


def calculate_stroke_index(weather_data: Dict[str, Optional[float]]) -> Dict[str, Any]:
    """뇌졸증 지수(TI) 및 등급 계산"""
    results = {"stroke_index_score": None, "stroke_index_level": None, "error": None}
    try:
        pressure = weather_data.get("pressure")
        min_temp = weather_data.get("temp_min")
        max_temp = weather_data.get("temp_max")
        humidity = weather_data.get("humidity")

        if None in [pressure, min_temp, max_temp, humidity]:
            results["error"] = (
                "Missing required weather data for Stroke Index calculation."
            )
            return results

        # 등급 계산 (TI 기준 사용)
        dtr = max_temp - min_temp
        score_min_temp = _calculate_score("최저기온_TI_CI", min_temp)
        score_dtr = _calculate_score("일교차_TI_CI", dtr)
        score_pressure = _calculate_score(
            "현지기압_TI_CI", pressure
        )  # 보정 없는 기압 사용
        score_humidity = _calculate_score("상대습도_TI", humidity)

        ti_score = (
            0.627 * score_min_temp
            + 0.012 * score_dtr
            + 0.276 * score_pressure
            + 0.085 * score_humidity
        )
        results["stroke_index_score"] = round(ti_score, 4)
        results["stroke_index_level"] = _get_ti_level(ti_score)
        print(
            f"Calculated Stroke Index Score: {results['stroke_index_score']}, Level: {results['stroke_index_level']}"
        )

    except Exception as e:
        results["error"] = f"Unexpected error in Stroke Index calculation: {e}"
        print(results["error"])

    return results


def calculate_cold_index(weather_data: Dict[str, Optional[float]]) -> Dict[str, Any]:
    """감기가능 지수(CI) 및 등급 계산"""
    results = {"cold_index_score": None, "cold_index_level": None, "error": None}
    try:
        pressure = weather_data.get("pressure")
        min_temp = weather_data.get("temp_min")
        max_temp = weather_data.get("temp_max")
        humidity = weather_data.get("humidity")

        if None in [pressure, min_temp, max_temp, humidity]:
            results["error"] = (
                "Missing required weather data for Cold Index calculation."
            )
            return results

        # 등급 계산 (CI 기준 사용)
        dtr = max_temp - min_temp
        score_min_temp = _calculate_score("최저기온_TI_CI", min_temp)
        score_dtr = _calculate_score("일교차_TI_CI", dtr)
        score_pressure = _calculate_score("현지기압_TI_CI", pressure)
        score_humidity = _calculate_score("상대습도_CI", humidity)  # CI 기준 습도 점수

        ci_score = (
            0.46 * score_min_temp
            + 0.177 * score_dtr
            + 0.319 * score_pressure
            + 0.044 * score_humidity
        )
        results["cold_index_score"] = round(ci_score, 4)
        results["cold_index_level"] = _get_ci_level(ci_score)
        print(
            f"Calculated Cold Index Score: {results['cold_index_score']}, Level: {results['cold_index_level']}"
        )

    except Exception as e:
        results["error"] = f"Unexpected error in Cold Index calculation: {e}"
        print(results["error"])

    return results


def get_food_poisoning_risk_for_region(
    food_poisoning_data: Dict[str, Optional[str]], user_region_gu: str
) -> Optional[str]:
    """스크래핑된 식중독 지수 데이터에서 특정 구(gu)의 위험도를 반환"""
    if not food_poisoning_data or food_poisoning_data.get("error"):
        print("Food poisoning data is unavailable or contains error.")
        return None

    # user_region_gu 이름과 일치하는 키 찾기 (예: '강남구')
    risk = food_poisoning_data.get(user_region_gu)

    if risk:
        print(f"Found food poisoning risk for {user_region_gu}: {risk}")
        return risk
    else:
        print(
            f"Warning: Food poisoning risk data not found for district: {user_region_gu}"
        )
        return None  # 해당 구 정보 없음
