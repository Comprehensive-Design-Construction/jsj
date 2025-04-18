import shutil
import time
from typing import Optional, Dict

from selenium import webdriver
from selenium.common import NoSuchElementException, TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


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

                data = {}
                # 식중독 지수 추출
                risk_element = driver.find_element(By.ID, "risk")
                risk_text = risk_element.text

                # 식중독 위험도 추출
                level_element = driver.find_element(By.ID, "stateText")
                level_text = level_element.text

                data["poison_index"] = risk_text
                data["poison_level"] = level_text
                scraped_data[span_text] = data

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
