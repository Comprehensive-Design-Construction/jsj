import requests
from datetime import datetime

def get_weather():
    api_url = "http://apis.data.go.kr/1360000/VilageFcstInfoService/getVilageFcst"
    service_key = "여기에_본인의_API_키를_입력하세요"  # API 키
    nx = 60  # 예시: 특정 지역의 위도
    ny = 127  # 예시: 특정 지역의 경도
    
    # 현재 날짜와 시간 얻기 (기상청 API에 맞는 형식으로 변환)
    today = datetime.today()
    base_date = today.strftime('%Y%m%d')  # 오늘 날짜 (YYYYMMDD)
    base_time = today.strftime('%H%M')  # 현재 시간 (HHMM)

    params = {
        'serviceKey': service_key,
        'numOfRows': 10,
        'pageNo': 1,
        'dataType': 'JSON',
        'base_date': base_date,
        'base_time': base_time,
        'nx': nx,
        'ny': ny,
    }

    # API 호출
    response = requests.get(api_url, params=params)
    if response.status_code == 200:
        data = response.json()
        return data
    else:
        return None
    
def check_for_disasters(weather_data):
    # 날씨 정보에서 중요 데이터를 추출
    for item in weather_data['response']['body']['items']['item']:
        category = item['category']
        fcst_value = item['fcstValue']
        
        # 폭염, 한파 등의 조건에 맞는지 체크
        if category == 'TMP':  # 기온 정보
            if int(fcst_value) > 35:  # 예: 기온이 35도를 초과하면 폭염 경고
                return "폭염 경고! 외출 시 주의하세요."
            elif int(fcst_value) < -10:  # 예: 기온이 -10도 이하이면 한파 경고
                return "한파 경고! 외출 시 따뜻하게 입으세요."
    
    return None

from plyer import notification

def send_notification(message):
    notification.notify(
        title="WE 앱 자연재해 경고",
        message=message,
        timeout=10  # 알림 표시 시간 (초)
    )

def main():
    weather_data = get_weather()
    if weather_data:
        disaster_message = check_for_disasters(weather_data)
        if disaster_message:
            send_notification(disaster_message)
        else:
            print("현재 자연재해 경고는 없습니다.")
    else:
        print("날씨 정보를 가져오는 데 실패했습니다.")

# 앱 실행
main()

import time

def periodic_weather_check(interval=3600):
    while True:
        main()  # 날씨 확인 및 알림 보내기
        time.sleep(interval)  # 지정된 시간(초)마다 반복 실행

# 앱 실행 (1시간 간격으로 날씨 확인)
periodic_weather_check(3600)
