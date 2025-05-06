import asyncio
import folium
from shapely.geometry import Point
import traceback
from typing import Dict, Optional, Tuple
import geopandas as gpd  # 추가

# 모듈 임포트
import config
from config.settings import settings
from core.shelter.shelter_loader import load_shelter_by_type
from core.shelter.map_visualizer import create_shelter_map


async def _generate_single_map_html(
    latitude: float, longitude: float, disaster_type: str, radius_km: float
) -> Tuple[str, Optional[str]]:
    """
    단일 재난 유형에 대한 지도를 생성하고 (유형, HTML) 튜플을 반환합니다.
    """
    user_location = Point(longitude, latitude)
    map_html: Optional[str] = None
    shelter_obj = None
    shelter_gdf_filtered: Optional[gpd.GeoDataFrame] = (
        None  # 변경됨: 필터링된 GDF 저장 변수
    )

    print(f"\n--- 지도 생성 시작: {disaster_type} (반경: {radius_km}km) ---")
    try:
        # 1. 대피소 데이터 로드 (캐싱 활용)
        shelter_obj = load_shelter_by_type(disaster_type)
        if shelter_obj.gdf is None or shelter_obj.gdf.empty:
            print(f"  {disaster_type}: 로드된 유효 대피소 데이터 없음.")
            # 대피소 없어도 빈 지도 생성 (사용자 위치만 표시)
            fmap = create_shelter_map(
                shelter_gdf=None,  # 변경됨: 필터링된 GDF 없음
                user_location=user_location,
                disaster_type=disaster_type,
                radius_km=radius_km,
            )

            # 지도에 대피소 없음을 알리는 메시지 추가 (선택 사항)
            folium.map.Marker(
                location=(latitude, longitude),
                icon=folium.features.DivIcon(
                    icon_size=(150, 36),
                    icon_anchor=(0, 0),
                    html=f'<div style="position: absolute; bottom: 10px; left: -75px; width: 150px; text-align: center; background-color: white; padding: 2px; border-radius: 3px; box-shadow: 1px 1px 3px rgba(0,0,0,0.3); font-size: 11px;">{disaster_type} 대피소 없음</div>',
                ),
            ).add_to(fmap)
            map_html = fmap._repr_html_()
            return disaster_type, map_html

        # 2. 반경 내 대피소 필터링
        try:
            shelter_gdf_filtered = shelter_obj.get_filtered_by_radius(
                user_location, radius_km
            )
            if shelter_gdf_filtered is None or shelter_gdf_filtered.empty:
                print(f"  {disaster_type}: 반경 {radius_km}km 내 대피소 없음.")
                # 필터링 결과 없으면 shelter_gdf_filtered는 None 또는 빈 GDF 상태 유지
            else:
                print(
                    f"  {disaster_type}: 반경 내 {len(shelter_gdf_filtered)}개 대피소 필터링됨."
                )
        except AttributeError:
            print(
                f"오류: Shelter 객체에 'get_filtered_by_radius' 메서드가 없습니다. 필터링 없이 전체 데이터를 사용합니다."
            )
            # 필터링 실패 시, 지도에는 모든 대피소를 표시할지 결정 (여기서는 필터링 안된 원본 사용하지 않음 - 반경 필터링이 핵심 요구사항)
            shelter_gdf_filtered = None  # 필터링 실패 시 None 처리 (또는 빈 GDF)
        except Exception as filter_e:
            print(f"오류 ({disaster_type}): 반경 필터링 중 오류 발생: {filter_e}")
            shelter_gdf_filtered = None  # 오류 시 None 처리

        # 3. 가장 가까운 대피소 탐색 로직 (제거됨)
        # closest_shelter, travel_time_sec, travel_distance_m, route_coords = (
        #     await find_closest_shelter_with_tmap(shelter_gdf_for_api, user_location)
        # ) # 제거됨

        # 4. 지도 시각화 (Folium) - 필터링된 결과만 전달
        fmap = create_shelter_map(
            shelter_gdf=shelter_gdf_filtered,  # 변경됨: 필터링된 대피소 GDF 전달
            user_location=user_location,
            disaster_type=disaster_type,
            radius_km=radius_km,
            # 제거됨: closest_shelter_row, min_distance_m, min_time_sec, route_coordinates 인자 제거
        )
        fmap.save("asd.html")  # 필요 시 디버깅용 저장
        map_html = fmap._repr_html_()

    except ValueError as ve:  # load_shelter_by_type 등에서 발생
        print(f"오류 ({disaster_type}): {ve}")
        # 오류 발생 시 기본 지도 반환
        fmap = create_shelter_map(
            None, user_location, disaster_type, radius_km=radius_km
        )
        folium.map.Popup(f"오류: {disaster_type} 지도 생성 실패 ({ve})").add_to(fmap)
        map_html = fmap._repr_html_()
    except Exception as e:
        print(f"예상치 못한 오류 ({disaster_type}): {e}")
        traceback.print_exc()  # 개발 시 상세 로그 확인
        # 오류 발생 시 기본 지도 반환
        fmap = create_shelter_map(
            None, user_location, disaster_type, radius_km=radius_km
        )
        folium.map.Popup(f"오류: {disaster_type} 지도 생성 중 문제 발생").add_to(fmap)
        map_html = fmap._repr_html_()

    print(f"--- 지도 생성 완료: {disaster_type} ---")
    return disaster_type, map_html


# --- 메인 서비스 함수 ---
async def generate_maps_for_all_disasters(
    latitude: float, longitude: float, radius_km: float = 2.0  # 기본 반경 1km
) -> Dict[str, Optional[str]]:
    """
    모든 정의된 재난 유형에 대해 병렬로 대피소 지도를 생성합니다.

    Args:
        latitude: 사용자 위치 위도
        longitude: 사용자 위치 경도
        radius_km: 대피소 필터링 반경 (km)

    Returns:
        딕셔너리: {재난 유형: 지도 HTML 문자열 또는 None}
    """
    print(
        f"\n===== 모든 재난 유형 지도 생성 시작 (위도: {latitude}, 경도: {longitude}, 반경: {radius_km}km) ====="
    )
    # 설정 파일에서 재난 유형 목록 가져오기
    disaster_types_to_process = config.ALL_DISASTER_TYPES

    tasks = []
    for disaster_type in disaster_types_to_process:
        # 각 재난 유형별 지도 생성 함수를 비동기 태스크로 등록
        task = _generate_single_map_html(latitude, longitude, disaster_type, radius_km)
        tasks.append(task)

    # 모든 지도 생성 태스크를 병렬로 실행하고 결과 수집
    # 결과는 [(disaster_type, map_html), (disaster_type, map_html), ...] 형태의 리스트
    results = await asyncio.gather(*tasks)

    # 결과를 딕셔너리로 변환
    maps_html_dict: Dict[str, Optional[str]] = {
        result[0]: result[1] for result in results if result
    }

    successful_maps = sum(1 for html in maps_html_dict.values() if html is not None)
    print(
        f"===== 지도 생성 완료: 총 {len(disaster_types_to_process)}개 유형 중 {successful_maps}개 지도 생성 성공 ====="
    )

    return maps_html_dict
