from datetime import datetime
import shutil

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

from backend.index.get_url import generate_pressure_url, generate_weather_url


def get_values(latitude, longitude):
    # URL 준비
    weather_url = generate_weather_url(latitude, longitude)
    pressure_url = generate_pressure_url(latitude, longitude)

    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    # ChromeDriver 실행 (드라이버 한 번 생성)
    service = Service(shutil.which("chromedriver"))
    driver = webdriver.Chrome(service=service, options=options)

    try:
        # 첫 번째 페이지: 기압 데이터 처리
        driver.get(pressure_url)
        values = driver.find_elements(By.CLASS_NAME, "aws-table-col-auto")
        pressure_value = values[21].text  # 대상 값 추출

        # 두 번째 페이지: 날씨 데이터 처리
        driver.get(weather_url)

        tem1 = driver.find_elements(By.CSS_SELECTOR, "span.tmp")
        wind_humi = driver.find_elements(By.CSS_SELECTOR, "span.val")
        min1 = driver.find_element(By.CSS_SELECTOR, ".daily-minmax span")
        max1 = driver.find_element(
            By.CSS_SELECTOR, ".daily-minmax div:nth-child(2) span"
        )

        temperature = float(tem1[0].text.replace("℃", ""))
        humidity = float(wind_humi[0].text.replace("%", ""))
        wind_speed = float(wind_humi[1].text.split()[1])
        min_tem = float(min1.text.replace("℃", ""))
        max_tem = float(max1.text.replace("℃", ""))
    finally:
        driver.quit()

    return pressure_value, temperature, humidity, wind_speed, min_tem, max_tem
