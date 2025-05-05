def health_index_response(
    index_type, index_value, condition, name, birthdate, diseases
):
    response = ""
    disease_response = ""
    condition_response = ""

    # Disease-specific response
    if "당뇨병" in diseases:
        disease_response += (
            "당뇨병 환자는 혈당 관리를 철저히 하고, 정기적으로 혈당을 체크하세요. "
        )
    if "고혈압" in diseases:
        disease_response += (
            "고혈압 환자는 혈압 관리를 철저히 하고, 스트레스 관리를 하세요. "
        )
    if "심뇌혈관질환" in diseases:
        disease_response += (
            "심뇌혈관질환 환자는 증상에 주의하고, 응급 상황에 대비하세요. "
        )
    if "호흡기 질환" in diseases:
        disease_response += (
            "호흡기 질환 환자는 외출 시 마스크를 착용하고, 공기질에 주의하세요. "
        )
    if "해당 없음" in diseases:
        disease_response = "기저질환이 없습니다."

    # Index-specific response
    if index_type == "체감온도":
        if condition == 1:  # 노인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "정기적으로 혈압과 혈당을 측정하고, 정상 수준을 유지. "
                    "급격한 날씨 변화에 주의하고, 외출 시 보온에 신경 씀. "
                    "고혈압이나 뇌졸중 기왕력 있는 경우 각별한 주의 필요."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "혈압을 꾸준히 측정하며, 정상 수준 유지에 노력. "
                    "보온에 유의하며, 특히 새벽이나 밤 시간 외출 자제."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "건강 관리를 철저히 하고, 규칙적인 운동과 식습관 조절. "
                    "외출 시 갑작스러운 체온 변화에 대비하여 따뜻한 복장 착용."
                )
            else:
                response = "낮음: " "꾸준한 건강 관리와 영양 섭취, 가벼운 운동을 지속."

        elif condition == 2:  # 어린이
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 외출 시 주의. "
                    "특히 감기 증상에 민감하게 대처하고, 외출 후 손 씻기 등 위생 관리 강화. "
                    "건강 상태를 수시로 체크하고, 이상 증상 시 빠르게 조치."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "외출 시 따뜻한 옷을 착용하여 체온 유지. "
                    "추운 곳으로 외출할 경우 보호자의 동반 필수. "
                    "밤이나 새벽 외출은 피하고, 건강 상태를 주의 깊게 관찰."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "건강한 생활 습관을 유지하며, 규칙적인 운동과 건강한 식습관을 지킬 것. "
                    "외출 시 기온 차에 대비하여 추가 의류 준비."
                )
            else:
                response = (
                    "낮음: "
                    "평소 건강 관리에 유의하며, 적절한 영양 섭취와 가벼운 운동을 권장."
                )

        elif condition == 6:  # 임산부
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "임산부는 체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 주의. "
                    "외출 시 따뜻한 복장을 유지하고, 무리한 활동을 피함. "
                    "건강 상태를 주기적으로 체크하고, 이상 증상 시 빠른 조치."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "외출 시 따뜻한 옷 착용하여 체온 유지. "
                    "추운 시간대 외출 자제, 건강 상태 주의 깊게 관찰."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "건강 관리를 철저히 하고, 규칙적인 운동과 함께 식습관 조절. "
                    "외출 시 기온 차에 대비하여 추가 의류 준비."
                )
            else:
                response = (
                    "낮음: "
                    "평소 건강 관리에 유의하고, 적절한 영양 섭취와 가벼운 운동을 권장."
                )

        elif condition == 7:  # 기저질환자
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "꾸준히 혈압, 혈당, 콜레스테롤 수치를 측정하고 정상 수준 유지. "
                    "외출 및 환기에 주의하며, 급격한 날씨 변화에 노출되지 않도록 함. "
                    "고혈압 및 뇌졸중 기왕력 환자는 각별히 주의."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "혈압을 꾸준히 측정하며 정상 상태 유지. "
                    "보온에 신경 쓰고, 특히 새벽이나 밤 외출 자제."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의. "
                    "외출 시 체온 변화에 대비해 따뜻한 복장 준비."
                )
            else:
                response = (
                    "낮음: "
                    "평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속."
                )

        else:  # 일반인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "날씨 변화에 민감하게 대처하고, 외출 시 보온에 유의. "
                    "급격한 온도 변화에 노출되지 않도록 주의하며, 규칙적으로 건강 상태를 체크. "
                    "충분한 수분을 섭취하고, 건강 이상 시 즉시 조치."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "따뜻한 옷을 착용하여 체온 유지. "
                    "특히 추운 시간대(새벽, 밤) 외출 시 보온에 신경 쓰기. "
                    "건강 상태를 자주 확인하고, 무리하지 않도록 주의."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의. "
                    "외출 시 기온 변화에 대비하여 추가 의류 준비."
                )
            else:
                response = (
                    "낮음: "
                    "평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속."
                )

    elif index_type == "미세먼지":
        if index_value >= 151:
            response = (
                "매우나쁨: "
                "모든 사람은 실외 활동을 자제하고, 외출 시에는 마스크를 착용하세요. "
                "민감군은 실내에 머무르세요."
            )
        elif 101 <= index_value < 151:
            response = (
                "나쁨쁨: "
                "민감군은 실외 활동을 줄이고, 일반인은 장시간 또는 무리한 실외 활동을 줄이세요."
            )
        elif 51 <= index_value < 101:
            response = "보통: " "민감군은 실외 활동을 줄이세요."
        else:
            response = "좋음: " "실외 활동에 지장이 없습니다."

    elif index_type == "심뇌혈관질환":
        if condition == 1:  # 노인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "심뇌혈관질환 발생 위험이 매우 높습니다. "
                    "정기적으로 혈압과 혈당을 측정하고, 정상 수준을 유지하도록 함. "
                    "급격한 날씨 변화에 노출되지 않도록 외출 및 환기에 주의하기. "
                    "고혈압 뇌졸중 기왕력 환자들은 각별한 주의 요망."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "심뇌혈관질환 발생 위험이 높습니다. "
                    "혈압측정을 꾸준히 하면서 정상 혈압이 유지되도록 함. "
                    "건강에 더욱 관심을 가지고 추운 곳으로 외출할 경우 보온 유지하기. "
                    "특히 온도가 낮은 새벽이나 밤 시간을 피해 외출함."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "심뇌혈관 건강을 위해 정기적인 건강 검진을 받으세요. "
                    "평소 건강관리에 유의하고 규칙적인 운동과 함께 식습관 조절하기. "
                    "뇌졸중 환자들은 외출 시 갑작스럽게 체온이 변하지 않도록 보온에 유념함."
                )
            else:
                response = (
                    "낮음: "
                    "심뇌혈관 건강에 큰 문제는 없으나, 꾸준한 관리가 필요합니다. "
                    "평소 건강관리에 유의하여 음식 섭취를 조절하고 가벼운 운동을 하도록 함."
                )

        elif condition == 2:  # 어린이
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "어린이의 심뇌혈관질환 발생 위험이 매우 높습니다. "
                    "체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 외출 시 주의. "
                    "건강 상태를 수시로 체크하고, 이상 증상 시 빠르게 조치."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "어린이의 심뇌혈관질환 발생 위험이 높습니다. "
                    "외출 시 따뜻한 옷을 착용하여 체온 유지. "
                    "특히 추운 시간대 외출은 피하고, 건강 상태를 주의 깊게 관찰."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "어린이의 심뇌혈관 건강을 위해 정기적인 건강 검진을 받으세요. "
                    "건강한 생활 습관을 유지하며, 규칙적인 운동과 건강한 식습관을 지킬 것."
                )
            else:
                response = (
                    "낮음: "
                    "어린이의 심뇌혈관 건강에 큰 문제는 없으나, 꾸준한 관리가 필요합니다. "
                    "평소 건강 관리에 유의하며, 적절한 영양 섭취와 가벼운 운동을 권장."
                )

        elif condition == 6:  # 임산부
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "임산부의 심뇌혈관질환 발생 위험이 매우 높습니다. "
                    "체온 유지에 유의하고, 급격한 날씨 변화에 노출되지 않도록 주의. "
                    "건강 상태를 주기적으로 체크하고, 이상 증상 시 빠른 조치."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "임산부의 심뇌혈관질환 발생 위험이 높습니다. "
                    "외출 시 따뜻한 옷 착용하여 체온 유지. "
                    "추운 시간대 외출 자제, 건강 상태 주의 깊게 관찰."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "임산부의 심뇌혈관 건강을 위해 정기적인 건강 검진을 받으세요. "
                    "건강 관리를 철저히 하고, 규칙적인 운동과 함께 식습관 조절."
                )
            else:
                response = (
                    "낮음: "
                    "임산부의 심뇌혈관 건강에 큰 문제는 없으나, 꾸준한 관리가 필요합니다. "
                    "평소 건강 관리에 유의하고, 적절한 영양 섭취와 가벼운 운동을 권장."
                )

        elif condition == 7:  # 기저질환자
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "기저질환자의 심뇌혈관질환 발생 위험이 매우 높습니다. "
                    "꾸준히 혈압, 혈당, 콜레스테롤 수치를 측정하고 정상 수준 유지. "
                    "외출 및 환기에 주의하며, 급격한 날씨 변화에 노출되지 않도록 함."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "기저질환자의 심뇌혈관질환 발생 위험이 높습니다. "
                    "혈압을 꾸준히 측정하며 정상 상태 유지. "
                    "보온에 신경 쓰고, 특히 새벽이나 밤 외출 자제."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "기저질환자의 심뇌혈관 건강을 위해 정기적인 건강 검진을 받으세요. "
                    "규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의."
                )
            else:
                response = (
                    "낮음: "
                    "기저질환자의 심뇌혈관 건강에 큰 문제는 없으나, 꾸준한 관리가 필요합니다. "
                    "평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속."
                )

        else:  # 일반인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "일반인의 심뇌혈관질환 발생 위험이 매우 높습니다. "
                    "날씨 변화에 민감하게 대처하고, 외출 시 보온에 유의. "
                    "급격한 온도 변화에 노출되지 않도록 주의하며, 규칙적으로 건강 상태를 체크."
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "일반인의 심뇌혈관질환 발생 위험이 높습니다. "
                    "따뜻한 옷을 착용하여 체온 유지. "
                    "특히 추운 시간대(새벽, 밤) 외출 시 보온에 신경 쓰기."
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "일반인의 심뇌혈관 건강을 위해 정기적인 건강 검진을 받으세요. "
                    "규칙적인 운동과 건강한 식습관을 유지하며, 건강 관리에 유의."
                )
            else:
                response = (
                    "낮음: "
                    "일반인의 심뇌혈관 건강에 큰 문제는 없으나, 꾸준한 관리가 필요합니다. "
                    "평소 건강 관리에 유의하며, 적절한 음식 섭취와 가벼운 운동을 지속."
                )

    elif index_type == "천식질환":
        if index_value >= 5:
            response = (
                "매우 높음: "
                "천식질환 발생 위험이 매우 높습니다. "
                "천식 환자는 처방받은 약물을 항상 소지하고, 자극적인 활동을 피하세요."
            )
        elif index_value >= 3:
            response = (
                "높음: "
                "천식질환 발생 위험이 높습니다. "
                "알레르기 유발 요인을 피하고, 충분한 휴식을 취하세요."
            )
        elif index_value >= 1:
            response = (
                "보통: "
                "천식질환 발생 위험이 보통입니다. "
                "정기적인 천식 관리가 필요합니다."
            )
        else:
            response = (
                "낮음: "
                "천식질환 발생 위험이 낮습니다. "
                "기본적인 건강 관리를 유지하세요."
            )

    elif index_type == "감기가능":
        if condition == 6:  # 임산부
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "- 외출 자제, 무리한 가사/활동 피하기\n"
                    "- 외출 시 따뜻한 복장, 특히 배/허리 보온\n"
                    "- 외출 후 따뜻한 물로 샤워 및 충분한 휴식"
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "- 수면과 영양 섭취 균형 유지\n"
                    "- 실내 적정 온·습도 관리(가습기 활용)\n"
                    "- 비타민 C 섭취 권장"
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "- 산책은 햇볕 좋은 시간에 짧게\n"
                    "- 손씻기 등 위생관리 강화\n"
                    "- 따뜻한 물 자주 마시기"
                )
            else:
                response = (
                    "낮음: "
                    "- 감기 초기증상에 민감하게 대처\n"
                    "- 가벼운 실내 스트레칭"
                )

        elif condition == 2:  # 어린이
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "- 외출 자제, 실내 놀이로 대체\n"
                    "- 목도리, 모자, 장갑 착용 철저\n"
                    "- 젖은 옷 즉시 갈아입히기"
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "- 실내에서 규칙적인 놀이 유지\n"
                    "- 과격한 운동 자제\n"
                    "- 충분한 수면시간 확보"
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "- 규칙적인 생활습관 유지\n"
                    "- 손 씻기, 마스크 쓰기 교육\n"
                    "- 외출 전후 체온 체크"
                )
            else:
                response = (
                    "낮음: " "- 평소 체온 관찰 습관화\n" "- 보호자의 감기예방 교육"
                )

        elif condition == 1:  # 노인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "- 외출 자제, 난방기 사용 시 실내 습도 유지\n"
                    "- 무리한 운동·산책 피하기\n"
                    "- 따뜻한 물 자주 섭취"
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "- 활동 후 충분한 휴식 취하기\n"
                    "- 온열 내의 착용 권장\n"
                    "- 실내 공기 자주 환기"
                )
            elif index_value >= 1:
                response = (
                    "보통: " "- 외출 전후 따뜻한 차 마시기\n" "- 저녁 시간 외출 지양"
                )
            else:
                response = (
                    "낮음: "
                    "- 감기 증상 시 조기 진료 유도\n"
                    "- 충분한 수면 및 영양 섭취 유지"
                )
        else:  # 일반인
            if index_value >= 5:
                response = (
                    "매우 높음: "
                    "- 외출 자제, 실내에서 휴식\n"
                    "- 따뜻한 복장 착용\n"
                    "- 감기 증상에 민감하게 대처"
                )
            elif index_value >= 3:
                response = (
                    "높음: "
                    "- 외출 시 따뜻한 옷 착용\n"
                    "- 충분한 수면과 영양 섭취\n"
                    "- 감기 예방을 위한 비타민 C 섭취"
                )
            elif index_value >= 1:
                response = (
                    "보통: "
                    "- 규칙적인 생활 습관 유지\n"
                    "- 위생 관리 철저\n"
                    "- 충분한 수분 섭취"
                )
            else:
                response = (
                    "낮음: "
                    "- 건강한 생활 습관 유지\n"
                    "- 기본적인 감기 예방 수칙 준수"
                )

    elif index_type == "식중독":
        if index_value >= 5:
            response = (
                "매우 높음: "
                "식중독 발생 위험이 매우 높습니다. "
                "음식은 철저히 익혀 먹고, 조리된 음식은 빨리 섭취하세요."
            )
        elif index_value >= 3:
            response = (
                "높음: "
                "식중독 발생 위험이 높습니다. "
                "식품 위생에 주의하고, 손을 자주 씻으세요."
            )
        elif index_value >= 1:
            response = (
                "보통: "
                "식중독 발생 위험이 보통입니다. "
                "기본적인 식품 안전 수칙을 지키세요."
            )
        else:
            response = (
                "낮음: "
                "식중독 발생 위험이 낮습니다. "
                "기본적인 건강 관리를 유지하세요."
            )
    else:
        response = "알 수 없는 지수 유형입니다."

    # Condition-specific response
    if condition == 1:
        condition_response = "65세 이상 노인에게 특별히 주의가 필요합니다."
    elif condition == 2:
        condition_response = "어린이는 특별히 주의가 필요합니다."
    elif condition == 3:
        condition_response = "농촌 지역에서는 특별한 주의가 필요합니다."
    elif condition == 4:
        condition_response = "비닐하우스 작업자는 특별히 주의가 필요합니다."
    elif condition == 5:
        condition_response = "실외 작업자는 특별히 주의가 필요합니다."
    elif condition == 6:
        condition_response = "임산부는 특별히 주의가 필요합니다."
    elif condition == 7:
        condition_response = "건강관리에 주의하십시오."

    return f"{name} ({birthdate}) - {disease_response}{response} {condition_response}"


# Example usage
name = input("이름을 입력하세요: ")
birthdate = input("생년월일을 입력하세요 (YYYY-MM-DD): ")
index_type = input(
    "지수 유형을 선택하세요 (체감온도, 미세먼지, 심뇌혈관질환, 천식질환, 감기가능, 식중독): "
)
index_value = float(input(f"{index_type} 지수를 입력하세요: "))
condition = int(
    input(
        "조건을 입력하세요 (1: 65세 이상 노인, 2: 어린이, 3: 농촌, 4: 비닐하우스, 5: 실외 작업자, 6: 임산부, 7: 해당 없음): "
    )
)
diseases = input(
    "기저질환을 입력하세요 (예: 당뇨병, 고혈압, 심뇌혈관질환, 호흡기 질환, 해당 없음), 쉼표로 구분하세요: "
).split(", ")

print(
    health_index_response(index_type, index_value, condition, name, birthdate, diseases)
)
