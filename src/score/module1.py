#dong_name = "잠실2동"  # 원하는 행정동명 입력
latitude = "37.575251"  # 원하는 위도 입력
longitude = "126.928484"  # 원하는 경도 입력

region_name = "강동"  # 행정동에서 가장 가까운 기상관측소를 매핑해서 자동으로 입력되게 끔
user_types = ["노인", "비닐하우스"] #사용자의 환경 입력("노인", "어린이", "취약 거주환경", "농촌", "비닐하우스")
                              #[실외작업장_도로, 실외작업장_건설현장, 실외작업장_조선소] --> 빼는게 나을 듯)


# 지역별 stnId 값을 딕셔너리로 정의
region_ids = {
    "서울": 108,
    "김포(공)": 110,
    "강남": 400,
    "서초": 401,
    "강동": 402,
    "송파*": 403,
    "강서": 404,
    "양천": 405,
    "도봉": 406,
    "노원": 407,
    "동대문": 408,
    "중랑": 409,
    "기상청": 410,
    "마포": 411,
    "서대문": 412,
    "광진": 413,
    "성북": 414,
    "용산": 415,
    "은평": 416,
    "금천": 417,
    "한강": 418,
    "중구": 419,
    "성동": 421,
    "구로": 423,
    "강북": 424,
    "남현": 425,
    "관악": 508,
    "영등포*": 510,
    "현충원": 889
    # 필요한 지역 추가
}


#기상청 크롤링 함수수
#import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from datetime import datetime


# 기본 URL
base_url = "https://www.weather.go.kr/w/observation/land/aws-obs.do"
tmp = 123
# 현재 시간 가져오기
now = datetime.now()
current_time = now.strftime("%Y.%m.%d%%20%H%%3A%M")  # 현재 시간 형식: 2025.04.02%2021%3A57



"""상세 관측 url"""
# URL 생성(현재시간, 지역에 맞게 url 변경경)
if region_name in region_ids:
    stnId = region_ids[region_name]
    final_url = (
        f"{base_url}?db=MINDB_01M&tm={current_time}&stnId={stnId}&sidoCode=1100000000&sort=&config="
    )
    #print(f"생성된 상세관측 URL: {final_url}")
else:
    print("해당 지역명은 데이터에 없습니다.")


"""기상청 홈페이지 행정동 고정 버전 url"""
def generate_weather_url(latitude, longitude):
    admin_code = 1171067000
    url = f"https://www.weather.go.kr/w/index.do#dong/{admin_code}/{latitude}/{longitude}/"
    return url


weather_url = generate_weather_url(latitude, longitude)




#해당 url에서 특정 값 가져오기
# ChromeDriver 경로 설정
chrome_driver_path = "C:\\Users\\User\\workspace\\jsj\\chromedriver.exe"  # 자신의 chromedriver 경로 입력

# Selenium 옵션 설정
options = Options()
options.add_argument("--headless")  # 브라우저를 숨긴 채 실행 (필요하면 제거 가능)
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

# ChromeDriver 실행
service = Service(chrome_driver_path)
driver = webdriver.Chrome(service=service, options=options)

try:
    driver.get(final_url)  # 웹페이지 열기

    values = driver.find_elements(By.CLASS_NAME, "aws-table-col-auto")

    # 특정 값 가져오기 (클래스나 ID를 수정해야 함
    gi_ab = values[21].text

    print(f"현재 값 기압: {gi_ab}")


finally:
    driver.quit()  # 실행 후 브라우저 닫기




#print(f"생성된 기상청 URL: {weather_url}")

# Selenium 옵션 설정
options = Options()
options.add_argument("--headless")  # 브라우저를 숨긴 채 실행 (필요하면 제거 가능)
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

# ChromeDriver 실행
service = Service(chrome_driver_path)
driver = webdriver.Chrome(service=service, options=options)

try:
    driver.get(weather_url)  # 웹페이지 열기

    tem1 = driver.find_elements(By.CSS_SELECTOR, "span.tmp")
    wind_humi = driver.find_elements(By.CSS_SELECTOR, "span.val")
    min1 = driver.find_element(By.CSS_SELECTOR, ".daily-minmax span")
    max1 = driver.find_element(By.CSS_SELECTOR, ".daily-minmax div:nth-child(2) span")


    # 특정 값 가져오기 (클래스나 ID를 수정해야 함
    on_do = float(tem1[0].text.replace("℃", ""))
    seob_do = float(wind_humi[0].text.replace("%", ""))
    pung_sock = float(wind_humi[1].text.split()[1])
    text_value = min1.text.replace("℃", "")
    if text_value == "-":
        mintem = None  # 또는 기본값 설정
    else:
        mintem = float(text_value)

    text_value = max1.text.replace("℃", "")
    if text_value == "-":
        maxtem = None  # 기본값을 설정하거나 다른 처리 방식 사용
    else:
        maxtem = float(text_value)


    print(f"현재 값 온도: {on_do}")
    print(f"현재 값 습도: {seob_do}")
    print(f"현재 값 풍속: {pung_sock}")
    print(f"현재 값 최저기온: {mintem}")
    print(f"현재 값 최고기온: {maxtem}")
    print("--------------------------------------------")

finally:
    driver.quit()  # 실행 후 브라우저 닫기



import numpy as np

ta = on_do #기온
rh = seob_do #상대습도 %그대로 적으면 됨
v =  pung_sock #풍속 m/s 

result = 0 #가중치 초기화

#습구온도
tw = ta*np.arctan(0.151977*(rh+8.313659)**(1/2))+np.arctan(ta+rh)\
    -np.arctan(rh-1.67633)+(0.00391838*rh**(3/2))*np.arctan(0.023101*rh)-4.686035



#시간대 별 가중치 정의 함수수
def weh(user_types, time_slot):
    
    # 시간대별 가중치 정의
    weights = {
        "어린이": {
            3: 0.0, 6: 0.0, 9: 2.9, 12: 2.5, 15: 1.2, 18: -0.9, 21: 0.0, 24: 0.0
        },
        "취약 거주환경": {
            3: 1.0, 6: 0.0, 9: 0.7, 12: 1.7, 15: 0.9, 18: 0.3, 21: 5.0, 24: 2.5
        },
        "농촌": {
            3: 0.0, 6: 0.0, 9: 0.1, 12: 0.5, 15: 1.1, 18: 0.6, 21: 0.0, 24: 0.0
        },
        "비닐하우스": {
            3: 0.0, 6: 0.0, 9: 2.3, 12: 4.0, 15: 4.0, 18: 2.1, 21: 1.0, 24: 0.5
        },
        "실외작업장_도로": {
            3: 0.3, 6: 0.5, 9: 1.2, 12: 1.4, 15: 1.3, 18: 0.9, 21: 0.5, 24: 0.3
        },
        "실외작업장_건설현장": {
            3: 1.2, 6: 1.0, 9: 1.3, 12: 1.6, 15: 1.2, 18: 0.7, 21: 1.4, 24: 1.2
        },
        "실외작업장_조선소": {
            3: 0.0, 6: 0.0, 9: 1.7, 12: 2.2, 15: 1.0, 18: 0.0, 21: 0.0, 24: 0.0
        }
    }

    # 선택된 조건들만 가중치 합산
    total_weight = 0
    for user_type in user_types:
        if user_type in weights:
            total_weight += weights[user_type].get(time_slot, 0)
    
    return total_weight



# 현재 시간을 3, 6, 9, ~ 24에 맞도록 변경
def get_time_slot():
    # 현재 시간 가져오기
    current_hour = datetime.now().hour
    
    # 시간대를 기반으로 time_slot 값 결정
    if 0 <= current_hour < 3:   
        return 24
    elif 3 <= current_hour < 6: 
        return 3
    elif 6 <= current_hour < 9: 
        return 6
    elif 9 <= current_hour < 12: 
        return 9
    elif 12 <= current_hour < 15: 
        return 12
    elif 15 <= current_hour < 18: 
        return 15
    elif 18 <= current_hour < 21: 
        return 18
    elif 21 <= current_hour < 24: 
        return 21
    else: 
        return 24

# time_slot에 3, 6, 9, 형태로 현재 시간을 저장
time_slot = get_time_slot()





# 체감온도 계산함수수
def merge_eftem(ta, v, rh):
    """
    현재 날짜에 따라 겨울 또는 여름 체감온도를 계산.
    - 겨울 (10월 ~ 4월): winter_eftem 공식
    - 여름 (5월 ~ 9월): summer_eftem 공식
    """
    # 현재 월 가져오기
    current_month = datetime.now().month

    if current_month in [10, 11, 12, 1, 2, 3, 4]:  # 겨울 공식 적용
        if ta <= 10 and v >= 1.3:
            eftem = 13.12 + 0.6215 * ta - 11.37 * ((v*3.6) ** 0.16) + (0.3965 * ((v*3.6) ** 0.16)) * ta
            return round(eftem, 2)  # 소수점 2자리로 반환
        else:
            return ta  # 조건 미충족 시 기온 그대로 반환

    elif current_month in [5, 6, 7, 8, 9]:  # 여름 공식 적용
        # 개인별 가중치
        result = weh(user_types, time_slot) #가중치
        
        # 여름 체감온도 공식
        eftem = -0.2442 + 0.55399 * tw + 0.45535 * ta - (0.0022 * tw ** 2) + \
                (0.00278 * tw * ta) + result + 3.0
        return round(eftem, 2)  # 소수점 2자리로 반환
    else:
        raise ValueError("월(month)은 1에서 12 사이의 값이어야 합니다.")
    

apparent_temperature = merge_eftem(ta, v, rh)


#print(f"체감온도: {apparent_temperature}°C")


#사용자 환경 함수 정의의
def check_risk(user_types, eftem):
    # 노인, 어린이, 취약 거주환경 중 하나라도 해당되면 체크
    applicable_types = {"노인", "어린이", "취약거주환경"}
    # 농촌, 비닐하우스 중 하나라도 해당되면 체크
    applicable_types2 = {"농촌", "비닐하우스"}
    
    # 입력된 user_types에 하나라도 노인, 어린이, 취약거주환경이 포함되면 True
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
        
    # 입력된 user_type에 하나라도 농촌, 비닐하우스이 포함되면 True
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
    
    # 그 어디에도 해당 되지 않는 다면 e.g. 건장한 성인 남성 (이건 다른 기준 보고 수치 다시 조절해야함)
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
risk = check_risk(user_types, apparent_temperature)

print("")
print("---------사용자 체감온도----------------")
print(f"사용자의 해당 환경: {user_types}")
#print(f"사용자 가중치 값: {result}")
print(f"사용자의 체감온도: {apparent_temperature}")
print(f"사용자 위험 상태: {risk}")


mintem = mintem if mintem is not None else -99
maxtem = maxtem if maxtem is not None else -99

#천식 폐질환 가능 지수수
drhythm = maxtem-mintem # 일교차
lpressure = float(gi_ab.replace(",", ""))-10.4 #현지기압
#상대습도는 위에서 정의

def calculate_score(column_name, value):
    # 서울 항목별 점수 기준 정의
    criteria = {
        '최저기온': {
            4: (-float('inf'), -8.1),  # 4점: -8.1 미만
            3: (-8.1, 0.6),           # 3점: 0.6 미만
            2: (0.6, 13.5),           # 2점: 13.5 미만
            1: (13.5, float('inf'))   # 1점: 13.5 이상
        },
        '일교차': {
            4: (12.5, float('inf')),  # 4점: 12.5 이상
            3: (9.9, 12.5),           # 3점: 9.9 이상
            2: (7.3, 9.9),            # 2점: 7.3 이상
            1: (-float('inf'), 7.3)   # 1점: 7.3 미만
        },
        '현지기압': {
            4: (1017.9, float('inf')), # 4점: 1017.9 이상
            3: (1011.9, 1017.9),       # 3점: 1011.9 이상
            2: (1003.5, 1011.9),       # 2점: 1003.5 이상
            1: (-float('inf'), 1003.5) # 1점: 1003.5 미만
        },
        '상대습도': {
            4: (-float('inf'), 37.4),  # 4점: 37.4 미만
            3: (37.4, 50.0),           # 3점: 50.0 미만
            2: (50.0, 65.9),           # 2점: 65.9 미만
            1: (65.9, float('inf'))    # 1점: 65.9 이상
        }
    }
    
    # 해당 열(column_name)의 값(value)에 대한 점수 계산
    for score, (lower, upper) in criteria[column_name].items():
        if lower <= value < upper:
            return score
    return None  # 범위에 맞는 점수가 없을 경우

# 데이터 입력
data = {
    '최저기온': mintem,
    '일교차': drhythm,
    '현지기압': lpressure,
    '상대습도': rh
}

# 각 항목에 대한 점수 계산
scores = {column: calculate_score(column, value) for column, value in data.items()}
#print(scores)

#천식 폐질환 지수 계산
ALI = 0.443*scores['최저기온'] + 0.202*scores['일교차'] + 0.315*scores['현지기압'] + 0.04*scores['상대습도']



#천식 폐질환 등급
def check_ali_level(ALI):
    # ALI 지수 범위별 레벨 정의
    if ALI >= 3.0525:
        return "매우 높음"
    elif 2.6452 <= ALI < 3.0525:
        return "높음"
    elif 1.5354 <= ALI < 2.6452:
        return "보통"
    elif 1.0 <= ALI < 1.5354:
        return "낮음"
    else:
        return "잘못된 값"  # 1 미만의 ALI 값 처리 (기준 외)

if mintem == -99 or maxtem == -99:
    ALI = "오류"

# mintem과 maxtem의 값 확인 후 ALI_risk 설정
if mintem == -99 or maxtem == -99:
    ALI_risk = "오류"
else:
    ALI_risk = check_ali_level(ALI)


print("")
print("---------천식, 폐질환 가능 지수----------")
print(f"사용자의 천식, 폐질환 가능지수: {ALI}")
print(f"등급 값: {ALI_risk}")