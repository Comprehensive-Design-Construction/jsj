import asyncio
import aiohttp
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
import traceback
from typing import Tuple, Any, Optional, List

# 설정 파일 임포트
from config.settings import settings


async def _fetch_single_route_data(
    session: aiohttp.ClientSession,
    start_lon: float,
    start_lat: float,
    end_lon: float,
    end_lat: float,
    shelter_index: Any,
) -> Optional[
    Tuple[Any, Optional[int], Optional[int], Optional[List[List[float]]]]
]:  # 경로 좌표 반환 타입 추가
    """
    단일 출발지-목적지에 대한 TMAP 보행자 경로 정보를 비동기로 요청합니다.
    결과: (인덱스, 시간(초), 거리(미터), 경로좌표[[lon, lat],...]) 튜플 또는 None
    """
    payload = {
        "startX": start_lon,
        "startY": start_lat,
        "endX": end_lon,
        "endY": end_lat,
        "reqCoordType": "WGS84GEO",
        "resCoordType": "WGS84GEO",
        "startName": "출발지",
        "endName": "도착지",
    }
    headers = {
        "accept": "application/json",
        "appKey": settings.TMAP_API_KEY,
        "content-type": "application/json",
    }

    route_coordinates: List[List[float]] = []  # 경로 좌표 저장 리스트

    try:
        async with session.post(
            settings.TMAP_PEDESTRIAN_ROUTE_URL,
            json=payload,
            headers=headers,
            timeout=15,
        ) as response:  # 타임아웃 약간 증가
            if response.status != 200:
                print(
                    f"오류: TMAP API 호출 실패 (Shelter Index: {shelter_index}, Status: {response.status})"
                )
                return None

            data = await response.json()

            if data.get("features") and len(data["features"]) > 0:
                properties = data["features"][0].get("properties", {})
                total_time_sec = properties.get("totalTime")
                total_distance_m = properties.get("totalDistance")

                # 경로 좌표 추출 (LineString 타입의 geometry coordinates)
                for feature in data["features"]:
                    geometry = feature.get("geometry", {})
                    if geometry.get("type") == "LineString":
                        coords = geometry.get("coordinates", [])
                        if coords:
                            # LineString의 coordinates는 [lon, lat] 쌍의 리스트
                            route_coordinates.extend(
                                coords
                            )  # 모든 LineString 좌표를 이어붙임

                # 거리 정보가 유효해야 함
                if total_distance_m is not None:
                    # 경로 좌표가 없더라도 거리/시간 정보는 반환할 수 있음
                    return (
                        shelter_index,
                        total_time_sec,
                        total_distance_m,
                        route_coordinates if route_coordinates else None,
                    )
                else:
                    print(
                        f"  API Warning for Shelter Index {shelter_index}: No 'totalDistance' in response properties."
                    )
                    return None
            else:
                print(
                    f"  API Warning for Shelter Index {shelter_index}: No 'features' found in response."
                )
                return None

    except aiohttp.ClientError as e:
        print(f"네트워크 오류: TMAP API 호출 중 (Shelter Index: {shelter_index}): {e}")
        return None
    except asyncio.TimeoutError:
        print(f"타임아웃 오류: TMAP API 호출 중 (Shelter Index: {shelter_index})")
        return None
    except Exception as e:
        print(
            f"예상치 못한 오류: TMAP API 처리 중 (Shelter Index: {shelter_index}): {e}"
        )
        return None


async def find_closest_shelter_with_tmap(
    shelter_gdf: gpd.GeoDataFrame, user_location: Point
) -> tuple[
    Optional[pd.Series], Optional[int], Optional[int], Optional[List[List[float]]]
]:  # 경로 좌표 반환 타입 추가
    """
    주어진 대피소 목록에 대해 TMAP API를 병렬 호출하여 가장 가까운 대피소(거리 기준)를 찾습니다.
    반환값: (가장 가까운 대피소(Series), 시간(초), 거리(미터), 경로좌표[[lon, lat],...]) 튜플.
            찾지 못한 경우 (None, None, None, None) 반환.
    """
    if shelter_gdf is None or shelter_gdf.empty:
        print("TMAP 클라이언트: 검색할 대피소 GeoDataFrame이 비어 있습니다.")
        return None, None, None, None

    start_lon, start_lat = user_location.x, user_location.y
    tasks = []

    async with aiohttp.ClientSession() as session:
        print(f"TMAP API: {len(shelter_gdf)}개 대피소에 대한 경로 탐색 요청 시작...")
        count = 0
        for index, row in shelter_gdf.iterrows():
            shelter_geom = row.geometry
            if (
                shelter_geom
                and isinstance(shelter_geom, Point)
                and shelter_geom.is_valid
            ):
                end_lon, end_lat = shelter_geom.x, shelter_geom.y
                task = _fetch_single_route_data(
                    session, start_lon, start_lat, end_lon, end_lat, index
                )
                tasks.append(task)
                count += 1

        if not tasks:
            print(
                "TMAP 클라이언트: 유효한 대피소 좌표가 없어 API를 호출할 수 없습니다."
            )
            return None, None, None, None

        print(f"TMAP API: 총 {len(tasks)}개의 유효한 대피소에 대해 API 호출 실행...")
        results = await asyncio.gather(*tasks)
        print(f"TMAP API: {len(results)}개의 응답 수신 완료.")

    # 유효한 결과 필터링 (API 성공 & 거리 정보(res[2]) 존재)
    valid_results = [res for res in results if res is not None and res[2] is not None]

    if not valid_results:
        print("TMAP API: API로부터 유효한 경로 거리 정보를 받지 못했습니다.")
        return None, None, None, None

    # 이동 거리(미터, res[2]) 기준으로 가장 가까운 결과 찾기
    # 결과 튜플 형식: (index, time, distance, route_coords)
    closest_result = min(valid_results, key=lambda res: res[2])  # 거리 기준 정렬

    closest_shelter_index = closest_result[0]
    min_time_sec = closest_result[1]
    min_distance_m = closest_result[2]
    route_coords = closest_result[3]  # 가장 가까운 경로의 좌표 추출

    closest_shelter_row = shelter_gdf.loc[closest_shelter_index]

    print(
        f"TMAP API: 최단 거리 대피소 발견. 인덱스: {closest_shelter_index}, "
        f"거리: {min_distance_m} m ({min_distance_m / 1000:.2f} km), "
        f"경로 좌표 개수: {len(route_coords) if route_coords else 0}"  # 경로 좌표 개수 로깅
    )

    return (
        closest_shelter_row,
        min_time_sec,
        min_distance_m,
        route_coords,
    )  # 경로 좌표 반환
