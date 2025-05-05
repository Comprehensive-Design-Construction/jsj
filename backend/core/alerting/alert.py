from typing import Optional, List

AGE_THRESHOLD_ELDERLY = 65
AGE_THRESHOLD_CHILD = 18


def _map_user_profile_to_condition(
    age: Optional[int],
    working_type: Optional[str],
    diseases: List[str],
    is_pregnant: Optional[bool],
) -> int:
    """사용자 프로필 정보를 alarm.py의 condition 숫자로 매핑 (if/elif 우선순위)"""

    # 1. 임산부 체크 (최우선 순위 가정 - 논의 필요)
    if is_pregnant:
        return 6

    # 2. 나이 기반 체크 (노인/어린이)
    if age is not None:
        if age >= AGE_THRESHOLD_ELDERLY:
            return 1  # 노인
        if age < AGE_THRESHOLD_CHILD:
            return 2  # 어린이

    # 3. 근무 유형 체크
    if working_type:
        if working_type == "농촌":
            return 3
        if working_type == "비닐하우스":
            return 4
        if working_type == "실외작업자":
            return 5

    # 4. 기저 질환 체크 (질환 간 우선순위는 alarm.py 내부 로직 순서 따름 - 여기선 단순 존재 여부 확인)
    #    만약 특정 질환이 다른 질환보다 우선시되어야 한다면, 그 순서대로 체크
    if diseases:
        if "호흡기 질환" in diseases:  # 예시: 호흡기 질환 우선
            return 9
        if "심뇌혈관질환" in diseases:
            return 8
        if "당뇨병" in diseases:
            return 7

    return 0  # 일반인


def _get_raw_recommendation(
    index_type: str, index_level_str: str, condition: int
) -> str:
    response = ""
    # 지수 유형별 응답
    if index_type == "체감온도":
        if condition == 1:  # 노인
            if index_level_str == "위험":
                response = (  # source: 55, 56, 57
                    f"🚫 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 외출을 자제하고, 실내 또는 시원한 곳에서 쉬시기 바랍니다.\n"
                    "▪️ 독거노인 등은 온열질환 발생 가능성이 매우 높으니 안부전화 등 수시로 상태 점검하기 바랍니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 열사병 증상(구토, 고열 등) 나타나면 119에 신고하기 바랍니다.\n"
                )
            elif index_level_str == "경고":
                response = (  # source: 58, 59, 60, 61, 62, 63
                    f"⚠️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 높으니 냉방장치를 틀거나, 더위를 피할 수 있는 곳에서 쉬시기 바랍니다.\n"
                    "▪️ 독거노인 등은 온열질환 발생 가능성이 매우 높으니 안부전화 등 상태 점검하기 바랍니다.\n"
                    "▪️ 노약자는 온열질환 발생 가능성이 높으니 외출을 자제하고 휴식을 취하기 바랍니다.\n"
                    "▪️ 수분과 염분을 섭취하고 현기증, 메스꺼움 등을 느끼면 주변에 도움을 요청하기 바랍니다.\n"
                )
            elif index_level_str == "주의":
                response = (  # source: 64, 65, 66, 67
                    f"ℹ️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 노약자는 온열질환에 걸리기 쉬우니 건강관리에 유의하기 바랍니다.\n"
                    "▪️ 차량 안 온도가 높아지면 질식할 수 있으니 노약자를 혼자 차에 두지 않기 바랍니다.\n"
                    "▪️ 독거노인, 신체가 약한 사람 등은 온열질환에 걸리기 쉬우니 안부전화 등으로 상태 점검하기 바랍니다.\n"
                    "▪️ 온열질환에 걸리기 쉬우니 무더위쉼터와 같은 더위를 피할 수 있는 곳에서 쉬시기 바랍니다.\n"
                )
            elif index_level_str == "관심":
                response = (  # source: 68, 69, 70
                    f"✅ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환에 취약한 노약자는 30분 간격으로 쉬면서 야외 활동하기 바랍니다.\n"
                    "▪️ 온열질환에 취약한 노약자가 야외 활동을 할 때 불편해하는지 관찰하기 바랍니다.\n"
                    "▪️ 온열질환에 취약한 노약자는 야외 활동 시간을 줄이고, 수시로 상태 확인하기 바랍니다.\n"
                )
        elif condition == 2:  # 어린이
            if index_level_str == "위험":
                response = (  # source: 71, 72, 73
                    f"🚫 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 외출을 자제하고, 실내 또는 시원한 곳에서 쉬기 바랍니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 열사병 증상(구토, 고열 등) 나타나면 119에 신고하기 바랍니다.\n"
                )
            elif index_level_str == "경고":
                response = (  # source: 74, 75, 76, 77, 78, 79
                    f"⚠️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 높으니 냉방장치를 틀거나, 더위를 피할 수 있는 곳에서 쉬기 바랍니다.\n"
                    "▪️ 영유아는 온열질환 발생 가능성이 높으니 외출을 자제하고 휴식을 취하기 바랍니다.\n"
                    "▪️ 수분과 염분을 섭취하고 현기증, 메스꺼움 등을 느끼면 주변에 도움을 요청하기 바랍니다.\n"
                    "▪️ 온열질환 발생 가능성이 높으니 열사병 증상(구토, 고열 등) 나타나면 119에 바로 신고하기 바랍니다.\n"
                )
            elif index_level_str == "주의":
                response = (  # source: 80, 81, 82, 83
                    f"ℹ️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 영유아는 온열질환에 걸리기 쉬우니 건강관리에 유의하기 바랍니다.\n"
                    "▪️ 차량 안 온도가 높아지면 질식할 수 있으니 어린이를 혼자 차에 두지 않기 바랍니다.\n"
                    "▪️ 신체가 약한 사람 등은 온열질환에 걸리기 쉬우니 안부전화 등으로 상태 점검하기 바랍니다.\n"
                    "▪️ 온열질환에 걸리기 쉬우니 무더위쉼터와 같은 더위를 피할 수 있는 곳에서 쉬기 바랍니다.\n"
                )
            elif index_level_str == "관심":
                response = (  # source: 84, 85, 86
                    f"✅ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환에 취약한 영유아는 30분 간격으로 쉬면서 야외 활동하기 바랍니다.\n"
                    "▪️ 온열질환에 취약한 영유아가 야외 활동을 할 때 불편해하는지 관찰하기 바랍니다.\n"
                    "▪️ 온열질환에 취약한 영유아는 야외 활동 시간을 줄이고, 수시로 상태 확인하기 바랍니다.\n"
                )

        elif condition in [3, 4]:  # 농촌, 비닐하우스
            if index_level_str == "위험":
                response = (  # source: 87
                    f"🚫 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 한낮에는 모든 작업을 멈추고 충분히 쉬시기 바랍니다.\n"
                )
            elif index_level_str == "경고":
                response = (  # source: 88
                    f"⚠️ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 온열질환에 걸리기 쉬우니 아침·저녁에만 일하고, 충분한 휴식을 취하기 바랍니다.\n"
                )
            elif index_level_str == "주의":
                response = (  # source: 89
                    f"ℹ️ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 온열질환에 걸리기 쉬우니 수시로 수분 섭취, 장시간 농작업·나홀로 작업은 자제하기 바랍니다.\n"
                )
            elif index_level_str == "관심":
                response = (  # source: 90
                    f"✅ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 온열질환에 대비하여 통기성이 좋은 작업복 착용, 수분 섭취, 그늘에서 쉬시기 바랍니다.\n"
                )

        elif condition == 5:  # 실외 작업자
            if index_level_str == "위험":
                response = (  # source: 91, 92, 93, 94, 95
                    f"🚫 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 시원하고 깨끗한 물을 제공하고 한 시간마다 15분 이상씩 그늘에서 휴식하기 바랍니다.\n"
                    "▪️ 온열질환에 취약하거나 힘든작업을 하는 근로자에게 휴식시간 추가 배정하기 바랍니다.\n"
                    "▪️ 오후 2시~5시는 재난/안전 긴급조치 외 옥외작업 중지, 작업 시에도 충분한 휴식 부여를 권장합니다.\n"
                    "▪️ 옥외에서 작업할 때는 가급적 아이스 조끼, 아이스 팩 등 보냉장구를 사용하기 바랍니다.\n"
                    "▪️ 열사병 등의 온열질환에 취약한 사람에게는 옥외작업을 제한함을 권장합니다.\n"
                    "▪️ 더워도 안전모 안전대 등 개인 보호 장구 착용에 소홀하지 않도록 유의하기 바랍니다.\n"
                    "▪️ 집중력 저하로 인한 떨어짐·넘어짐 등 안전사고에 유의하기 바랍니다.\n"
                    "▪️ 작업자들끼리 서로 온열질환 증상 나타나는지 확인하고 응급상황 시 신속히 조치하기 바랍니다.\n"
                )
            elif index_level_str == "경고":
                response = (  # source: 96, 97, 98, 99, 100, 101, 102
                    f"⚠️ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 시원하고 깨끗한 물을 제공하고 한 시간마다 15분씩 그늘에서 휴식하기 바랍니다.\n"
                    "▪️ 작업자들끼리 서로 온열질환 증상 나타나는지 확인하고 응급상황 시 신속히 조치하기 바랍니다.\n"
                    "▪️ 오후 2시~5시에는 가급적 옥외작업 중지, 작업 시에는 충분한 휴식을 부여하기 바랍니다.\n"
                    "▪️ 옥외에서 작업할 때는 가급적 아이스 조끼, 아이스 팩 등 보냉장구 사용하기 바랍니다.\n"
                    "▪️ 온열질환에 취약하거나 힘든 작업을 하는 근로자에게 휴식시간 추가 배정하기 바랍니다.\n"
                    "▪️ 더워도 안전모 안전대 등 개인 보호 장구 착용에 소홀하지 않도록 유의 바랍니다.\n"
                    "▪️ 집중력 저하로 인한 떨어짐·넘어짐 등 안전사고에 유의 바랍니다.\n"
                    "▪️ 열사병 등 온열질환에 취약한 사람에게는 옥외작업을 제한함을 권장합니다.\n"
                )
            elif index_level_str == "주의":
                response = (  # source: 103, 104, 105, 106, 107, 108
                    f"ℹ️ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 시원하고 깨끗한 물을 제공하고 한 시간마다 10분씩 그늘에서 휴식하기 바랍니다.\n"
                    "▪️ 오후 2시부터 5시 사이는 옥외작업을 줄이거나 작업 시간대 조정을 권장합니다.\n"
                    "▪️ 옥외에서 작업할 때는 가급적 아이스 조끼, 아이스 팩 등 보냉장구 사용하기 바랍니다.\n"
                    "▪️ 온열질환에 취약하거나 힘든 작업을 하는 근로자에게 휴식시간 추가 배정하기 바랍니다.\n"
                    "▪️ 작업자들끼리 서로 온열질환 증상 나타나는지 확인하고 응급상황 시 신속히 조치하기 바랍니다.\n"
                    "▪️ 더워도 안전모 안전대 등 개인 보호 장구 착용에 소홀하지 않도록 유의하기 바랍니다.\n"
                    "▪️ 집중력 저하로 인한 떨어짐·넘어짐 등 안전사고에 유의하기 바랍니다.\n"
                )
            elif index_level_str == "관심":
                response = (  # source: 109, 110
                    f"✅ 현재 체감온도 '{index_level_str}' 단계입니다. \n"
                    "▪️ 시원하고 깨끗한 물을 마련하여 충분히 물을 마실 수 있게 하고, 쉴 수 있는 그늘 준비하기 바랍니다.\n"
                    "▪️ 온열질환에 취약한 근로자 및 작업강도가 높은 힘든 작업 사전 확인 및 구분하기 바랍니다.\n"
                )

        else:
            if index_level_str == "위험":
                response = (  # source: 71, 72, 73
                    f"🚫 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 외출을 자제하고, 실내 또는 시원한 곳에서 쉬기 바랍니다.\n"
                    "▪️ 온열질환 발생 가능성이 매우 높으니 열사병 증상(구토, 고열 등) 나타나면 119에 신고하기 바랍니다.\n"
                )
            elif index_level_str == "경고":
                response = (  # source: 74, 75, 76, 77, 78, 79
                    f"⚠️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환 발생 가능성이 높으니 냉방장치를 틀거나, 더위를 피할 수 있는 곳에서 쉬기 바랍니다.\n"
                    "▪️ 수분과 염분을 섭취하고 현기증, 메스꺼움 등을 느끼면 주변에 도움을 요청하기 바랍니다.\n"
                )
            elif index_level_str == "주의":
                response = (  # source: 80, 81, 82, 83
                    f"ℹ️ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 신체가 약한 사람 등은 온열질환에 걸리기 쉬우니 안부전화 등으로 상태 점검하기 바랍니다.\n"
                    "▪️ 온열질환에 걸리기 쉬우니 무더위쉼터와 같은 더위를 피할 수 있는 곳에서 쉬기 바랍니다.\n"
                )
            elif index_level_str == "관심":
                response = (  # source: 84, 85, 86
                    f"✅ 현재 체감온도 '{index_level_str}' 단계입니다.\n"
                    "▪️ 온열질환에 주의하여 야외활동하기 바랍니다"
                )
    elif index_type == "미세먼지":

        if condition == 1:  # 노인
            if index_level_str == "매우 나쁨":
                response = (  # source: 118
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 건강 악화 위험이 매우 높습니다.\n"
                    "▪️ 가급적 외출을 삼가고 실내에 머무르기 바랍니다.\n"
                )
            elif index_level_str == "나쁨":
                response = (  # source: 117
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 기관지 자극으로 기침·호흡곤란을 유발할 수 있습니다.\n"
                    "▪️ 가급적 외출을 삼가고 실내에 머무르기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 117
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 호흡이 불편할 수 있어 외출 시 주의가 필요합니다.\n"
                    "▪️ 혼자보다는 보호자와 동반하는 것을 권장합니다.\n"
                )
            elif index_level_str == "좋음":
                response = (  # source: 116
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 가벼운 외출이나 산책을 권장합니다.\n"
                )

        elif condition == 2:  # 어린이
            if index_level_str == "매우 나쁨":
                response = (  # source: 115
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 금지하고, 창문을 닫고 공기청정기 사용을 권장합니다.\n"
                )
            elif index_level_str == "나쁨":
                response = (  # source: 115
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고 실내 활동을 권장합니다.\n"
                    "▪️ 학교에서도 체육수업 제한하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 114
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 야외 활동 시 KF80 이상 마스크 착용 필요합니다.\n"
                    "▪️ 너무 과도한 야외활동은 자제하기 바랍니다.\n"
                )
            elif index_level_str == "좋음":
                response = (  # source: 114 # 오타 수정: 113은 일반인 위험
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 야외활동을 통한 적당한 운동을 하기 바랍니다.\n"
                )

        elif condition == 6:  # 임산부
            if index_level_str == "매우 나쁨":
                response = (  # source: 128
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 절대 금지. 실내 공기청정기를 사용하고 호흡곤란, 어지럼증 발생 시 바로 병원 연락, 응급대비 체계 마련이 필요합니다.\n"
                )
            elif index_level_str == "나쁨":
                response = (  # source: 127, 128
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출은 꼭 필요한 경우에만 최소화하고, 외출 전 공기질 확인하기 바랍니다.\n"
                    "▪️ 호흡곤란, 두통 등 증상 발생 시 즉시 휴식하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 127
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 반드시 KF80 이상 마스크 착용.\n"
                    "▪️ 장시간 외출은 삼가고 실내활동을 권장합니다.\n"  # PDF에 '실내활동을 권장.' 문구 추가
                )
            elif index_level_str == "좋음":
                response = (  # source: 126
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 및 가벼운 산책 가능하며 마스크 없이도 무방합니다.\n"
                    "▪️ 단 실내외 온도 차에는 주의 필요합니다.\n"
                )

        elif condition == 8:  # 기저질환자 (호흡기/심혈관 질환자 기준 통합 또는 분리)
            # 호흡기 질환자 기준으로 우선 적용
            if index_level_str == "매우 나쁨":
                # 호흡기: source 121, 심혈관: source 125
                response = (
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️공기질 악화가 심장에 부담을 줍니다. 흉통·가슴 답답함 발생 시 즉시 응급조치하기 바랍니다.\n"
                )
            elif index_level_str == "나쁨":
                # 호흡기: source 121, 심혈관: source 124
                response = (
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️외출 시 흉통, 어지럼증 발생할 수 있어 위험. 실내에서 휴식하며 상태를 관찰하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                # 호흡기: source 120, 심혈관: source 123
                response = (
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️과격한 활동은 피하고, 가슴 통증이 나타나면 즉시 휴식을 취하기 바랍니다.\n"
                )
            elif index_level_str == "좋음":
                # 호흡기: source 119, 심혈관: source 122
                response = (
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️외출 후 손씻기 등 개인 위생은 유지하고, 공사장 등 인적 먼지가 발생하는 곳은은 방문하지 않기 바랍니다.\n"
                )
        elif condition == 9:  # 기저질환자 (호흡기/심혈관 질환자 기준 통합 또는 분리)
            # 호흡기 질환자 기준으로 우선 적용
            if index_level_str == "매우 나쁨":
                # 호흡기: source 121, 심혈관: source 125
                response = (
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️호흡기 질환 증상 악화 가능성이 높아 외출 절대 금지. 증상 악화 시 병원 즉시 방문하기 바랍니다.\n"
                )

            elif index_level_str == "나쁨":
                # 호흡기: source 121, 심혈관: source 124
                response = (
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 피하고 실내 공기청정기 사용을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                # 호흡기: source 120, 심혈관: source 123
                response = (
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️외출 시 반드시 마스크 착용하고 흡입기 소지, 무리한 활동은 자제하기 바랍니다.\n"
                )
            elif index_level_str == "좋음":
                # 호흡기: source 119, 심혈관: source 122
                response = (
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 후 손씻기 등 개인 위생은 유지하고, 공사장 등 인적 먼지가 발생하는 곳은은 방문하지 않기 바랍니다.\n"
                )

        else:  # 일반인
            if index_level_str == "매우 나쁨":
                response = (  # source: 112
                    f"🚫 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고, 실내활동을 권장합니다.\n"
                    "▪️ 또한 실내 공기질 개선을 위해 공기청정기 사용을 권장합니다.\n"
                )
            elif index_level_str == "나쁨":
                response = (  # source: 112
                    f"⚠️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 자제하고, 불가피한 경우 KF94 이상 마스크 착용하기 바랍니다.\n"
                    "▪️ 실내활동을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 111
                    f"ℹ️ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외부 활동 시 마스크 착용, 장시간 외출은 피하기 바랍니다.\n"
                )
            elif index_level_str == "좋음":
                response = (  # source: 111
                    f"✅ 현재 미세먼지 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 및 가벼운 산책 가능하며 마스크 없이도 무방합니다.\n"
                )

    elif index_type == "심뇌혈관질환":
        if condition == 1:  # 노인
            if index_level_str == "매우 높음":
                response = (  # source: 7, 8
                    f"🚫 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 정기적으로 혈압과 혈당을 측정하고, 정상 수준을 유지하는 데에 신경쓰기 바랍니다.\n"
                    "▪️ 급격한 날씨 변화에 주의하고, 외출 시 보온에 신경쓰기 바랍니다.\n"
                    "▪️ 고혈압이나 뇌졸중 기왕력 있는 경우 각별한 주의가 필요합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 9
                    f"⚠️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 혈압을 꾸준히 측정하며, 정상 수준 유지에 신경쓰기 바랍니다.\n"
                    "▪️ 보온에 유의하며, 특히 새벽이나 밤 시간 외출 자제하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 10
                    f"ℹ️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 건강 관리를 철저히 하고, 규칙적인 운동과 식습관 조절하기 바랍니다.\n"
                    "▪️ 외출 시 갑작스러운 체온 변화에 대비하여 따뜻한 복장을 착용하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 11
                    f"✅ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 꾸준한 건강 관리와 영양 섭취, 가벼운 운동을 지속하기 바랍니다.\n"
                )

        elif condition == 2:  # 어린이
            if index_level_str == "매우 높음":
                response = (  # source: 1, 2, 3
                    f"🚫 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 외출 시 주의하기 바랍니다.\n"
                    "▪️ 특히 감기 증상에 민감하게 대처하고, 외출 후 손 씻기 등 위생 관리에 주의하기 바랍니다.\n"
                    "▪️ 건강 상태를 수시로 체크하고, 이상 증상 시 빠르게 조치하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 4
                    f"⚠️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 따뜻한 옷을 착용하여 체온 유지하기 바랍니다.\n"
                    "▪️ 추운 곳으로 외출할 경우 보호자와 반드시 동반하기 바랍니다.\n"
                    "▪️ 밤이나 새벽 외출은 피하고, 건강 상태를 주의 깊게 관찰하기 바랍니다.\n"  # PDF 줄바꿈 반영
                )
            elif index_level_str == "보통":
                response = (  # source: 5
                    f"ℹ️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 건강한 생활 습관을 유지하며, 규칙적인 운동과 건강한 식습관을 지키기 바랍니다.\n"
                    "▪️ 외출 시 기온 차에 대비하여 추가 의류를 준비하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 6
                    f"✅ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 건강 관리에 유의하며, 적절한 영양 섭취와 가벼운 운동을 권장합니다.\n"
                )

        elif condition == 6:  # 임산부
            if index_level_str == "매우 높음":
                response = (  # source: 12
                    f"🚫 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 주의하기 바랍니다.\n"
                    "▪️ 외출 시 따뜻한 복장을 유지하고, 무리한 활동을 자제하기 바랍니다.\n"
                    "▪️ 건강 상태를 주기적으로 체크하고, 이상 증상 시 빠른 조치하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 13
                    f"⚠️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 따뜻한 옷 착용하여 체온을 유지하기 바랍니다.\n"
                    "▪️ 추운 시간대 외출 자제, 건강 상태를 주의 깊게 관찰하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 14
                    f"ℹ️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 건강 관리를 철저히 하고, 규칙적인 운동과 함께 식습관을 조절하기 바랍니다.\n"
                    "▪️ 외출 시 기온 차에 대비하여 추가 의류를 준비하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 15
                    f"✅ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 건강 관리에 유의하고, 적절한 영양 섭취와 가벼운 운동을 권장합니다.\n"
                )

        elif condition == 8:
            if index_level_str == "매우 높음":
                response = (  # source: 16, 17
                    f"🚫 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 꾸준히 혈압, 혈당, 콜레스테롤 수치를 측정하고 정상 수준을 유지하도록 바랍니다.\n"
                    "▪️ 외출 및 환기에 주의하며, 급격한 날씨 변화에 노출되지 않도록 유의하기 바랍니다.\n"
                    "▪️ 고혈압 및 뇌졸중 기왕력 환자는 각별히 주의하기 바랍니다.\n"  # PDF 줄바꿈 반영
                )
            elif index_level_str == "높음":
                response = (  # source: 18
                    f"⚠️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 혈압을 꾸준히 측정하며 정상 상태를 유지하기 바랍니다.\n"
                    "▪️ 보온에 신경 쓰고, 특히 새벽이나 밤 외출을 자제하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 19
                    f"ℹ️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의하기 바랍니다.\n"
                    "▪️ 외출 시 체온 변화에 대비해 따뜻한 복장을 준비하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 20
                    f"✅ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속하기 바랍니다.\n"
                )
        else:  # 일반인 (condition 3, 4, 5 포함) - PDF에 해당 조건 없음
            if index_level_str == "매우 높음":
                response = (  # source: 16, 17
                    f"🚫 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 꾸준히 혈압, 혈당, 콜레스테롤 수치를 측정하고 정상 수준을 유지하도록 바랍니다.\n"
                    "▪️ 급격한 날씨 변화에 노출되지 않도록 외출 및 환기에 주의하기 바랍니다.\n"
                    "▪️ 고혈압 및 뇌졸중 기왕력 환자는 각별히 주의하기 바랍니다.\n"  # PDF 줄바꿈 반영
                )
            elif index_level_str == "높음":
                response = (  # source: 18
                    f"⚠️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 혈압을 꾸준히 측정하며 정상 상태를 유지하기 바랍니다.\n"
                    "▪️ 추운 곳으로 외출시 보온에 신경 쓰고, 특히 새벽이나 밤 외출을 자제하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 19
                    f"ℹ️ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의하기 바랍니다.\n"
                    "▪️ 외출 시 체온 변화에 대비해 따뜻한 복장을 준비하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 20
                    f"✅ 현재 심뇌혈관질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속하기 바랍니다.\n"
                )

    elif index_type == "천식질환":
        if condition == 1:  # 노인
            if index_level_str == "매우 높음":
                response = (  # source: 139
                    f"🚫 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 폐기능 저하 위험이 있으니 응급 상황에 대비하고 가족·의료진과 연락을 유지하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 138
                    f"⚠️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 호흡기 문제 악화 가능성 있으니 외출을 자제하기 바랍니다.\n"
                    "▪️ 무증상이어도 의료기관 상담을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 137
                    f"ℹ️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 호흡 불편함 있을 수 있어 외출시 동반자 필요. 과도한 활동을 자제하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 137
                    f"✅ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 큰 문제 없이 일상생활 가능하나 급격한 기온 변화에는 주의가 필요합니다.\n"
                )

        elif condition == 2:  # 어린이
            if index_level_str == "매우 높음":
                response = (  # source: 136
                    f"🚫 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 금지, 보호자 감독하에 실내에 머물기 바랍니다.\n"  # PDF 수정
                    "▪️ 증상 발생 시 병원에 즉시 방문하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 135
                    f"⚠️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 야외활동 금지 권장.\n"
                    "▪️ 체육 수업은 실내에서 실시, 증상 시 교사 및 보호자에게 바로 알리기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 134
                    f"ℹ️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 증상이 있으면 야외활동을 줄이고 흡입기 지참하기 바랍니다.\n"  # PDF 수정
                    "▪️ 보호자 지도가 필요합니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 133
                    f"✅ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소처럼 놀이와 체육활동 가능.\n"
                    "▪️ 천식 이력이 있다면 흡입제 점검을 요합니다.\n"
                )

        elif condition == 6:  # 임산부
            if index_level_str == "매우 높음":
                response = (  # source: 150
                    f"🚫 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 천식 유발 가능성 높아 외출 금지.\n"
                    "▪️ 증상 발생 시 바로 병원 연락, 응급대비 체계 마련하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 149
                    f"⚠️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 가벼운 증상이라도 즉시 진료 고려.\n"
                    "▪️ 무리한 집안일, 운동은 피하고 실내 공기 질 관리 신경쓰기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 148
                    f"ℹ️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 미세먼지 및 알레르기 유발물질 주의하기 바랍니다.\n"
                    "▪️ 약한 기침, 숨참 증상 나타나면 즉시 휴식하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 147
                    f"✅ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소처럼 생활 가능하나 이력이 있다면 흡입기·약 점검이 필요합니다.\n"
                    "▪️ 무리한 활동은 피하는 것이 좋습니다.\n"
                )

        elif condition == 8:  # 기저질환자 (호흡기/심혈관 질환자 기준 통합 또는 분리)
            # 호흡기 질환자 기준으로 우선 적용
            if index_level_str == "매우 높음":
                # 호흡기: source 143, 심혈관: source 146
                response = (
                    f"🚫 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 심정지 등 위험 급증. 가슴통증, 호흡 곤란 시 즉시 응급실로 이동하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                # 호흡기: source 142, 심혈관: source 145
                response = (
                    f"⚠️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 실내에서 휴식하며, 숨참·가슴 압박감 있을 경우 병원 방문을 준비하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                # 호흡기: source 141, 심혈관: source 144
                response = (
                    f"ℹ️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 활동 시 숨참 또는 피로감 느낄 수 있어 무리하지 말고 휴식을 병행하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                # 호흡기: source 140, 심혈관: source 144
                response = (
                    f"✅ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 혈압·맥박 체크를 주기적으로 하기 바랍니다.\n"
                )

        else:  # 일반인 (condition 3, 4, 5 포함)
            if index_level_str == "매우 높음":
                response = (  # source: 132
                    f"🚫 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 실외 활동 피하고 실내에서 지내야 합니다.\n"  # PDF 수정
                    "▪️ 증상 발생 시 진료가 필요합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 131
                    f"⚠️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 시 마스크 착용 권장, 실내 공기 질 관리하고 실내 활동을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 130
                    f"ℹ️ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 민감성 천식이 있다면 실외 활동 조절, 무리한 운동 자제하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 129
                    f"✅ 현재 천식질환 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 천식 관련 영향 없음. 평상시와 동일하게 실내외 활동이 가능합니다.\n"
                )

    elif index_type == "감기가능":
        if condition == 1:  # 노인
            if index_level_str == "매우 높음":
                response = (  # source: 51, 52
                    f"🚫 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고, 난방기 사용 시 실내 습도를 유지하기 바랍니다.\n"
                    "▪️ 무리한 운동·산책을 피하기 바랍니다.\n"
                    "▪️ 따뜻한 물을 자주 섭취하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 53
                    f"⚠️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 활동 후 충분한 휴식을 취하기 바랍니다.\n"
                    "▪️ 온열 내의 착용을 권장합니다.\n"
                    "▪️ 실내 공기를 자주 환기하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 54
                    f"ℹ️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출 전후 따뜻한 차를 마시기 권장합니다.\n"
                    "▪️ 저녁 시간 외출은 지양하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 54
                    f"✅ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 감기 증상 시 조기에 진료받기 바랍니다.\n"
                    "▪️ 충분한 수면 및 영양 섭취를 유지하기 바랍니다.\n"
                )

        elif condition == 2:  # 어린이
            if index_level_str == "매우 높음":
                response = (  # source: 47, 48
                    f"🚫 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고, 실내 놀이로 대체하기 바랍니다.\n"
                    "▪️ 목도리, 모자, 장갑 착용에 철저하기 바랍니다.\n"
                    "▪️ 보호자는 어린이의 젖은 옷을 갈아입히기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 49
                    f"⚠️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고, 실내 놀이를 하기 바랍니다.\n"  # PDF 내용 추가
                    "▪️ 과격한 운동을 자제하기 바랍니다.\n"
                    "▪️ 충분한 수면시간 확보하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 50
                    f"ℹ️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 규칙적인 생활습관을 유지하기 바랍니다.\n"
                    "▪️ 보호자께서는 아이들에게 손 씻기, 마스크 쓰기 교육을 하기 바랍니다.\n"
                    "▪️ 외출 전후로 체온을 체크하기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 51
                    f"✅ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 체온 관찰 습관화하기 바랍니다.\n"
                    "▪️ 보호자께서는 개인위생 관리 철저 안내하기 바랍니다.\n"
                )

        elif condition == 6:  # 임산부
            if index_level_str == "매우 높음":
                response = (  # source: 44
                    f"🚫 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 외출을 자제하고, 무리한 가사/활동 피하기 바랍니다.\n"
                    "▪️ 외출 시 따뜻한 복장을 착용하고, 특히 배/허리 보온에 유의하기 바랍니다.\n"
                    "▪️ 외출 후 따뜻한 물로 샤워 및 충분한 휴식을 취하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 45
                    f"⚠️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 수면과 영양 섭취 균형 유지에 유의하기 바랍니다.\n"
                    "▪️ 실내 적정 온·습도 관리에 유의하기 바랍니다.(가습기 활용)\n"
                    "▪️ 비타민 C 섭취를 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 46
                    f"ℹ️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 산책은 햇볕 좋은 시간에 짧게 하는 것을 권장합니다.\n"
                    "▪️ 손씻기 등 위생관리 강화에 유의하기 바랍니다.\n"
                    "▪️ 따뜻한 물을 자주 마시기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 47
                    f"✅ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 감기 초기증상에 민감하게 대처하기 바랍니다.\n"
                    "▪️ 가벼운 실내 스트레칭을 권장합니다.\n"
                )

        else:  # 일반인 (condition 3, 4, 5, 7 포함)
            if index_level_str == "매우 높음":
                response = (  # source: 39, 40
                    f"🚫 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 가급적 외출을 자제하고 과로에 유의하기 바랍니다.\n"
                    "▪️ 외출 시 마스크, 목도리 등을 착용하여 몸을 따뜻하게 하고 체온을 유지하기 바랍니다.\n"
                    "▪️ 머리나 몸이 물에 젖어있을 경우 몸을 충분히 말린 후 외출하기 바랍니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 41
                    f"⚠️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 충분한 수면 취하고, 과로에 유의하기 바랍니다.\n"
                    "▪️ 체온을 유지하고 실내 적정한 온습도 유지하기 바랍니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 42
                    f"ℹ️ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 규칙적인 생활습관을 유지하기 바랍니다.\n"
                    "▪️ 수분을 적절히 섭취하고, 외출 후 손과 발을 깨끗이 씻기 바랍니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 43
                    f"✅ 현재 감기 가능성이 '{index_level_str}' 단계입니다. \n"
                    "▪️ 평소 건강관리 유의하기 바랍니다.\n"
                )

    elif index_type == "식중독":
        # PDF 파일에 식중독 지수 관련 내용 없음. 기존 코드 유지.
        if index_level_str == "위험":
            response = (
                f"🚫 현재 식중독 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                "▪️ 식중독 발생가능성이 매우 높으므로 식중독 예방에 각별한 경계가 요망됩니다.\n"  # 어투 수정
                "▪️ 설사, 구토 등 식중독 의심 증상이 있으면 의료기관을 방문하여 의사 지시에 따르기 바랍니다.\n"
                "▪️ 식중독 의심 환자는 식품 조리 참여에 즉시 중단하여야 합니다.\n"
            )
        elif index_level_str == "경고":
            response = (
                f"⚠️ 현재 식중독 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                "▪️ 식중독 발생가능성이 높으므로 식중독 예방에 경계가 요망됩니다.\n"  # 어투 수정
                "▪️ 조리도구는 세척, 소독 등을 거쳐 세균오염을 방지하고 유통 기한, 보관방법 등을 확인하여 음식물 조리. 보관에 각별히 주의하여야 합니다다.\n"
            )
        elif index_level_str == "주의":
            response = (
                f"ℹ️ 현재 식중독 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                "▪️ 식중독 발생가능성이 중간 단계이므로 식중독예방에 주의가 요망됩니다.\n"  # 어투 수정
                "▪️ 조리음식은 중심부까지 75℃(어패류 85℃)로 1분 이상 완전히 익히고 외부로 운반할 때에는 가급적 아이스박스 등을 이용하여 10℃이하에서 보관 및 운반하기 바랍니다.\n"
            )
        elif index_level_str == "관심":

            response = (
                f"✅ 현재 식중독 발생 가능성이 '{index_level_str}' 단계입니다. \n"
                "▪️ 식중독 발생 가능성은 낮으나 식중독 예방에 지속적인 관심이 요망됩니다.\n"  # 어투 수정
                "▪️ 화장실 사용 후, 귀가 후, 조리 전에 손 씻기를 생활화하기 바랍니다.\n"
            )

    elif index_type == "자외선":  # <<< 자외선 지수 처리 추가
        if condition == 1:  # 노인
            if index_level_str == "위험":
                response = (  # source: 33
                    f"🚫 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부화상을 입을 수 있어 외출 금지를 권고합니다.\n"
                    "▪️ 외부 활동(은행 업무, 장보기 등)이 필요한 경우 자녀/보호자의 대리 활동을 권장합니다.\n"
                    "▪️ 실내에서도 자외선 차단 커튼/차광막 설치를 통해 외부 자외선 차단이 필요합니다.\n"
                    "▪️ 냉방을 유지하고 수분 섭취 유도가 필요합니다.\n"
                )
            elif index_level_str == "매우 높음":
                response = (  # source: 34
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부 화상을 입을 수 있어 외출 자제를 권장합니다.\n"
                    "▪️ 외출 시 긴소매 옷, 모자, 선글라스를 착용하고 자외선 차단제를 2시간 간격으로 정기적으로 발라야 합니다.\n"  # 일반 사용자 내용 참고 적용
                    "▪️ 자외선 차단 필름이 설치된 장소 방문을 추천합니다.\n"
                    "▪️ 복용 중인 약이 있는 경우 광과민성 부작용 확인 후 의사와 상담을 권장합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 35, 36
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 1~2시간 내 피부 화상을 입을 수 있어 한낮에는 그늘에 머물러야 합니다.\n"
                    "▪️ 외출 시 긴 소매 옷, 모자, 선글라스를 착용하고 자외선 차단제를 정기적으로 발라야 합니다.\n"
                    "▪️ 백내장, 피부염 위험이 증가하므로 병원 예약 시 오전 10시 이전, 오후 3시 이후 시간을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 37, 38
                    f"ℹ️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 2~3시간 내 햇볕에 지속적 노출 시에 피부 화상을 입을 수 있으므로 주의가 필요합니다.\n"
                    "▪️ 외출 시 모자, 선글라스를 착용하고 자외선 차단제를 발라야 합니다.\n"
                    "▪️ 햇빛 노출 후 피부 가려움증을 관찰하고, 고혈압/당뇨약 복용 중인 경우 광과민 반응을 체크하여야 합니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"✅ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕 노출에 대한 특별한 보호 조치가 필요하지 않고 자유로운 외출이 가능합니다.\n"
                    "▪️ 그러나 햇볕에 민감한 피부를 가진 사람은 자외선 차단제를 바르는 것을 권장합니다.\n"
                )

        elif condition == 2:  # 어린이
            if index_level_str == "위험":
                response = (  # source: 28, 29
                    f"🚫 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부화상을 입을 수 있어 외출 금지 수준입니다.\n"
                    "▪️ 학교/유치원에서도 실내 활동을 권장하는 공지가 필요합니다.\n"
                    "▪️ 외출 시 긴소매 옷, 모자, 선글라스 착용하고 자외선 차단제를 정기적으로 발라야 합니다.\n"
                    "▪️ 건물이나 차의 유리에 반사되는 반사광도 주의가 필요합니다.\n"
                    "▪️ 어린이의 피부 트러블에 주의하고 자극 시 즉시 세척/냉찜질이 필요합니다.\n"
                )
            elif index_level_str == "매우 높음":
                response = (  # source: 30
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부 화상을 입을 수 있어 오전 10시부터 오후 3시까지 외출을 피하고 실내나 그늘에 머물러야 합니다.\n"
                    "▪️ 외출 시 어린이의 목, 귀 등 부위까지 커버되는 의류를 착용하고 자외선 차단제를 2시간 간격으로 정기적으로 발라야 합니다.\n"
                    "▪️ 외출 시 유아차 차양을 사용하고 놀이방 등 실내 놀이를 권장합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 31
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 1~2시간 내 피부 화상을 입을 수 있어 한낮에는 그늘에 머물러야 합니다.\n"
                    "▪️ 외출 시 긴 소매 옷, 모자, 선글라스를 착용하고 자외선 차단제를 정기적으로 발라야 합니다.\n"
                    "▪️ 30분 이상 실외 활동을 피하고 모래놀이/물놀이 시 보호자 동반이 필요합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 32
                    f"ℹ️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 2~3시간 내 햇볕에 지속적 노출 시에 피부 화상을 입을 수 있으므로 주의가 필요합니다.\n"
                    "▪️ 외출 시 모자, 선글라스를 착용하고 자외선 차단제를 발라야 합니다.\n"
                    "▪️ 어린이의 경우 어린이 전용 자외선 차단제 사용을 권장합니다.\n"
                    "▪️ (외부 놀이터 장비 미끄럼틀 등의 온도를 주의하세요)\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"✅ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕 노출에 대한 특별한 보호 조치가 필요하지 않고 자유로운 외출이 가능합니다.\n"
                    "▪️ 그러나 햇볕에 민감한 피부를 가진 사람은 자외선 차단제를 바르는 것을 권장합니다.\n"
                    "▪️ 어린이의 경우 보호자의 수분 섭취 지도가 필요합니다.\n"
                )

        elif condition == 6:  # 임산부
            if index_level_str == "위험":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"🚫 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부화상을 입을 수 있어 외출 금지 수준이므로 실내에 머무르고, 진료 시 차량 이동이 필수입니다.\n"
                    "▪️ 피부 온도 상승은 태아 건강에 직접적으로 영향을 주므로 주의하여야 합니다.\n"
                    "▪️ 실내에서도 커튼으로 외부 자외선을 차단하고 냉방을 유지하는 것을 권장합니다.\n"
                )
            elif index_level_str == "매우 높음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부 화상을 입을 수 있어 외출을 최소화하는 것을 권장합니다.\n"
                    "▪️ 실외에서 햇빛 차단이 어려울 경우 단시간 외출 후 즉시 냉찜질을 하는 것을 권장합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 26, 27
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 1~2시간 내 피부 화상을 입을 수 있어 오전 10시 ~ 오후 4시 외출을 삼가야 합니다.\n"
                    "▪️ 기미/색소침착 예방을 위해 모자, 장갑을 착용하고 자외선 차단제(저자극 무기자차 권장)를 발라야 합니다.\n"
                    "▪️ 실내에서도 외부 자외선을 차단하기 위해 커튼 활용을 권장합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"ℹ️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 2~3시간 내 햇볕에 지속적 노출 시에 피부 화상을 입을 수 있으므로 주의가 필요합니다.\n"
                    "▪️ 외출 시 모자, 선글라스를 착용하고 자외선 차단제를 발르는 것을 권장합니다다.\n"
                    "▪️ 태아의 체온 관리를 위해 1시간 이상 외출 자제를 권장합니다.\n"  # 시간 정보 PDF 확인 필요
                )
            elif index_level_str == "낮음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"✅ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕 노출에 대한 특별한 보호 조치가 필요하지 않고 자유로운 외출이 가능합니다.\n"
                    "▪️ 그러나 햇볕에 민감한 피부를 가진 사람은 자외선 차단제를 바르는 것을 권장합니다.\n"
                    "▪️ 임산부의 경우 피부가 건조해지는 것을 주의하고 보습 강화를 권장합니다.\n"
                )

        else:  # 일반 사용자 (condition 3, 4, 5, 7, 8, 9 및 기타)
            if index_level_str == "위험":
                response = (  # source: 21, 22
                    f"🚫 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부화상을 입을 수 있어 가능한 실내에 머물러야 합니다.\n"
                    "▪️ 외출 시 긴소매 옷, 모자, 선글라스 착용하고 자외선 차단제를 정기적으로 발라야 합니다.\n"
                    "▪️ 건물이나 차의 유리에 반사되는 반사광도 주의가 필요합니다.\n"
                )
            elif index_level_str == "매우 높음":
                response = (  # source: 23, 24
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 수십 분 이내에도 피부 화상을 입을 수 있어 오전 10시부터 오후 3시까지 외출을 피하고 실내나 그늘에 머물러야 합니다.\n"
                    "▪️ 외출 시 긴소매 옷, 모자, 선글라스를 착용하고 자외선 차단제를 2시간 간격으로 정기적으로 발라야 합니다.\n"
                )
            elif index_level_str == "높음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"⚠️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕에 노출 시 1~2시간 내 피부 화상을 입을 수 있어 한낮에는 그늘에 머물러야 합니다.\n"
                    "▪️ 외출 시 긴 소매 옷, 모자, 선글라스를 착용하고 자외선 차단제를 정기적으로 발라야 합니다.\n"
                )
            elif index_level_str == "보통":
                response = (  # source: 25
                    f"ℹ️ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 2~3시간 내 햇볕에 지속적 노출 시에 피부 화상을 입을 수 있으므로 주의가 필요합니다.\n"
                    "▪️ 외출 시 모자, 선글라스를 착용하고 자외선 차단제를 발라야 합니다.\n"
                )
            elif index_level_str == "낮음":
                response = (  # source: 미상 (PDF 내용 기반 작성)
                    f"✅ 현재 자외선 지수 '{index_level_str}' 단계입니다.\n"
                    "▪️ 햇볕 노출에 대한 특별한 보호 조치가 필요하지 않고 자유로운 외출이 가능합니다.\n"
                    "▪️ 그러나 햇볕에 민감한 피부를 가진 사람은 자외선 차단제를 바르는 것을 권장합니다.\n"
                )

    else:
        response = f"❓ 알 수 없는 지수 유형({index_type})입니다.\n"

    return response.strip()


# --- 최종 호출 함수 ---
def get_recommendation_for_user(
    index_type: str,
    index_level: str,
    age: Optional[int],
    working_type: Optional[str],
    diseases: List[str],
    is_pregnant: Optional[bool],
) -> str:
    """사용자 프로필을 기반으로 최종 행동 요령을 반환"""
    condition_code = _map_user_profile_to_condition(
        age, working_type, diseases, is_pregnant
    )
    return _get_raw_recommendation(index_type, index_level, condition_code)
