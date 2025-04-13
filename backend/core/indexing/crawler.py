import asyncio
import datetime
import json
import os
import shutil
import time
from typing import Optional, Dict, Tuple, List

import pandas as pd
import requests
from dotenv import load_dotenv
from selenium import webdriver
from selenium.common import NoSuchElementException, TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from config.region_config import region_ids

# observatory.csv 경로 설정
OBSERVATORY_CSV_PATH = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "..",
        "..",
        "datasets",
        "weather",
        "observatory.csv",
    )
)

load_dotenv()

# --- Helper Functions ---


async def _get_region_from_coords(latitude: float, longitude: float) -> Optional[str]:
    """Kakao API를 사용해 좌표를 지역명(동)으로 변환 (비동기 아님, requests 사용)"""
    KAKAO_API_KEY = os.getenv("KAKAO_API_KEY")
    if not KAKAO_API_KEY:
        print("Error: KAKAO_API_KEY not found in environment variables.")
        return None, None
    url = f"https://dapi.kakao.com/v2/local/geo/coord2regioncode.JSON?x={longitude}&y={latitude}"
    headers = {"Authorization": "KakaoAK " + KAKAO_API_KEY}

    try:
        # requests는 동기 방식이므로 to_thread로 감싸 비동기 컨텍스트에서 실행
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None, lambda: requests.get(url, headers=headers, timeout=5)
        )
        response.raise_for_status()
        full_address = response.json()
        if full_address.get("documents") and len(full_address["documents"]) > 1:
            region = full_address["documents"][1].get("region_3depth_name")
            gu = full_address["documents"][1].get("region_2depth_name")
            print(f"Kakao API: Found region: {gu}, {region}")
            return gu, region
        else:
            print(
                f"Kakao API: Could not find region for coordinates ({latitude}, {longitude}). Response: {full_address}"
            )
            return None, None
    except requests.exceptions.RequestException as e:
        print(f"Kakao API request failed: {e}")
        return None, None
    except Exception as e:
        print(f"Error processing Kakao API response: {e}")
        return None, None


def _get_observatory_id(region: str) -> Optional[str]:
    """observatory.csv에서 지역명에 맞는 관측소 ID(stnId)를 반환"""
    try:
        if not os.path.exists(OBSERVATORY_CSV_PATH):
            print(f"Error: Observatory file not found at {OBSERVATORY_CSV_PATH}")
            return None

        df = pd.read_csv(OBSERVATORY_CSV_PATH)
        # '행정동' 컬럼에서 일치하는 지역 찾기
        observatory_series = df[df["행정동"] == region]["가장 가까운 관측 소(구)"]

        if not observatory_series.empty:
            observatory_name = observatory_series.values[0]
            stnId = region_ids.get(
                observatory_name
            )  # config/region_config.py의 딕셔너리 사용
            if stnId:
                print(
                    f"Found observatory '{observatory_name}' with stnId: {stnId} for region '{region}'"
                )
                return stnId
            else:
                print(
                    f"Warning: Observatory name '{observatory_name}' found, but no matching stnId in region_ids."
                )
                return None
        else:
            print(
                f"Warning: No observatory found for region '{region}' in {OBSERVATORY_CSV_PATH}"
            )
            return None
    except Exception as e:
        print(f"Error reading or processing observatory file: {e}")
        return None


def _setup_selenium_driver() -> webdriver.Chrome:
    """Selenium WebDriver 설정 및 생성"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")  # 명시적 크기 지정
    # User-Agent 설정 (차단 방지)
    options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36"
    )

    try:
        service = Service(shutil.which("chromedriver"))
        driver = webdriver.Chrome(service=service, options=options)
        driver.implicitly_wait(5)
        return driver
    except Exception as e2:
        print(f"Error setting up Selenium driver (fallback failed): {e2}")
    raise


# --- Main Fetching Functions ---


def _fetch_weather_pressure_sync(
    latitude: float, longitude: float, stn_id: str
) -> Dict[str, Optional[float]]:
    """Selenium을 사용하여 날씨 및 기압 데이터 스크래핑 (동기 함수)"""
    driver = None
    results = {
        "pressure": None,
        "temperature": None,
        "humidity": None,
        "wind_speed": None,
        "min_temp": None,
        "max_temp": None,
        "error": None,
    }

    try:
        # --- URL 생성 ---
        # 기압 URL
        base_pressure_url = "https://www.weather.go.kr/w/observation/land/aws-obs.do"
        now = datetime.datetime.now()
        # URL 인코딩 필요한 특수문자 처리 (시간 형식 주의)
        current_time_str = now.strftime("%Y.%m.%d+%H%%3A%M")  # 공백 대신 +, :는 %3A
        pressure_url = f"{base_pressure_url}?db=MINDB_01M&tm={current_time_str}&stnId={stn_id}&sidoCode=1100000000&sort=&config="
        print(f"Generated Pressure URL: {pressure_url}")

        # 날씨 URL
        admin_code = 1171067000  #
        weather_url = f"https://www.weather.go.kr/w/index.do#dong/{admin_code}/{latitude}/{longitude}/"
        print(f"Generated Weather URL: {weather_url}")
        # 참고: weather_url의 # 뒤 부분은 서버로 전송되지 않음. JS로 로딩될 가능성 높음.

        # --- Selenium 실행 ---
        driver = _setup_selenium_driver()
        wait = WebDriverWait(driver, 10)  # 명시적 대기 설정 (10초)

        # 1. 기압 데이터 스크래핑
        print(f"Fetching pressure data from: {pressure_url}")
        driver.get(pressure_url)
        # 테이블 로딩 대기 (클래스 이름 확인 필요)
        wait.until(
            EC.presence_of_element_located((By.CSS_SELECTOR, ".aws-table-col-auto"))
        )
        values = driver.find_elements(By.CSS_SELECTOR, ".aws-table-col-auto")
        if len(values) > 21:
            pressure_text = values[21].text.replace(",", "")
            results["pressure"] = float(pressure_text) if pressure_text else None
            print(f"Scraped pressure: {results['pressure']}")
        else:
            print("Warning: Could not find pressure value element (index 21).")

        # 2. 날씨 데이터 스크래핑
        print(f"Fetching weather data from: {weather_url}")
        driver.get(weather_url)  # 페이지 이동
        # 날씨 정보 로딩 대기 (주요 요소 확인)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "span.tmp")))
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "span.val")))
        wait.until(
            EC.presence_of_element_located((By.CSS_SELECTOR, ".daily-minmax span"))
        )

        tem_elements = driver.find_elements(By.CSS_SELECTOR, "span.tmp")
        wind_humi_elements = driver.find_elements(By.CSS_SELECTOR, "span.val")
        min_temp_element = driver.find_element(By.CSS_SELECTOR, ".daily-minmax span")
        # 최대 온도 선택자 수정 가능성 확인 (페이지 구조 변경 대비)
        try:
            max_temp_element = driver.find_element(
                By.CSS_SELECTOR, ".daily-minmax div:nth-child(2) span"
            )
        except NoSuchElementException:
            # 다른 선택자 시도 또는 None 처리
            print("Warning: Max temperature element not found with primary selector.")
            max_temp_element = None  # 또는 다른 CSS Selector 시도

        if tem_elements:
            results["temperature"] = float(tem_elements[0].text.replace("℃", ""))
        if len(wind_humi_elements) > 0:
            results["humidity"] = float(wind_humi_elements[0].text.replace("%", ""))
        if len(wind_humi_elements) > 1:
            # 풍속 텍스트 예: "남동 2.1m/s", 숫자만 추출
            wind_parts = wind_humi_elements[1].text.split()[1]
            if len(wind_parts) > 1:
                try:
                    results["wind_speed"] = float(wind_parts)
                except ValueError:
                    print("Warning: Could not parse wind speed value.")
        if min_temp_element:
            results["min_temp"] = float(min_temp_element.text.replace("℃", ""))
        if max_temp_element:
            results["max_temp"] = float(max_temp_element.text.replace("℃", ""))

        print(
            f"Scraped weather data: Temp={results['temperature']}, Humidity={results['humidity']}, Wind={results['wind_speed']}, Min={results['min_temp']}, Max={results['max_temp']}"
        )

    except TimeoutException:
        error_msg = "Error: Timed out waiting for page elements to load."
        print(error_msg)
        results["error"] = error_msg
    except NoSuchElementException as e:
        error_msg = f"Error: Could not find element during scraping: {e}"
        print(error_msg)
        results["error"] = error_msg
    except Exception as e:
        error_msg = f"Error during weather/pressure scraping: {e}"
        print(error_msg)
        results["error"] = error_msg
    finally:
        if driver:
            driver.quit()

    return results


def _fetch_food_poisoning_sync() -> Dict[str, Optional[str]]:
    """Selenium을 사용하여 식중독 지수 스크래핑 (동기 함수, 서울 데이터만)"""
    url = "https://poisonmap.mfds.go.kr/main.do"
    driver = None
    poison_data = {"error": None}

    try:
        driver = _setup_selenium_driver()
        print(f"Fetching food poisoning data from: {url}")
        driver.get(url)
        wait = WebDriverWait(driver, 10)  # 명시적 대기

        # 서울 버튼 클릭 대기 및 클릭
        seoul_button = wait.until(EC.element_to_be_clickable((By.ID, "pointArea-11")))
        # JavaScript 클릭 시도 (일반 클릭이 안될 경우)
        # driver.execute_script("arguments[0].click();", seoul_button)
        seoul_button.click()
        print("Clicked '서울'.")

        # 잠시 대기 후 자치구 목록 로딩 확인
        time.sleep(0.5)  # JS 실행 및 요소 로딩 대기 시간
        point_area = wait.until(
            EC.presence_of_element_located((By.CLASS_NAME, "pointArea"))
        )
        li_elements = point_area.find_elements(By.TAG_NAME, "li")
        print(f"Found {len(li_elements)} districts in Seoul.")

        scraped_data = {}
        # ActionChains 초기화
        # actions = ActionChains(driver) # 루프 밖에서 한 번만 생성

        for i, li in enumerate(li_elements):
            try:
                # span 요소 찾기 및 텍스트 추출 시도
                span = li.find_element(By.TAG_NAME, "span")
                span_text = span.text
                if not span_text:  # 텍스트 없는 li 스킵
                    continue

                driver.execute_script(
                    "arguments[0].dispatchEvent(new MouseEvent('mouseover', {bubbles: true}));",
                    li,
                )

                # hover 후 risk 요소가 나타날 때까지 잠시 대기
                time.sleep(0.1)  # 매우 짧은 대기 (필요시 조정)

                # 위험도 텍스트 추출 (ID 'risk' 요소 찾기)
                risk_element = driver.find_element(By.ID, "risk")
                risk_text = risk_element.text
                scraped_data[span_text] = risk_text

                # 수정 필요 !!!!!!!!!!!!!!!!
                level_element = driver.find_element(By.ID, "stateText")
                level_text = level_element.text
                scraped_data[span_text]

            except NoSuchElementException:
                # 특정 li 처리 중 오류 발생 시 경고 출력 후 계속 진행
                print(
                    f"Warning: Could not find span or risk element for list item index {i}. Skipping."
                )
                continue
            except Exception as e:
                print(f"Warning: Error processing list item index {i}: {e}. Skipping.")
                continue

        poison_data.update(scraped_data)
        print("Finished scraping food poisoning data.")

    except TimeoutException:
        error_msg = "Error: Timed out waiting for food poisoning page elements."
        print(error_msg)
        poison_data["error"] = error_msg
    except Exception as e:
        error_msg = f"Error during food poisoning scraping: {e}"
        print(error_msg)
        poison_data["error"] = error_msg
    finally:
        if driver:
            driver.quit()

    return poison_data


# --- Async Wrapper Functions ---


async def fetch_weather_and_pressure_data(
    latitude: float, longitude: float
) -> Dict[str, Optional[float]]:
    """날씨/기압 데이터 스크래핑 실행 (비동기 래퍼)"""
    print("Starting fetch_weather_and_pressure_data...")
    # 1. 좌표로 지역명 얻기
    _, region = await _get_region_from_coords(latitude, longitude)
    if not region:
        return {"error": "Could not determine region from coordinates."}

    # 2. 지역명으로 관측소 ID 얻기
    stn_id = _get_observatory_id(region)
    if not stn_id:
        return {"error": f"Could not find observatory ID for region '{region}'."}

    # 3. Selenium 동기 함수를 별도 스레드에서 실행
    loop = asyncio.get_running_loop()
    result = await loop.run_in_executor(
        None, _fetch_weather_pressure_sync, latitude, longitude, stn_id
    )
    print("Finished fetch_weather_and_pressure_data.")
    return result
