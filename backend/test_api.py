import requests
import json
import time
import sys
import html

# 기본 API URL
BASE_URL = "http://localhost:5000/api"
# 요청 타임아웃 설정 (초)
REQUEST_TIMEOUT = 15


def test_weather_api():
    """상세 날씨 API (/api/weather) 테스트"""
    print("\n=== 상세 날씨 API 테스트 ===")

    # 테스트 좌표 (서울 시청 근처)
    params = {"latitude": 37.5665, "longitude": 126.9780}

    url = f"{BASE_URL}/weather"  # 엔드포인트 경로 확인
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
            print(f"응답 데이터:")
            # 주요 응답 필드만 출력하거나, 전체 출력 후 주요 필드 확인
            print(json.dumps(data, indent=2, ensure_ascii=False))
            # 예시: 특정 필드 확인
            if data.get("measurements"):
                print(f"  - 현재 온도: {data['measurements'].get('temp')} °C")
            if data.get("weather_condition"):
                print(f"  - 날씨 설명: {data['weather_condition'].get('description')}")
        elif response.status_code == 422:  # 입력값 오류 (예: 좌표 범위 벗어남)
            print(f"입력값 오류 응답: {response.text}")
        else:
            print(f"오류 응답: {response.text}")
    except requests.exceptions.Timeout:
        print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
    except requests.exceptions.ConnectionError:
        print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
    except Exception as e:
        print(f"요청 실패: {e}")


def test_environment_uv_api():
    """지역별 UV 지수 API (/api/environment/uv) 테스트"""
    print("\n=== 지역별 UV 지수 API 테스트 ===")

    # 테스트 좌표 (서울 시청 근처)
    params = {"latitude": 37.5665, "longitude": 126.9780}

    url = f"{BASE_URL}/environment/uv"  # 엔드포인트 경로 확인
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
            print(f"응답 데이터:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            # 예시: 특정 필드 확인
            if data.get("region_info"):
                print(f"  - 조회 지역: {data['region_info'].get('gu')}")
            if data.get("uv_data"):
                print(f"  - UV 지수: {data['uv_data'].get('uv_index')}")
            print(f"  - 데이터 업데이트 시각: {data.get('last_updated')}")
        elif response.status_code == 422:  # 입력값 오류
            print(f"입력값 오류 응답: {response.text}")
        else:
            print(f"오류 응답: {response.text}")
            if response.status_code == 500 and "캐시에 없습니다" in response.text:
                print("  (참고: UV 데이터 캐시가 아직 생성되지 않았을 수 있습니다.)")

    except requests.exceptions.Timeout:
        print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
    except requests.exceptions.ConnectionError:
        print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
    except Exception as e:
        print(f"요청 실패: {e}")


def test_environment_fine_dust_api():
    """지역별 미세먼지 API (/api/environment/fine_dust) 테스트"""
    print("\n=== 지역별 미세먼지 API 테스트 ===")

    # 테스트 좌표 (서울 시청 근처)
    params = {"latitude": 37.5665, "longitude": 126.9780}

    url = f"{BASE_URL}/environment/fine_dust"  # 엔드포인트 경로 확인
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
            print(f"응답 데이터:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            # 예시: 특정 필드 확인
            if data.get("region_info"):
                print(f"  - 조회 지역: {data['region_info'].get('gu')}")
            if data.get("fine_dust_data"):
                print(f"  - 미세먼지(PM10): {data['fine_dust_data'].get('PM10')}")
                print(f"  - 초미세먼지(PM2.5): {data['fine_dust_data'].get('PM25')}")
                print(f"  - 등급: {data['fine_dust_data'].get('GRADE')}")
            print(f"  - 데이터 업데이트 시각: {data.get('last_updated')}")
        elif response.status_code == 422:  # 입력값 오류
            print(f"입력값 오류 응답: {response.text}")
        else:
            print(f"오류 응답: {response.text}")
            if response.status_code == 500 and "캐시에 없습니다" in response.text:
                print(
                    "  (참고: 미세먼지 데이터 캐시가 아직 생성되지 않았을 수 있습니다.)"
                )

    except requests.exceptions.Timeout:
        print(f"요청 타임아웃 (>{REQUEST_TIMEOUT}초)")
    except requests.exceptions.ConnectionError:
        print(f"연결 오류: API 서버가 실행 중인지 확인하세요 (URL: {url})")
    except Exception as e:
        print(f"요청 실패: {e}")


def test_index_api():
    """건강 지수 API 테스트"""
    print("\n=== 건강 지수 API 테스트 ===")

    # 테스트 좌표 (서울 강남구)
    params = {
        "latitude": 37.498095,
        "longitude": 127.027610,
<<<<<<< Updated upstream
        "age": "100",
        "user_type": ["비닐하우스", "실외작업자_도로"],
=======
        "age": 13,
        "user_type": ["실외작업자_건설현장"],
>>>>>>> Stashed changes
    }

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
    env_types = ["fine_dust", "uv", "flood_trace"]

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


def test_districts_api():
    """구 API"""
    print("\n=== 구 API 테스트 ===")

    url = f"{BASE_URL}/districts"
    print(f"요청 URL: {url}")

    try:
        start_time = time.time()
        response = requests.get(url, timeout=REQUEST_TIMEOUT)
        elapsed = time.time() - start_time

        print(f"응답 시간: {elapsed:.2f}초")
        print(f"상태 코드: {response.status_code}")

        if response.status_code == 200:
            data = response.json()

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


def test_dong_api():
    """동 API"""
    print("\n=== 동 API 테스트 ===")

    url = f"{BASE_URL}/dongs"
    params = {"gu": "중구"}
    print(f"요청 URL: {url}")

    try:
        start_time = time.time()
        response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
        elapsed = time.time() - start_time

        print(f"응답 시간: {elapsed:.2f}초")
        print(f"상태 코드: {response.status_code}")

        if response.status_code == 200:
            data = response.json()

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


def test_coords_api():
    """위경도 API"""
    print("\n=== 위경도 API 테스트 ===")

    url = f"{BASE_URL}/coordinates"
    params = {"gu": "중구", "dong": "명동"}
    print(f"요청 URL: {url}")

    try:
        start_time = time.time()
        response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
        elapsed = time.time() - start_time

        print(f"응답 시간: {elapsed:.2f}초")
        print(f"상태 코드: {response.status_code}")

        if response.status_code == 200:
            data = response.json()

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


# test_api.py 의 if __name__ == "__main__": 블록 수정 예시

if __name__ == "__main__":
    print("API 테스트 시작...")

    # 실행할 테스트 목록
    available_tests = {
        # "index": test_index_api,
<<<<<<< Updated upstream
        "env_map": test_env_map_api,  # 기존 환경 지도 테스트
=======
        # "env_map": test_env_map_api,  # 기존 환경 지도 테스트
>>>>>>> Stashed changes
        # "map": test_map_api,
        "weather": test_weather_api,  # 신규 상세 날씨 테스트
        # "uv": test_environment_uv_api,  # 신규 UV 테스트
        # "dust": test_environment_fine_dust_api,  # 신규 미세먼지 테스트
        # "district": test_districts_api,
        # "dong": test_dong_api,
        # "coord": test_coords_api,
    }

    tests_to_run = []

    # 명령줄 인수로 특정 테스트만 실행
    if len(sys.argv) > 1:
        for arg in sys.argv[1:]:
            test_name = arg.lower()
            if test_name in available_tests:
                tests_to_run.append(available_tests[test_name])
            else:
                print(f"알 수 없는 테스트: {test_name}")
    else:
        # 인수가 없으면 모든 테스트 실행
        tests_to_run = list(available_tests.values())

    if not tests_to_run and len(sys.argv) > 1:
        print("실행할 유효한 테스트가 지정되지 않았습니다.")
        print(f"사용 가능한 테스트: {', '.join(available_tests.keys())}")
    else:
        for test_func in tests_to_run:
            test_func()  # 선택된 테스트 함수 실행

    print("\nAPI 테스트 완료!")
