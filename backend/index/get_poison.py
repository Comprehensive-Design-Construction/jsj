from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager
import time
import shutil

url = "https://poisonmap.mfds.go.kr/main.do"


def get_poison_data() -> dict:
    """
    :return: {XX구: 식중독지수} dictionary
    """
    # 크롬 옵션 설정
    options = Options()
    options.add_argument("--headless")  # 창 띄우지 않음
    options.add_argument("--no-sandbox")  # 샌드박스 비활성화 (리눅스 등에서 필요)
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")  # 화면 크기 (hover 문제 방지용)

    # webdriver-manager를 통해 크롬 드라이버 자동 설치 및 경로 설정
    service = Service(shutil.which("chromedriver"))
    driver = webdriver.Chrome(service=service, options=options)
    driver.get(url)

    poison_data = {}

    try:
        time.sleep(1)  # 초기 페이지 렌더링 대기

        # 서울 클릭 (지점 활성화)
        seoul = driver.find_element(By.ID, "pointArea-11")
        seoul.click()
        time.sleep(0.1)

        # 지점 리스트 추출
        point_area = driver.find_element(By.CLASS_NAME, "pointArea")
        li_elements = point_area.find_elements(By.TAG_NAME, "li")

        for li in li_elements:
            span_text = li.find_element(By.TAG_NAME, "span").text

            # 마우스 hover
            actions = ActionChains(driver)
            actions.move_to_element(li).perform()
            time.sleep(0)  # hover 반영 대기

            # 위험도 텍스트 추출
            risk_text = driver.find_element(By.ID, "risk").text
            poison_data[span_text] = risk_text

    except Exception as e:
        print(f"에러 발생: {e}")
    finally:
        driver.quit()

    return poison_data


if __name__ == "__main__":
    data = get_poison_data()
    for name, risk in data.items():
        print(f"{name}: {risk}")
