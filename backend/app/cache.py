import threading
from datetime import datetime, timezone
import copy
import logging
from typing import Any, Dict, Optional

# 로깅 설정
logger = logging.getLogger(__name__)

# 스레드 간의 동시 접근을 막기 위해 Lock 사용
cache_lock = threading.Lock()

# 캐시 데이터 저장소 통합
cache_data = {
    "fine_dust": {"data": {}, "last_updated": None},
    "food_poisoning": {"data": {}, "last_updated": None},
    "uv": {"data": {}, "last_updated": None},
    "fine_dust_map": {"data": None, "last_updated": None},
    "uv_map": {"data": None, "last_updated": None},
}


def _update_cache(cache_type: str, data: Any) -> bool:
    """공통 캐시 업데이트 함수

    Args:
        cache_type: 업데이트할 캐시 유형 ('fine_dust', 'food_poisoning', 'uv', 'fine_dust_map', 'uv_map')
        data: 저장할 데이터

    Returns:
        bool: 업데이트 성공 여부
    """
    with cache_lock:
        if data is None or (isinstance(data, dict) and data.get("error")):
            logger.warning(
                f"Not updating {cache_type} cache: data is None or contains error"
            )
            return False

        try:
            # 캐시 데이터 업데이트 (깊은 복사를 통해 참조 문제 방지)
            if isinstance(data, dict):
                cache_data[cache_type]["data"] = copy.deepcopy(data)
            else:
                # 문자열이나 기본 타입은 직접 할당
                cache_data[cache_type]["data"] = data

            # 업데이트 시간 기록
            cache_data[cache_type]["last_updated"] = datetime.now(timezone.utc)

            logger.info(
                f"{cache_type.replace('_', ' ').title()} cache updated at {cache_data[cache_type]['last_updated']} UTC"
            )
            return True
        except Exception as e:
            logger.error(f"Error updating {cache_type} cache: {e}")
            return False


def _get_cache(cache_type: str) -> Dict[str, Any]:
    """공통 캐시 조회 함수

    Args:
        cache_type: 조회할 캐시 유형

    Returns:
        dict: 캐시된 데이터의 딥 카피
    """
    with cache_lock:
        # 캐시 정보 로깅
        if cache_data[cache_type]["last_updated"]:
            age_seconds = (
                datetime.now(timezone.utc) - cache_data[cache_type]["last_updated"]
            ).total_seconds()
            logger.debug(
                f"Cache {cache_type}: age={age_seconds:.1f}s, has_data={bool(cache_data[cache_type]['data'])}"
            )

        # 깊은 복사를 통해 반환하여 외부에서 캐시 직접 수정을 방지
        result = {"data": None, "last_updated": cache_data[cache_type]["last_updated"]}

        # 데이터가 있는 경우만 깊은 복사
        if cache_data[cache_type]["data"]:
            if isinstance(cache_data[cache_type]["data"], dict):
                result["data"] = copy.deepcopy(cache_data[cache_type]["data"])
            else:
                # 문자열과 같은 불변 타입은 직접 복사
                result["data"] = cache_data[cache_type]["data"]

        return result


# 캐시 업데이트 함수 (타입에 따라 적절한 캐시 저장소 선택)
def update_fine_dust_map_cache(data: Any) -> bool:
    return _update_cache("fine_dust_map", data)


def update_uv_map_cache(data: Any) -> bool:
    return _update_cache("uv_map", data)


def update_uv_cache(data: Dict[str, Any]) -> bool:
    return _update_cache("uv", data)


def update_fine_dust_cache(data: Dict[str, Any]) -> bool:
    return _update_cache("fine_dust", data)


def update_food_poisoning_cache(data: Dict[str, Any]) -> bool:
    return _update_cache("food_poisoning", data)


# 캐시 조회 함수
def get_uv_cache() -> Dict[str, Any]:
    return _get_cache("uv")


def get_fine_dust_cache() -> Dict[str, Any]:
    return _get_cache("fine_dust")


def get_food_poisoning_cache() -> Dict[str, Any]:
    return _get_cache("food_poisoning")


def get_uv_map_cache() -> Dict[str, Any]:
    return _get_cache("uv_map")


def get_fine_dust_map_cache() -> Dict[str, Any]:
    return _get_cache("fine_dust_map")


def clear_cache(cache_type: Optional[str] = None) -> None:
    """캐시를 초기화하는 함수

    Args:
        cache_type: 초기화할 캐시 유형, None이면 모든 캐시 초기화
    """
    with cache_lock:
        if cache_type:
            if cache_type in cache_data:
                cache_data[cache_type]["data"] = (
                    {} if cache_type not in ["fine_dust_map", "uv_map"] else None
                )
                cache_data[cache_type]["last_updated"] = None
                logger.info(f"Cache {cache_type} cleared")
            else:
                logger.warning(f"Unknown cache type: {cache_type}")
        else:
            # 모든 캐시 초기화
            for key in cache_data:
                cache_data[key]["data"] = (
                    {} if key not in ["fine_dust_map", "uv_map"] else None
                )
                cache_data[key]["last_updated"] = None
            logger.info("All caches cleared")
