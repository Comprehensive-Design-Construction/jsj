# core/shelter/service.py
import warnings
import osmnx as ox
import networkx as nx
import folium
import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
from geopy.distance import geodesic
import asyncio
import traceback  # 에러 로깅용

from config import settings
from core.shelter.shelter import Shelter  # Shelter 클래스 임포트

warnings.filterwarnings("ignore")

# --- Helper Functions (기존 코드 재구성) ---


def _load_shelter_by_type(disaster_type: str) -> Shelter:
    """입력한 재난 유형에 해당하는 대피소 데이터만 로드합니다."""
    mapping = {  # 파일 이름은 실제 경로에 맞게 조정 필요
        "COLD_WAVE": "cold_wave.csv",
        "HEAT_WAVE": "heat_wave.csv",
        "FINE_DUST": "fine_dust_prepared.csv",
        "FLOOD": "flood_prepared.csv",
        "EARTHQUAKE": "earthquake.csv",
    }
    # 설정 파일에서 대피소 데이터 루트 경로 사용
    root_data_path = settings.SHELTER_ROOT_PATH

    if disaster_type not in mapping:
        raise ValueError(
            f"유효하지 않은 재난 유형입니다: {disaster_type}. 유효한 유형: {list(mapping.keys())}"
        )

    data_file = mapping[disaster_type]
    shelter = Shelter(data_file, root_data_path)
    shelter.load_data()
    # GeoDataFrame 생성 시 사용할 위경도 컬럼명 지정 (필요시 수정)
    shelter.create_geodataframe(lon_column="경도", lat_column="위도")

    # 특정 재난 유형별 추가 처리 (예: FINE_DUST)
    if disaster_type == "FINE_DUST":
        if shelter.gdf is not None and not shelter.gdf.empty:
            # 유효하지 않거나 비어있는 지오메트리 제거
            shelter.gdf = shelter.gdf[
                shelter.gdf.geometry.is_valid & ~shelter.gdf.geometry.is_empty
            ].copy()

    if shelter.gdf is None or shelter.gdf.empty:
        print(
            f"경고: {disaster_type} 유형의 대피소 데이터를 로드했으나 유효한 지리 정보가 없습니다."
        )
    return shelter


def _filter_shelter_by_radius(
    shelter: Shelter, user_location: Point, radius_km: float
) -> gpd.GeoDataFrame | None:
    """
    Shelter 객체 내의 get_filtered_by_radius 메서드를 사용합니다.
    반경 내 대피소가 없으면 빈 GeoDataFrame을 반환합니다.
    """
    print(f"Filtering shelters within {radius_km} km radius...")
    return shelter.get_filtered_by_radius(user_location, radius_km)


def _extract_closest_shelter_and_route(
    shelter_gdf: gpd.GeoDataFrame, user_location: Point, network_radius_km: float
):
    """
    도로 네트워크 내 지정 반경(network_radius km)에서 사용자로부터 가장 가까운 대피소를 찾습니다.
    가장 가까운 대피소 정보(GeoSeries), 네트워크 그래프, 최단 경로(노드 ID 리스트), 경로 거리(km)를 반환합니다.
    """
    if shelter_gdf is None or shelter_gdf.empty:
        print("경고: 검색할 대피소 데이터가 없습니다.")
        return None, None, None, None

    try:
        print(f"OSMnx: Downloading graph for radius {network_radius_km} km...")
        # 보행자 네트워크 다운로드 (시간이 오래 걸릴 수 있음)
        graph = ox.graph_from_point(
            (user_location.y, user_location.x),
            dist=network_radius_km * 1000,
            network_type="walk",
            simplify=True,
        )
        print("OSMnx: Graph downloaded.")

        # 사용자 위치에서 가장 가까운 네트워크 노드 찾기
        user_node = ox.nearest_nodes(graph, user_location.x, user_location.y)
        print(f"OSMnx: User's nearest node: {user_node}")

    except Exception as e:
        print(f"오류: 네트워크 그래프 생성 또는 사용자 노드 탐색 실패: {e}")
        return None, None, None, None  # 그래프 생성 실패 시 진행 불가

    closest_shelter_row = None
    min_distance_km = float("inf")
    shortest_route_nodes = None

    if "geometry" not in shelter_gdf.columns:
        raise ValueError("Shelter GeoDataFrame에 'geometry' 컬럼이 필요합니다.")

    # 유효한 대피소 좌표와 인덱스 추출
    valid_shelter_coords = []
    valid_shelter_indices = []
    for idx, geom in shelter_gdf.geometry.items():
        if geom and isinstance(geom, Point) and geom.is_valid:
            valid_shelter_coords.append((geom.x, geom.y))
            valid_shelter_indices.append(idx)

    if not valid_shelter_coords:
        print("경고: 유효한 대피소 좌표가 없습니다.")
        return None, graph, None, None

    try:
        # 대피소들의 가장 가까운 노드 일괄 계산
        shelter_nodes_list = ox.nearest_nodes(graph, *zip(*valid_shelter_coords))
        shelter_nodes_map = dict(zip(valid_shelter_indices, shelter_nodes_list))
        print(f"OSMnx: Calculated nearest nodes for {len(shelter_nodes_map)} shelters.")
    except Exception as e:
        print(f"경고: 대피소 최근접 노드 일괄 계산 실패: {e}. 개별 처리합니다.")
        shelter_nodes_map = {}  # 실패 시 빈 맵

    # 필터링된 대피소 목록 순회하며 최단 경로 계산 (시간 소요)
    print(f"NetworkX: Calculating shortest paths for {len(shelter_gdf)} shelters...")
    processed_count = 0
    for index, row in shelter_gdf.iterrows():
        shelter_geom = row.geometry
        if not (
            shelter_geom and isinstance(shelter_geom, Point) and shelter_geom.is_valid
        ):
            continue

        try:
            # 대피소 노드 가져오기 (캐시 또는 개별 계산)
            shelter_node = shelter_nodes_map.get(index)
            if shelter_node is None:
                shelter_node = ox.nearest_nodes(graph, shelter_geom.x, shelter_geom.y)

            # 최단 경로 길이 계산
            route_length_meters = nx.shortest_path_length(
                graph, source=user_node, target=shelter_node, weight="length"
            )
            route_km = route_length_meters / 1000.0

            # 현재까지 가장 가까운 경로인지 확인
            if route_km < min_distance_km:
                min_distance_km = route_km
                closest_shelter_row = row  # GeoSeries 반환
                # 가장 가까운 경로가 갱신될 때만 경로 노드 리스트 계산 (최적화)
                shortest_route_nodes = nx.shortest_path(
                    graph, source=user_node, target=shelter_node, weight="length"
                )

            processed_count += 1
            if processed_count % 20 == 0:  # 로그 출력 빈도 조절
                print(f"  Processed {processed_count}/{len(shelter_gdf)} shelters...")

        except nx.NetworkXNoPath:
            continue  # 경로 없는 경우 다음 대피소로
        except Exception as e:
            print(f"오류: 대피소(인덱스 {index}) 처리 중 오류: {e}")
            continue

    if closest_shelter_row is not None:
        print(
            f"NetworkX: Shortest path found. Shelter Index: {closest_shelter_row.name}, Distance: {min_distance_km:.2f} km"
        )
    else:
        print(f"NetworkX: No reachable shelter found within the network radius.")

    # GeoSeries, graph 객체, 노드 리스트, 거리(km) 반환
    return closest_shelter_row, graph, shortest_route_nodes, min_distance_km


def _visualize_shelters_on_map(
    shelter_gdf: gpd.GeoDataFrame | None,  # 필터링된 또는 전체 GDF
    closest_shelter_row: pd.Series | None,  # 가장 가까운 대피소 정보 (GeoSeries)
    user_location: Point,
    disaster_type: str,
    graph: nx.MultiDiGraph | None = None,
    route_nodes: list | None = None,
    min_distance_km: float | None = None,
) -> folium.Map:
    """Folium 지도를 생성합니다. (사용자 제공 코드 기반으로 수정)"""
    print("Folium: Creating map visualization...")
    # --- 아이콘 스타일 정의 (기존 코드 사용) ---
    icon_styles = {
        "HEAT_WAVE": {"icon": "fire", "color": "red", "prefix": "fa"},
        "COLD_WAVE": {"icon": "snowflake", "color": "blue", "prefix": "fa"},
        "FINE_DUST": {
            "icon": "lungs-virus",
            "color": "gray",
            "prefix": "fa",
        },  # 아이콘 변경
        "FLOOD": {
            "icon": "house-flood-water",
            "color": "cadetblue",
            "prefix": "fa",
        },  # 아이콘 변경
        "EARTHQUAKE": {
            "icon": "house-crack",
            "color": "orange",
            "prefix": "fa",
        },  # 아이콘 변경
    }
    default_style = {"icon": "home", "color": "darkgray", "prefix": "fa"}
    style = icon_styles.get(disaster_type, default_style)

    fmap = folium.Map(location=(user_location.y, user_location.x), zoom_start=15)

    # 사용자 위치 마커
    folium.Marker(
        location=(user_location.y, user_location.x),
        popup="<b>현재 위치</b>",
        icon=folium.Icon(color="blue", icon="user", prefix="fa"),
        tooltip="현재 위치",
    ).add_to(fmap)

    # 지도에 표시할 대피소 데이터 확인
    display_gdf = (
        shelter_gdf if (shelter_gdf is not None and not shelter_gdf.empty) else None
    )

    # 대피소 마커 추가
    if display_gdf is not None:
        print(f"Folium: Adding {len(display_gdf)} shelter markers...")
        for idx, row in display_gdf.iterrows():
            shelter_geom = row.geometry
            if not (
                shelter_geom
                and isinstance(shelter_geom, Point)
                and shelter_geom.is_valid
            ):
                continue
            lat, lon = shelter_geom.y, shelter_geom.x

            is_closest = (
                closest_shelter_row is not None and idx == closest_shelter_row.name
            )

            marker_icon = (
                folium.Icon(color="black", icon="star", prefix="fa")
                if is_closest
                else folium.Icon(
                    color=style["color"], icon=style["icon"], prefix=style["prefix"]
                )
            )
            title = (
                "⭐ 최단 경로 대피소 ⭐" if is_closest else f"{disaster_type} 대피소"
            )
            tooltip_text = f"{title}: {row.get('시설명', row.get('명칭', '이름 없음'))}"

            # 팝업 내용 (기존 코드 개선 적용)
            popup_content = [f"<h4 style='margin-bottom: 2px;'>{title}</h4>"]
            name = row.get("시설명", None) or row.get("명칭", None)
            address = (
                row.get("주소", None)
                or row.get("도로명주소", None)
                or row.get("소재지도로명주소", None)
            )
            capacity = (
                row.get("수용가능인원", None)
                or row.get("최대수용인원", None)
                or row.get("수용인원", None)
            )
            if name:
                popup_content.append(f"<p style='margin:0;'><b>이름:</b> {name}</p>")
            if address:
                popup_content.append(f"<p style='margin:0;'><b>주소:</b> {address}</p>")
            if capacity:
                try:
                    popup_content.append(
                        f"<p style='margin:0;'><b>수용인원:</b> {int(capacity):,}명</p>"
                    )
                except:
                    popup_content.append(
                        f"<p style='margin:0;'><b>수용인원:</b> {capacity}</p>"
                    )
            popup_content.append(
                f"<p style='margin:0;'>위도: {lat:.5f}<br>경도: {lon:.5f}</p>"
            )
            popup_html = f"<div style='font-family: sans-serif; font-size: 12px;'>{''.join(popup_content)}</div>"

            folium.Marker(
                location=(lat, lon),
                popup=folium.Popup(popup_html, max_width=250),
                icon=marker_icon,
                tooltip=tooltip_text,
            ).add_to(fmap)

    # 최단 경로 시각화
    if closest_shelter_row is not None and route_nodes and graph:
        print("Folium: Adding shortest path route...")
        try:
            route_latlons = [
                (graph.nodes[node_id]["y"], graph.nodes[node_id]["x"])
                for node_id in route_nodes
            ]
            route_tooltip = (
                f"최단 도보 경로 ({min_distance_km:.2f} km)"
                if min_distance_km is not None
                else "최단 도보 경로"
            )
            folium.PolyLine(
                locations=route_latlons,
                color="purple",
                weight=5,
                opacity=0.8,
                tooltip=route_tooltip,
            ).add_to(fmap)
        except Exception as e:
            print(f"오류: 경로 시각화 중 오류 발생: {e}")

    # 지도 범위 자동 조절 (기존 코드 사용)
    bounds_points = [(user_location.y, user_location.x)]
    if closest_shelter_row is not None and route_nodes and graph:
        if "geometry" in closest_shelter_row and closest_shelter_row.geometry:
            bounds_points.append(
                (closest_shelter_row.geometry.y, closest_shelter_row.geometry.x)
            )
        if "route_latlons" in locals():
            bounds_points.extend(route_latlons)
    elif (
        closest_shelter_row is not None
        and "geometry" in closest_shelter_row
        and closest_shelter_row.geometry
    ):
        bounds_points.append(
            (closest_shelter_row.geometry.y, closest_shelter_row.geometry.x)
        )

    if len(bounds_points) >= 2:
        try:
            fmap.fit_bounds(bounds=bounds_points, padding=(0.001, 0.001))
        except Exception as e:
            print(f"지도 범위 자동 조절(fit_bounds) 중 오류: {e}")

    print("Folium: Map creation finished.")
    return fmap


# --- Main Service Function ---
async def generate_shelter_map_html(
    latitude: float, longitude: float, disaster_type: str, radius_km: float
) -> str:
    """
    OSMnx와 Folium을 사용하여 대피소 및 경로 지도의 HTML을 생성합니다.
    CPU 집약적인 작업을 별도 스레드에서 실행합니다.
    """
    user_location = Point(longitude, latitude)
    print(
        f"--- Map Generation Service Started: Type={disaster_type}, Radius={radius_km}km ---"
    )

    try:
        # CPU 집약적인 작업들을 감싸는 함수
        def _blocking_operations():
            # 1. 재난 유형별 대피소 로드
            shelter_data = _load_shelter_by_type(disaster_type)
            if shelter_data.gdf is None or shelter_data.gdf.empty:
                raise ValueError(
                    f"'{disaster_type}' 유형의 유효 대피소 데이터를 로드하지 못했습니다."
                )

            # 2. 반경 내 대피소 필터링 (또는 전체 사용 결정)
            #    osmnx 탐색 반경과 별개로, 지도에 표시할 대피소 목록 필터링
            shelter_gdf_to_display = _filter_shelter_by_radius(
                shelter_data, user_location, radius_km
            )
            if shelter_gdf_to_display is None:  # 필터링 중 오류 발생 시
                shelter_gdf_to_display = shelter_data.gdf  # 원본 사용 시도
            if shelter_gdf_to_display is None or shelter_gdf_to_display.empty:
                print(
                    f"경고: 반경 {radius_km}km 내 또는 원본 데이터에 유효한 대피소가 없습니다."
                )
                # 대피소가 없어도 사용자 위치만 표시된 지도는 생성 가능

            # 3. 가장 가까운 대피소 및 네트워크 경로 탐색 (가장 시간 소요)
            #    네트워크 탐색 반경은 입력받은 radius_km 사용
            closest_shelter, network_graph, route_nodes, distance_km = (
                _extract_closest_shelter_and_route(
                    shelter_gdf_to_display,
                    user_location,
                    radius_km,  # 필터링된 GDF 전달
                )
            )

            # 4. 지도 시각화
            fmap = _visualize_shelters_on_map(
                shelter_gdf=shelter_gdf_to_display,  # 지도에 표시할 GDF
                closest_shelter_row=closest_shelter,
                user_location=user_location,
                disaster_type=disaster_type,
                graph=network_graph,
                route_nodes=route_nodes,
                min_distance_km=distance_km,
            )
            return fmap._repr_html_()

        # asyncio.to_thread를 사용하여 동기 함수를 별도 스레드에서 실행
        print("Running blocking operations in a separate thread...")
        loop = asyncio.get_running_loop()
        map_html = await loop.run_in_executor(
            None, _blocking_operations
        )  # None은 기본 스레드 풀 사용
        print("--- Map Generation Service Finished ---")
        return map_html

    except ValueError as ve:
        print(f"Map Generation Error (ValueError): {ve}")
        return f"<h2>지도 생성 오류: {ve}</h2>"
    except ImportError as ie:
        print(f"Map Generation Error (ImportError): {ie}")
        return (
            f"<h2>지도 생성 오류: 필요한 라이브러리({ie})가 설치되지 않았습니다.</h2>"
        )
    except Exception as e:
        print(f"Map Generation Error (Unexpected): {e}")
        traceback.print_exc()
        return f"<h2>지도 생성 중 예상치 못한 오류가 발생했습니다: {e}</h2>"
