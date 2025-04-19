import requests
from datetime import datetime
import asyncio
import os
import json
import pandas as pd
from typing import Optional
from dotenv import load_dotenv

load_dotenv()


async def _fetch_uv_sync() -> Optional[dict]:
    """
    :return: 구: h0
    """
    path = os.path.join(
        # ".",
        ".",
        "datasets",
        "weather",
        "observatory_UV.csv",
    )
    df = pd.read_csv(path)
    code_gu = zip(df["행정구역코드"].values, df["2단계"].values)

    now = datetime.now()
    hour = now.hour // 3 * 3
    base_url = "http://apis.data.go.kr/1360000/LivingWthrIdxServiceV4/getUVIdxV4"
    params = {
        "dataType": "JSON",
        "ServiceKey": os.getenv("OPEN_DATA_API_KEY"),
        "areaNo": None,
        "time": f"{now.strftime('%Y%m%d')}{hour:02d}",
    }

    results = {}

    for code, gu in code_gu:
        params["areaNo"] = str(code)
        print(f"Fetching UV index for {gu} (Code: {code})...")

        try:
            response = requests.get(
                base_url, params=params, timeout=10
            )  # 타임아웃 설정
            response.raise_for_status()  # HTTP 오류 발생 시 예외 발생 (4xx, 5xx)

            data = response.json()

            # 응답 구조 확인 및 데이터 추출 (API 문서 기반)

            items = data["response"].get("body", {}).get("items", {}).get("item")
            if items and isinstance(items, list) and len(items) > 0:
                uv_index_str = items[0].get("h0")
                if uv_index_str is not None and uv_index_str != "":
                    try:
                        results[gu] = int(uv_index_str)
                        print(f"  > Success: {gu} UV Index (h0) = {results[gu]}")
                    except ValueError:
                        print(
                            f"  > Warning: Could not convert UV index '{uv_index_str}' to integer for {gu}."
                        )
                        results[gu] = None  # 변환 실패 시 None 저장
                else:
                    print(
                        f"  > Info: UV index ('h0') value not found or empty in response for {gu}."
                    )
                    results[gu] = None
            else:
                print(
                    f"  > Info: No UV index items found in the response body for {gu}."
                )
                results[gu] = None  # 아이템이 없으면 None 저장

        except requests.exceptions.Timeout:
            print(f"  > Error: Request timed out for {gu} ({code}).")
            results[gu] = None
        except requests.exceptions.HTTPError as http_err:
            print(f"  > Error: HTTP error occurred for {gu} ({code}): {http_err}")
            results[gu] = None
        except requests.exceptions.RequestException as req_err:
            print(f"  > Error: Request failed for {gu} ({code}): {req_err}")
            results[gu] = None
        except json.JSONDecodeError:
            print(
                f"  > Error: Failed to decode JSON response for {gu} ({code}). Response text: {response.text[:200]}..."
            )  # 응답 일부 출력
            results[gu] = None
        except Exception as e:  # 기타 예외 처리
            print(f"  > Error: An unexpected error occurred for {gu} ({code}): {e}")
            results[gu] = None

    return results


if __name__ == "__main__":
    print(asyncio.run(_fetch_uv_sync()))
