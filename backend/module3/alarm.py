import time


def check_weather_and_alert(temperature):
    """
    기온을 입력받아 폭염 또는 한파 조건을 확인하고 행동 요령 알람을 출력하는 함수
    """
    if temperature >= 35:
        print("⚠️ [폭염 경보] 야외 활동을 자제하고 충분한 수분을 섭취하세요!")
    elif temperature <= -10:
        print("❄️ [한파 경보] 따뜻한 옷을 착용하고 실내에서 머무르세요!")
    else:
        print("✅ 현재 기온은 정상 범위입니다.")


# 테스트용 실행 (나중에 기상청 API 연동 가능)
if __name__ == "__main__":
    test_temperatures = [20, 36, -12, 30]  # 샘플 기온 데이터
    for temp in test_temperatures:
        print(f"\n현재 기온: {temp}℃")
        check_weather_and_alert(temp)
        time.sleep(1)
