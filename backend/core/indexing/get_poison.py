import shutil
import time
import logging
from typing import Optional, Dict, Any

from selenium import webdriver
from selenium.common import NoSuchElementException, TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.remote.webelement import WebElement
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

logger = logging.getLogger(__name__)


class PoisonDataError(Exception):
    """Custom exception for food poisoning data scraping errors."""

    pass


def _setup_selenium_driver() -> webdriver.Chrome:
    """Selenium WebDriver 설정 및 생성"""
    logger.info("Setting up Selenium WebDriver...")
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
        service = Service(
            executable_path=ChromeDriverManager().install(),
            service_args=["--verbose", "--log-path=/tmp/chromedriver.log"],
        )
        driver = webdriver.Chrome(service=service, options=options)
        driver.implicitly_wait(5)
        logger.info("Selenium WebDriver setup successful.")
        return driver
    except Exception as e:
        logger.exception("Error setting up Selenium driver.")
        raise PoisonDataError(f"Failed to setup Selenium driver: {e}")


def fetch_food_poisoning_data() -> Dict[str, Dict[str, str]]:
    """Selenium을 사용하여 식중독 지수 스크래핑 (동기 함수, 서울 데이터만)"""
    url = "https://poisonmap.mfds.go.kr/main.do"
    driver = None
    scraped_data: Dict[str, Dict[str, str]] = {}

    try:
        driver = _setup_selenium_driver()
        logger.info(f"Fetching food poisoning data from: {url}")
        driver.get(url)
        wait = WebDriverWait(driver, 15)

        try:
            seoul_button = wait.until(
                EC.element_to_be_clickable((By.ID, "pointArea-11"))
            )
            driver.execute_script("arguments[0].click();", seoul_button)
            logger.info("Clicked '서울' button.")
        except TimeoutException:
            logger.error("Timed out waiting for '서울' button.")
            raise PoisonDataError("Timed out waiting for '서울' button.")

        # 자치구 목록 로딩 확인
        try:
            point_area = wait.until(
                EC.presence_of_element_located((By.CLASS_NAME, "pointArea"))
            )
            li_elements = wait.until(
                EC.presence_of_all_elements_located(
                    (By.CSS_SELECTOR, ".pointArea li span")
                )
            )
            li_tags = [
                span.find_element(By.XPATH, "./..") for span in li_elements if span.text
            ]

            logger.info(f"Found {len(li_tags)} districts in Seoul.")
            if not li_tags:
                raise PoisonDataError("No district list items found.")
        except TimeoutException:
            logger.error("Timed out waiting for district list.")
            raise PoisonDataError("Timed out waiting for district list.")

        for i, li in enumerate(li_tags):
            district_name = ""
            try:
                span = li.find_element(By.TAG_NAME, "span")
                district_name = span.text
                if not district_name:
                    logger.warning(
                        f"District name is empty for list item index {i}. Skipping."
                    )
                    continue

                driver.execute_script(
                    "arguments[0].dispatchEvent(new MouseEvent('mouseover', {bubbles: true}));",
                    li,
                )

                risk_element = wait.until(
                    EC.visibility_of_element_located((By.ID, "risk"))
                )
                level_element = wait.until(
                    EC.visibility_of_element_located((By.ID, "stateText"))
                )

                risk_text = risk_element.text
                level_text = level_element.text

                scraped_data[district_name] = {
                    "poison_index": risk_text,
                    "poison_level": level_text,
                }
                logger.debug(
                    f"Scraped data for {district_name}: Index={risk_text}, Level={level_text}"
                )

            except (NoSuchElementException, TimeoutException) as e:
                logger.warning(
                    f"Could not process district '{district_name}' (index {i}): {e}. Skipping."
                )
                continue
            except Exception as e:
                logger.exception(
                    f"Unexpected error processing district '{district_name}' (index {i}): {e}. Skipping."
                )
                continue

        if not scraped_data:
            raise PoisonDataError("Failed to scrape any food poisoning data.")

        logger.info("Finished scraping food poisoning data successfully.")
        return scraped_data

    except PoisonDataError as pe:
        logger.error(f"Food poisoning scraping failed: {pe}")
        raise
    except Exception as e:
        logger.exception(f"Critical error during food poisoning scraping: {e}")
        raise PoisonDataError(f"Critical error during food poisoning scraping: {e}")
    finally:
        if driver:
            driver.quit()
            logger.info("Selenium WebDriver closed.")
