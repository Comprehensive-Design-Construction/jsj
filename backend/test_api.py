#!/usr/bin/env python
# coding: utf-8
"""
API 테스트 스크립트
다양한 엔드포인트에 요청을 보내고 결과를 확인합니다.
"""
import requests
import json
import time
import sys

# 기본 API URL
BASE_URL = "http://localhost:5000/api"
# 요청 타임아웃 설정 (초)
REQUEST_TIMEOUT = 15


def test_index_api():
    """건강 지수 API 테스트"""
    print("\n=== 건강 지수 API 테스트 ===")

    # 테스트 좌표 (서울 강남구)
    params = {"latitude": 37.498095, "longitude": 127.027610, "age": 30}

    url = f"{BASE_URL}/index"
    print(f"요청 URL: {url}")
    print(f"파라미터: {params}")

    try:
        start_time = time.time()
        response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
        elapsed = time.time() - start_time

        print(f"응답 시간: {elapsed:.2f}초")
        print(f"상태 코드: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(data)
            print(f"응답 데이터 요약:")
            # 주요 필드만 출력
            summary = {
                "region": data.get("region", {}),
                "indices": summarize_indices(data.get("indices", {})),
                "errors": data.get("errors", []),
            }
            print(json.dumps(summary, indent=2, ensure_ascii=False))
        else:
            print(f"오류 응답: {response.text}")
    except requests.exceptions.Timeout:
        print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
    except requests.exceptions.ConnectionError:
        print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
    except Exception as e:
        print(f"요청 실패: {e}")


def test_env_map_api():
    """환경 지도 API 테스트"""
    print("\n=== 환경 지도 API 테스트 ===")

    # 테스트할 환경 유형
    env_types = ["fine_dust", "uv"]

    for env_type in env_types:
        params = {"env_type": env_type, "force_refresh": "false"}

        url = f"{BASE_URL}/env_map"
        print(f"\n요청 URL: {url}")
        print(f"파라미터: {params}")

        try:
            start_time = time.time()
            response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
            elapsed = time.time() - start_time

            print(f"응답 시간: {elapsed:.2f}초")
            print(f"상태 코드: {response.status_code}")

            if response.status_code == 200:
                data = response.json()
                # HTML 내용은 너무 길어서 생략
                html_content = data.get("env_map_html", "")
                if html_content:
                    html_preview = (
                        html_content[:100] + "..."
                        if len(html_content) > 100
                        else html_content
                    )
                    data["env_map_html"] = html_preview

                print(f"응답 데이터:")
                print(json.dumps(data, indent=2, ensure_ascii=False))
            else:
                print(f"오류 응답: {response.text}")
        except requests.exceptions.Timeout:
            print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
        except requests.exceptions.ConnectionError:
            print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
        except Exception as e:
            print(f"요청 실패: {e}")


def test_map_api():
    """대피소 지도 API 테스트"""
    print("\n=== 대피소 지도 API 테스트 ===")

    # 테스트 좌표 (서울 강남구)
    params = {
        "latitude": 37.498095,
        "longitude": 127.027610,
        "disaster_type": "EARTHQUAKE",
        "radius_km": 2.0,
    }

    url = f"{BASE_URL}/map"
    print(f"요청 URL: {url}")
    print(f"파라미터: {params}")

    try:
        start_time = time.time()
        response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
        elapsed = time.time() - start_time

        print(f"응답 시간: {elapsed:.2f}초")
        print(f"상태 코드: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            # HTML 내용은 너무 길어서 생략
            if "shelter_map_html" in data:
                html_preview = (
                    data["shelter_map_html"][:100] + "..."
                    if len(data["shelter_map_html"]) > 100
                    else data["shelter_map_html"]
                )
                data["shelter_map_html"] = html_preview

            print(f"응답 데이터:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            print(f"오류 응답: {response.text}")
    except requests.exceptions.Timeout:
        print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
    except requests.exceptions.ConnectionError:
        print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
    except Exception as e:
        print(f"요청 실패: {e}")


def summarize_indices(indices):
    """건강 지수 데이터를 요약하는 함수"""
    if not indices:
        return {}

    # 오류가 있는 경우
    if "error" in indices:
        return {"error": indices["error"]}

    # 주요 지수만 선택하여 요약
    summary = {}

    if "apparent_temperature" in indices:
        summary["체감온도"] = indices["apparent_temperature"]

    if "food_poisoning_risk" in indices:
        summary["식중독위험"] = indices["food_poisoning_risk"]

    if "cold_index_level" in indices:
        summary["감기지수"] = indices["cold_index_level"]

    if "stroke_index_level" in indices:
        summary["뇌졸중지수"] = indices["stroke_index_level"]

    return summary


if __name__ == "__main__":
    print("API 테스트 시작...")

    # 명령줄 인수로 특정 테스트만 실행할 수 있음
    if len(sys.argv) > 1:
        test_name = sys.argv[1].lower()
        if test_name == "index":
            test_index_api()
        elif test_name == "env":
            test_env_map_api()
        elif test_name == "map":
            test_map_api()
        else:
            print(f"알 수 없는 테스트: {test_name}")
            print("사용 가능한 테스트: index, env, map")
    else:
        # 모든 테스트 실행
        test_index_api()
        test_env_map_api()
        test_map_api()

    print("\nAPI 테스트 완료!")
