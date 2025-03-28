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

warnings.filterwarnings("ignore")


def get_shelter(
    data_path: str,
    lon_column: str = "경도",
    lat_column: str = "위도",
):
    shelter = Shelter(data_path, "./datasets/shelter")
    shelter.load_data()
    shelter.create_geodataframe(lon_column, lat_column)

    return shelter


def load_all_shelters():
    """모든 유형의 대피소 데이터를 로드합니다."""
    shelters = {
        DisasterType.COLD_WAVE: get_shelter("cold_wave.csv"),
        DisasterType.HEAT_WAVE: get_shelter("heat_wave.csv"),
        DisasterType.FINE_DUST: get_shelter("fine_dust_prepared.csv"),
        DisasterType.FLOOD: get_shelter("flood_prepared.csv"),
        DisasterType.EARTHQUAKE: get_shelter("earthquake.csv"),
    }

    # 미세먼지 대피소 데이터에서 결측치 제거
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
):
    local_shelters = {}
    local_shelter_counts = {}

    for disaster_type, shelter in all_shelters.items():
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

    shelter_dict = {}
    for disaster_type in all_shelters.keys():
        shelter_dict[disaster_type] = (
            local_shelters[disaster_type]
            if local_shelter_counts[disaster_type] > 0
            else all_shelters[disaster_type]
        )

    return shelter_dict


def simulate_disaster():
    manager = DisasterManager()
    weather = WeatherData()
    weather_data = weather.simulate_current_weather()
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
    # 반경 network_radius km 내 도로 네트워크 로드 (단위: m)
    graph = ox.graph_from_point(
        (user_location.y, user_location.x),
        dist=network_radius * 1000,
        network_type="walk",
    )
    user_node = ox.distance.nearest_nodes(graph, user_location.x, user_location.y)

    closest_shelter = None
    min_distance = float("inf")

    # 재난 유형에 따른 대피소 선택
    disaster = manager.recommend_shelter_type()
    shelter = local_shelters[disaster]

    for _, row in shelter.gdf.iterrows():
        try:
            # 도로 네트워크 내에서 각 대피소와 연결된 노드 검색
            shelter_node = ox.distance.nearest_nodes(
                graph, row.geometry.x, row.geometry.y
            )
            route_length = nx.shortest_path_length(
                graph, user_node, shelter_node, weight="length"
            )
            route_km = route_length / 1000.0

            # 네트워크 내 경로 거리가 network_radius 이내인 대피소만 고려
            if route_km <= network_radius and route_km < min_distance:
                min_distance = route_km
                closest_shelter = row
        except Exception:
            continue

    return closest_shelter, shelter, graph


def visualize_shelters_on_map(shelter, closest_shelter, user_location):
    import folium

    map_center = (user_location.y, user_location.x)
    fmap = folium.Map(location=map_center, zoom_start=14)

    # 사용자 위치 마커 추가
    folium.Marker(
        location=map_center,
        popup="현재 위치",
        icon=folium.Icon(color="blue", icon="user"),
    ).add_to(fmap)

    # 대피소들의 마커 추가
    for idx, row in shelter.gdf.iterrows():
        lat = row.geometry.y
        lon = row.geometry.x

        if closest_shelter is not None and idx == closest_shelter.name:
            folium.Marker(
                location=(lat, lon),
                popup="가장 가까운 대피소",
                icon=folium.Icon(color="red", icon="info-sign"),
            ).add_to(fmap)
        else:
            folium.Marker(
                location=(lat, lon),
                popup="대피소",
                icon=folium.Icon(color="green", icon="home"),
            ).add_to(fmap)

    return fmap


if __name__ == "__main__":
    # 사용자 위치 (예: 서울 시청 좌표)
    user_location = Point(126.9780, 37.5665)

    # 대피소 데이터 로드 및 지역 필터링 (반경 5km 이내)
    all_shelters = load_all_shelters()
    local_shelters = filter_local_shelters(all_shelters, user_location, radius=5)

    # 재난 시뮬레이션 수행
    disaster_manager = simulate_disaster()

    # 반경 x km (예: 3km) 내 도로 네트워크를 이용하여 가장 가까운 대피소 추출
    network_radius = 3  # km
    closest_shelter, selected_shelter, network_graph = (
        extract_closest_shelter_within_radius(
            local_shelters, user_location, disaster_manager, network_radius
        )
    )

    # 지도 시각화 (대피소 및 사용자 위치 표시)
    fmap = visualize_shelters_on_map(selected_shelter, closest_shelter, user_location)
    fmap.save("shelter_map.html")
    print("지도가 shelter_map.html 파일로 저장되었습니다.")
