"""
수정 사항
1. 반경 내 필터 기능
2. 직선거리 x 장애물 고려 최단거리
"""

from shelter import Shelter
from disaster import DisasterType, DisasterLevel, Disaster, DisasterManager
from weather import WeatherData

from geopandas import GeoSeries
from geopy.distance import geodesic
from shapely.geometry import Point
import os
import warnings

import osmnx as ox
import networkx as nx
import folium

warnings.filterwarnings("ignore")


def get_shelter(
    data_path: str, lon_column: str = "경도", lat_column: str = "위도"
) -> Shelter:
    shelter = Shelter(data_path, "./datasets/shelter")
    shelter.load_data()
    shelter.create_geodataframe(lon_column, lat_column)
    return shelter


def load_all_shelters() -> dict[DisasterType, Shelter]:
    """모든 유형의 대피소 데이터를 로드합니다."""
    shelters = {
        DisasterType.COLD_WAVE: get_shelter("cold_wave.csv"),
        DisasterType.HEAT_WAVE: get_shelter("heat_wave.csv"),
        DisasterType.FINE_DUST: get_shelter("fine_dust_prepared.csv"),
        DisasterType.FLOOD: get_shelter("flood_prepared.csv"),
        DisasterType.EARTHQUAKE: get_shelter("earthquake.csv"),
    }

    # 미세먼지 대피소 데이터의 결측치 제거
    if DisasterType.FINE_DUST in shelters:
        shelters[DisasterType.FINE_DUST].df.dropna(
            subset=["경도", "위도"], inplace=True
        )
        shelters[DisasterType.FINE_DUST].gdf = shelters[
            DisasterType.FINE_DUST
        ].gdf.dropna(subset=["경도", "위도"])

    return shelters


def filter_local_shelters(
    all_shelters: dict[DisasterType, Shelter], user_location: Point, radius: float
) -> dict[DisasterType, Shelter]:
    """사용자 위치로부터 지정 반경 내의 대피소만 필터링합니다."""
    local_shelters = {}
    local_shelter_counts = {}

    for disaster_type, shelter in all_shelters.items():
        # 새로운 Shelter 객체를 생성하고 인덱스 필터링 후 GeoDataFrame 할당
        local_shelter = Shelter(shelter.data_path.name, "../../datasets/map/shelter")
        indices = [
            index
            for index, row in shelter.gdf.iterrows()
            if geodesic(
                (user_location.y, user_location.x), (row.geometry.y, row.geometry.x)
            ).kilometers
            <= radius
        ]
        local_shelter.gdf = shelter.gdf.iloc[indices]
        local_shelters[disaster_type] = local_shelter
        local_shelter_counts[disaster_type] = (
            len(local_shelter.gdf) if local_shelter.gdf is not None else 0
        )

    # 대피소가 하나도 없으면 전체 데이터를 반환
    shelter_dict = {
        disaster_type: (
            local_shelters[disaster_type]
            if local_shelter_counts[disaster_type] > 0
            else all_shelters[disaster_type]
        )
        for disaster_type in all_shelters.keys()
    }
    return shelter_dict


def simulate_disaster() -> DisasterManager:
    """날씨 데이터를 기반으로 재난을 시뮬레이션하고 재난 정보를 관리합니다."""
    manager = DisasterManager()
    weather = WeatherData()
    weather.simulate_current_weather()
    is_disaster, disaster_type_str, disaster_details = (
        weather.check_disaster_conditions()
    )

    if is_disaster:
        disaster_type_map = {
            "HEAT_WAVE": DisasterType.HEAT_WAVE,
            "COLD_WAVE": DisasterType.COLD_WAVE,
            "FINE_DUST": DisasterType.FINE_DUST,
            "FLOOD": DisasterType.FLOOD,
        }
        disaster_type = disaster_type_map.get(disaster_type_str, DisasterType.HEAT_WAVE)

        level_map = {
            "NORMAL": DisasterLevel.NORMAL,
            "WATCH": DisasterLevel.WATCH,
            "WARNING": DisasterLevel.WARNING,
            "SEVERE": DisasterLevel.SEVERE,
        }
        disaster_level = level_map.get(disaster_details["level"], DisasterLevel.WATCH)

        disaster = Disaster(disaster_type)
        disaster.update_level(disaster_level)
        disaster.set_region("서울특별시")

        for key, value in disaster_details.items():
            if key != "level":
                disaster.add_detail(key, value)

        manager.add_disaster(disaster)
        print(f"[재난 발생] {disaster_type_str}: {disaster_details['details']}")

    else:
        # 테스트용 폭염 재난 추가
        heat_disaster = Disaster(DisasterType.HEAT_WAVE)
        heat_disaster.update_level(DisasterLevel.WARNING)
        heat_disaster.set_region("서울특별시")
        heat_disaster.add_detail("temperature", "38.5°C")
        heat_disaster.add_detail("humidity", "85%")
        manager.add_disaster(heat_disaster)
        print("[테스트 재난 추가] 폭염 경보: 현재 기온 38.5°C")

    return manager


def extract_closest_shelter_within_radius(
    local_shelters: dict[DisasterType, Shelter],
    user_location: Point,
    manager: DisasterManager,
    network_radius: float,  # 단위: km
):
    """도로 네트워크를 통해 지정 반경 내 가장 가까운 대피소를 찾습니다."""
    graph = ox.graph_from_point(
        (user_location.y, user_location.x),
        dist=network_radius * 1000,
        network_type="walk",
    )
    user_node = ox.distance.nearest_nodes(graph, user_location.x, user_location.y)

    closest_shelter = None
    min_distance = float("inf")
    disaster = manager.recommend_shelter_type()
    shelter = local_shelters[disaster]

    for _, row in shelter.gdf.iterrows():
        try:
            shelter_node = ox.distance.nearest_nodes(
                graph, row.geometry.x, row.geometry.y
            )
            route_length = nx.shortest_path_length(
                graph, user_node, shelter_node, weight="length"
            )
            route_km = route_length / 1000.0

            if route_km <= network_radius and route_km < min_distance:
                min_distance = route_km
                closest_shelter = row
        except Exception:
            continue

    return closest_shelter, shelter, graph


def visualize_shelters_on_map(
    shelter: Shelter, closest_shelter, user_location: Point, disaster_type: DisasterType
) -> folium.Map:
    """
    Folium을 이용해 지도상에 사용자 위치, 대피소들을 꾸며서 표시합니다.
    모든 대피소를 우선 표시하고, 그 후 가장 가까운 대피소까지의 경로를 시각화합니다.
    재난 유형에 따라 마커 아이콘을 변경합니다.
    """
    # Font-Awesome 아이콘 스타일 (재난 유형별)
    icon_styles = {
        DisasterType.HEAT_WAVE: {"icon": "fire", "color": "red", "prefix": "fa"},
        DisasterType.COLD_WAVE: {"icon": "snowflake", "color": "blue", "prefix": "fa"},
        DisasterType.FINE_DUST: {"icon": "medkit", "color": "green", "prefix": "fa"},
        DisasterType.FLOOD: {"icon": "tint", "color": "cadetblue", "prefix": "fa"},
        DisasterType.EARTHQUAKE: {
            "icon": "exclamation-triangle",
            "color": "orange",
            "prefix": "fa",
        },
    }
    default_style = {"icon": "home", "color": "gray", "prefix": "fa"}
    style = icon_styles.get(disaster_type, default_style)

    fmap = folium.Map(location=(user_location.y, user_location.x), zoom_start=14)

    # 사용자 위치 마커
    folium.CircleMarker(
        location=(user_location.y, user_location.x),
        radius=8,
        popup=folium.Popup("<b>현재 위치</b>", parse_html=True),
        color="blue",
        fill=True,
        fill_color="blue",
    ).add_to(fmap)

    # 모든 대피소 마커 표시
    for idx, row in shelter.gdf.iterrows():
        lat = row.geometry.y
        lon = row.geometry.x

        title = "대피소"
        if closest_shelter is not None and idx == closest_shelter.name:
            title = "가장 가까운 대피소"

        popup_html = (
            f"<div style='font-family: sans-serif;'>"
            f"<h4 style='margin-bottom: 2px;'>{title}</h4>"
            f"<p style='margin:0;'>위도: {lat:.4f}<br>경도: {lon:.4f}</p>"
            f"</div>"
        )
        popup = folium.Popup(popup_html, parse_html=True)

        # 가까운 대피소는 별도 스타일로 표시
        if closest_shelter is not None and idx == closest_shelter.name:
            marker_icon = folium.Icon(color="black", icon="star", prefix="fa")
        else:
            marker_icon = folium.Icon(
                color=style["color"], icon=style["icon"], prefix=style["prefix"]
            )
        folium.Marker(location=(lat, lon), popup=popup, icon=marker_icon).add_to(fmap)

    # 만약 가장 가까운 대피소가 존재한다면 사용자 위치와의 경로를 폴리라인으로 시각화합니다.
    if closest_shelter is not None:
        user_coord = (user_location.y, user_location.x)
        shelter_coord = (closest_shelter.geometry.y, closest_shelter.geometry.x)
        folium.PolyLine(
            locations=[user_coord, shelter_coord], color="black", weight=2.5, opacity=1
        ).add_to(fmap)

    return fmap


def run_pipeline():
    """전체 파이프라인 흐름을 실행합니다."""
    # 사용자 위치 (예: 서울 시청 좌표)
    user_location = Point(126.9780, 37.5665)

    # 사용자로부터 필터 반경 입력 (기본값 5km)
    try:
        filter_radius = float(input("대피소 필터링 반경(km): ") or 5)
    except Exception:
        filter_radius = 5

    # 대피소 데이터 로드 및 사용자 지정 반경 내 필터링
    all_shelters = load_all_shelters()
    local_shelters = filter_local_shelters(
        all_shelters, user_location, radius=filter_radius
    )

    # 재난 시뮬레이션 수행
    disaster_manager = simulate_disaster()

    # 도로 네트워크 내 지정 반경(입력 반경)에서 가장 가까운 대피소 추출
    closest_shelter, selected_shelter, network_graph = (
        extract_closest_shelter_within_radius(
            local_shelters,
            user_location,
            disaster_manager,
            network_radius=filter_radius,
        )
    )

    # 재난 유형에 따라 마커 스타일 결정
    recommended_type = (
        disaster_manager.recommend_shelter_type() or DisasterType.HEAT_WAVE
    )

    # 대피소 지도 생성 (모두 표시 후, 가장 가까운 대피소까지 경로 추가)
    fmap = visualize_shelters_on_map(
        selected_shelter, closest_shelter, user_location, recommended_type
    )
    output_path = "shelter_map.html"
    fmap.save(output_path)
    print(f"지도가 {output_path} 파일로 저장되었습니다.")


if __name__ == "__main__":
    run_pipeline()
