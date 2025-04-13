import threading
from datetime import datetime, timezone

# 식중독 지수 데이터를 저장할 딕셔너리와 마지막 업데이트 시간
# 스레드 간의 동시 접근을 막기 위해 Lock 사용
food_poisoning_cache = {"data": {}, "last_updated": None}
cache_lock = threading.Lock()


def update_food_poisoning_cache(data: dict):
    """캐시를 업데이트하는 함수"""
    with cache_lock:
        # 에러가 포함된 데이터는 업데이트하지 않거나 별도 처리 가능
        if data and not data.get("error"):
            food_poisoning_cache["data"] = data
            food_poisoning_cache["last_updated"] = datetime.now(timezone.utc)
            print(
                f"Food poisoning cache updated at {food_poisoning_cache['last_updated']} UTC"
            )
        else:
            print("Received data with error or empty data, cache not updated.")


def get_food_poisoning_cache() -> dict:
    """현재 캐시된 데이터를 반환하는 함수"""
    with cache_lock:
        # 깊은 복사를 통해 반환하여 외부에서 캐시 직접 수정을 방지 (선택 사항)
        # import copy
        # return copy.deepcopy(food_poisoning_cache)
        return food_poisoning_cache  # 간단히 반환
