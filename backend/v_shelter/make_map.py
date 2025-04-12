import warnings
import osmnx as ox
import networkx as nx
import folium

from backend.v_shelter.shelter import Shelter
from shapely.geometry import Point
from geopy.distance import geodesic

warnings.filterwarnings("ignore")


def get_shelter(
    data_path: str,
    root_path: str = "./datasets/shelter",
    lon_column: str = "경도",
    lat_column: str = "위도",
) -> Shelter:
    shelter = Shelter(data_path, root_path)
    shelter.load_data()
    shelter.create_geodataframe(lon_column, lat_column)
    return shelter


# --- load_shelter_by_type 함수 ---
def load_shelter_by_type(disaster_type: str) -> Shelter:
    """입력한 재난 유형에 해당하는 대피소 데이터만 로드합니다."""
    mapping = {
        "COLD_WAVE": "cold_wave.csv",
        "HEAT_WAVE": "heat_wave.csv",
        "FINE_DUST": "fine_dust_prepared.csv",
        "FLOOD": "flood_prepared.csv",
        "EARTHQUAKE": "earthquake.csv",
    }
    root_data_path = "./datasets/shelter"
    if disaster_type not in mapping:
        raise ValueError(
            f"유효하지 않은 재난 유형입니다: {disaster_type}. 유효한 유형: {list(mapping.keys())}"
        )

    data_file = mapping[disaster_type]
    shelter = get_shelter(data_file, root_data_path)

    if disaster_type == "FINE_DUST":
        if hasattr(shelter, "df") and shelter.df is not None:
            if "경도" in shelter.df.columns and "위도" in shelter.df.columns:
                shelter.df.dropna(subset=["경도", "위도"], inplace=True)
        if (
            hasattr(shelter, "gdf")
            and shelter.gdf is not None
            and not shelter.gdf.empty
        ):
            shelter.gdf = shelter.gdf[
                shelter.gdf.geometry.is_valid & ~shelter.gdf.geometry.is_empty
            ].copy()

    if shelter.gdf is None or shelter.gdf.empty:
        print(
            f"경고: {disaster_type} 유형의 대피소 데이터를 로드했으나 유효한 지리 정보가 없습니다."
        )

    return shelter


def filter_shelter_by_radius(
    shelter: Shelter, user_location: Point, radius: float
) -> Shelter:
    """
    대피소 GeoDataFrame을 사용자 위치 기준 반경(radius km) 내 데이터로 필터링합니다.
    필터링 결과가 없으면 원본 데이터를 반환합니다. (주의: 원본 Shelter 객체 반환)
    """
    filtered_shelter = Shelter(shelter.data_path, shelter.root_path)

    if shelter.gdf is None or shelter.gdf.empty:
        print("필터링할 원본 대피소 데이터가 없습니다.")
        filtered_shelter.gdf = shelter.gdf  # 비어있는 gdf 할당
        return filtered_shelter

    radii_to_try = sorted(list(set([radius, 3.0, 5.0])))

    found_shelters = False
    for current_radius in radii_to_try:
        indices = []

        for index, row in shelter.gdf.iterrows():
            # row.geometry가 유효한 Point 객체인지 확인 후 거리 계산
            if (
                row.geometry
                and isinstance(row.geometry, Point)
                and row.geometry.is_valid
                and not row.geometry.is_empty
            ):
                distance = geodesic(
                    (user_location.y, user_location.x), (row.geometry.y, row.geometry.x)
                ).kilometers
                if distance <= radius:
                    indices.append(index)

        if indices:
            filtered_shelter.gdf = shelter.gdf.loc[indices].copy()
            found_shelters = True
            break

    if not found_shelters:
        if shelter.gdf is not None:
            filtered_shelter = shelter

    return filtered_shelter


def extract_closest_shelter(
    shelter: Shelter, user_location: Point, network_radius: float
):
    """
    도로 네트워크 내 지정 반경(network_radius km)에서 사용자로부터 가장 가까운 대피소를 찾습니다.
    가장 가까운 대피소 정보(GeoDataFrame Row), 네트워크 그래프,
    그리고 해당 대피소까지의 최단 경로(노드 ID 리스트)를 반환합니다.
    """
    if shelter.gdf is None or shelter.gdf.empty:
        print("경고: 검색할 대피소 데이터가 없습니다.")
        return None, None, None  # 대피소 없음, 그래프 없음, 경로 없음

    try:
        graph = ox.graph_from_point(
            (user_location.y, user_location.x),
            dist=network_radius * 1000,
            network_type="walk",
            simplify=True,
        )

        # 사용자 위치에서 가장 가까운 네트워크 노드 찾기
        user_node = ox.nearest_nodes(graph, user_location.x, user_location.y)
        print(f"사용자 위치에 가장 가까운 노드: {user_node}")

    except Exception as e:
        print(f"오류: 네트워크 그래프 생성 또는 사용자 노드 탐색 실패: {e}")
        return None, None, None

    closest_shelter_row = None
    min_distance = float("inf")
    shortest_route_nodes = None

    # geometry 컬럼 존재 확인
    if "geometry" not in shelter.gdf.columns:
        raise ValueError("Shelter GeoDataFrame에 'geometry' 컬럼이 필요합니다.")

    # 대피소들의 가장 가까운 노드를 미리 계산하여 캐싱 (효율성 증대)
    shelter_nodes_map = {}
    valid_shelter_geoms = []  # 유효한 대피소 geometry 리스트
    valid_shelter_indices = []  # 유효한 대피소 인덱스 리스트

    for idx, geom in shelter.gdf.geometry.items():
        if geom and isinstance(geom, Point) and geom.is_valid:
            valid_shelter_geoms.append((geom.x, geom.y))
            valid_shelter_indices.append(idx)

    if not valid_shelter_geoms:
        print("경고: 유효한 대피소 좌표가 없습니다.")
        return None, graph, None

    try:
        # 여러 지점에 대해 가장 가까운 노드들을 한 번에 계산
        nearest_nodes_list = ox.nearest_nodes(graph, *zip(*valid_shelter_geoms))
        shelter_nodes_map = dict(zip(valid_shelter_indices, nearest_nodes_list))
        print(f"{len(shelter_nodes_map)}개 대피소의 최근접 노드 미리 계산 완료.")
    except Exception as e:
        print(
            f"경고: 대피소들의 최근접 노드 일괄 계산 실패: {e}. 개별적으로 처리합니다."
        )
        shelter_nodes_map = {}  # 캐시 비우기

    # 필터링된 (또는 전체) 대피소 목록을 순회
    print(f"총 {len(shelter.gdf)}개 대피소에 대해 최단 경로 탐색 시작...")
    processed_count = 0
    for index, row in shelter.gdf.iterrows():
        # geometry 유효성 재확인
        if (
            not row.geometry
            or not isinstance(row.geometry, Point)
            or not row.geometry.is_valid
        ):
            continue

        try:
            # 대피소 위치에서 가장 가까운 네트워크 노드 찾기 (캐시된 값 사용 또는 새로 계산)
            shelter_node = shelter_nodes_map.get(index)
            if shelter_node is None:
                # 캐시에 없으면 개별적으로 계산 (일괄 계산 실패 시 또는 캐시에 없는 경우)
                shelter_node = ox.nearest_nodes(graph, row.geometry.x, row.geometry.y)

            # 사용자 노드와 대피소 노드 간의 최단 경로 *노드 리스트* 계산
            # weight='length'는 도로/경로의 실제 길이를 가중치로 사용함을 의미
            route_nodes = nx.shortest_path(
                graph, source=user_node, target=shelter_node, weight="length"
            )
            route_length = nx.shortest_path_length(
                graph, source=user_node, target=shelter_node, weight="length"
            )
            route_km = route_length / 1000.0

            if route_km <= network_radius and route_km < min_distance:
                min_distance = route_km
                closest_shelter_row = row
                shortest_route_nodes = route_nodes

            processed_count += 1
            if processed_count % 50 == 0:
                print(f"    {processed_count}개 대피소 처리 완료...")

        except nx.NetworkXNoPath:
            continue
        except Exception as e:
            print(f"오류: 대피소(인덱스 {index}) 처리 중 오류 발생: {e}")
            continue

    if closest_shelter_row is not None:
        print(
            f"탐색 완료. 가장 가까운 대피소: 인덱스 {closest_shelter_row.name}, 거리 {min_distance:.2f} km"
        )
    else:
        print(
            f"탐색 완료. 반경 {network_radius}km 내 네트워크 경로로 도달 가능한 대피소를 찾지 못했습니다."
        )

    return closest_shelter_row, graph, shortest_route_nodes, min_distance


def visualize_shelters_on_map(
    shelter: Shelter,
    closest_shelter_row,
    user_location: Point,
    disaster_type: str,
    graph=None,
    route_nodes=None,
    min_distance_km=None,
) -> folium.Map:
    """
    Folium을 이용해 지도상에 사용자 위치, 대피소들을 표시하고,
    가장 가까운 대피소까지의 *네트워크 경로*를 시각화합니다.
    재난 유형에 따라 마커 아이콘을 변경합니다.
    """
    icon_styles = {
        "HEAT_WAVE": {"icon": "fire", "color": "red", "prefix": "fa"},  # 무더위 쉼터
        "COLD_WAVE": {
            "icon": "snowflake",
            "color": "blue",
            "prefix": "fa",
        },  # 한파 쉼터
        "FINE_DUST": {
            "icon": "medkit",  # ??
            "color": "green",
            "prefix": "fa",
        },
        "FLOOD": {
            "icon": "tint",  # ??
            "color": "cadetblue",
            "prefix": "fa",
        },
        "EARTHQUAKE": {  # 지진 대피소
            "icon": "building",  # 'exclamation-triangle' 대신 건물 아이콘 사용 고려
            "color": "orange",
            "prefix": "fa",
        },
    }
    # 매핑 안된 경우 기본 아이콘
    default_style = {
        "icon": "home",
        "color": "gray",
        "prefix": "fa",
    }
    style = icon_styles.get(disaster_type, default_style)

    # 지도 생성 (사용자 위치 중심, 확대 레벨 조정)
    fmap = folium.Map(
        location=(user_location.y, user_location.x),
        zoom_start=15,
        # tiles="CartoDB positron",
    )

    # 사용자 위치 마커 (파란색, 사람 아이콘)
    folium.Marker(
        location=(user_location.y, user_location.x),
        popup=folium.Popup("<b>현재 위치</b>", max_width=150),  # 팝업 내용
        icon=folium.Icon(color="blue", icon="user", prefix="fa"),
        tooltip="현재 위치",  # 마우스 올리면 표시될 텍스트
    ).add_to(fmap)

    # 지도에 표시할 대피소 데이터가 있는지 확인
    if shelter.gdf is None or shelter.gdf.empty:
        print("지도에 표시할 대피소 데이터가 없습니다.")
        # 가장 가까운 대피소 정보만이라도 있다면 표시 시도
        if (
            closest_shelter_row is not None
            and "geometry" in closest_shelter_row
            and closest_shelter_row.geometry
        ):
            lat, lon = closest_shelter_row.geometry.y, closest_shelter_row.geometry.x
            # 팝업 내용 구성 (대피소 이름 등 추가 정보 포함 시도)
            # 데이터 구조 변경 -> 정보 표시 고려
            shelter_name = closest_shelter_row.get(
                "시설명", closest_shelter_row.get("명칭", "이름 정보 없음")
            )
            popup_html = (
                f"<div style='font-family: sans-serif; font-size: 12px;'>"
                f"<h4 style='margin-bottom: 2px;'>⭐ 가장 가까운 대피소 ⭐</h4>"
                f"<p style='margin:0;'><b>이름:</b> {shelter_name}</p>"
                f"<p style='margin:0;'>위도: {lat:.5f}<br>경도: {lon:.5f}</p>"
                f"</div>"
            )
            folium.Marker(
                location=(lat, lon),
                popup=folium.Popup(popup_html, max_width=250),
                icon=folium.Icon(color="black", icon="star", prefix="fa"),  # 별 아이콘
                tooltip=f"가장 가까운 대피소: {shelter_name}",
            ).add_to(fmap)
        return fmap  # 사용자 위치만 있는 (혹은 가장 가까운 대피소만 있는) 지도 반환

    # 대피소 마커 표시 (주변 대피소 목록 순회)
    print(f"지도에 {len(shelter.gdf)}개 대피소 마커 표시 중...")
    for idx, row in shelter.gdf.iterrows():
        # 유효한 geometry 확인
        if (
            not row.geometry
            or not isinstance(row.geometry, Point)
            or not row.geometry.is_valid
        ):
            continue

        lat = row.geometry.y
        lon = row.geometry.x

        # 현재 대피소가 가장 가까운 대피소인지 확인
        # closest_shelter_row가 None이 아니고, 현재 행의 인덱스(idx)가 가장 가까운 대피소의 인덱스(name)와 같은지 비교
        is_closest = closest_shelter_row is not None and idx == closest_shelter_row.name

        # 마커 아이콘 및 툴팁 설정
        if is_closest:
            marker_icon = folium.Icon(
                color="black", icon="star", prefix="fa"
            )  # 검정색 별 아이콘
            title = "⭐ 가장 가까운 대피소 ⭐"
            tooltip_text = f"{title} ({row.get('시설명', '정보 없음')})"
        else:
            marker_icon = folium.Icon(
                color=style["color"], icon=style["icon"], prefix=style["prefix"]
            )
            title = f"{disaster_type} 대피소"  # 재난 유형 표시
            tooltip_text = (
                f"{row.get('시설명', '정보 없음')}"  # 시설명 표시 (없으면 '정보 없음')
            )

        # 팝업 내용 구성 (개선)
        popup_content = [f"<h4 style='margin-bottom: 2px;'>{title}</h4>"]
        # 대피소 데이터에 있을 법한 컬럼들 시도 (get 메서드로 안전하게 접근)
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
            try:  # 숫자일 경우 세 자리 콤마 추가 시도
                popup_content.append(
                    f"<p style='margin:0;'><b>수용인원:</b> {int(capacity):,}명</p>"
                )
            except (ValueError, TypeError):  # 숫자가 아니면 그대로 표시
                popup_content.append(
                    f"<p style='margin:0;'><b>수용인원:</b> {capacity}</p>"
                )

        popup_content.append(
            f"<p style='margin:0;'>위도: {lat:.5f}<br>경도: {lon:.5f}</p>"
        )
        popup_html = f"<div style='font-family: sans-serif; font-size: 12px;'>{''.join(popup_content)}</div>"
        popup = folium.Popup(popup_html, max_width=250)

        # 마커 생성 및 지도에 추가
        folium.Marker(
            location=(lat, lon),
            popup=popup,  # 클릭 시 팝업
            icon=marker_icon,  # 설정된 아이콘
            tooltip=tooltip_text,  # 마우스 오버 시 툴팁
        ).add_to(fmap)

    # 가장 가까운 대피소까지의 *네트워크 경로* 시각화
    if closest_shelter_row is not None and route_nodes and graph:
        try:
            # 경로를 구성하는 노드들의 (위도, 경도) 좌표 리스트 생성
            route_latlons = []
            for node_id in route_nodes:
                node_data = graph.nodes[node_id]
                route_latlons.append((node_data["y"], node_data["x"]))

            # 경로를 PolyLine으로 지도에 그리기
            route_tooltip = (
                f"최단 도보 경로 ({min_distance_km:.2f} km)"
                if min_distance_km is not None
                else "최단 도보 경로"
            )
            folium.PolyLine(
                locations=route_latlons,  # 노드 좌표 리스트
                color="purple",  # 경로 색상 (보라색)
                weight=5,  # 경로 두께
                opacity=0.8,  # 경로 투명도
                tooltip=route_tooltip,  # 경로에 마우스 올리면 거리 표시
            ).add_to(fmap)

        except KeyError as e:
            print(
                f"오류: 경로 시각화 중 노드 ID {e}를 그래프에서 찾을 수 없습니다. 경로가 불완전할 수 있습니다."
            )
        except Exception as e:
            print(f"오류: 경로 시각화 중 오류 발생: {e}")

    # 지도 범위 자동 조절 (fit_bounds)
    bounds_points = []
    # 사용자 위치 추가
    bounds_points.append((user_location.y, user_location.x))

    # 가장 가까운 대피소와 경로가 있으면 해당 지점들 추가
    if closest_shelter_row is not None and route_nodes and graph:
        if "geometry" in closest_shelter_row and closest_shelter_row.geometry:
            bounds_points.append(
                (closest_shelter_row.geometry.y, closest_shelter_row.geometry.x)
            )
        # 경로상의 모든 노드 좌표 추가 (위에서 계산한 route_latlons 재사용)
        if "route_latlons" in locals():  # route_latlons 변수가 생성되었는지 확인
            bounds_points.extend(route_latlons)

    # 가장 가까운 대피소만 있으면 해당 지점 추가
    elif closest_shelter_row is not None:
        if "geometry" in closest_shelter_row and closest_shelter_row.geometry:
            bounds_points.append(
                (closest_shelter_row.geometry.y, closest_shelter_row.geometry.x)
            )

    # 포함할 지점이 2개 이상일 때만 fit_bounds 호출
    if len(bounds_points) >= 2:
        try:
            # 모든 중요 지점(사용자, 가장 가까운 대피소, 경로)이 보이도록 지도 범위 조절
            fmap.fit_bounds(
                bounds=bounds_points, padding=(0.001, 0.001)
            )  # 약간의 여백 추가
        except Exception as e:
            print(
                f"지도 범위 자동 조절(fit_bounds) 중 오류 발생: {e}. 기본 확대/축소 유지."
            )
    # 포함할 지점이 1개 이하면 (사용자 위치만 있거나 오류 발생 시) 초기 zoom_start 유지됨

    return fmap


def make_map(user_location: Point, disaster_type: str, filter_radius: float) -> str:
    """
    1. 입력받은 재난 유형에 해당하는 대피소를 로드합니다.
    2. 사용자 위치 기준 반경 내 대피소를 필터링합니다.
    3. 도로 네트워크를 통해 가장 가까운 대피소와 그 경로를 찾습니다.
    4. 경로를 포함한 지도를 생성하여 HTML 문자열을 반환합니다.
    """
    print(f"--- 지도 생성 시작: 재난유형={disaster_type}, 반경={filter_radius}km ---")
    try:
        # 1. 재난 유형별 대피소 데이터 로드
        shelter_data = load_shelter_by_type(disaster_type)
        if shelter_data.gdf is None or shelter_data.gdf.empty:
            print(
                f"오류: {disaster_type} 유형의 유효한 대피소 데이터를 로드하지 못했습니다."
            )
            return f"<h2>지도 생성 오류: '{disaster_type}' 유형의 대피소 데이터를 찾을 수 없거나 유효하지 않습니다.</h2>"

        # 2. 사용자 위치 기준 반경 내 대피소 필터링
        # filter_radius(km)는 직선 거리 기준 필터링에 사용
        local_shelter_data = filter_shelter_by_radius(
            shelter_data, user_location, filter_radius
        )
        # 필터링 후에도 데이터가 있는지 확인 (없으면 원본이 반환되므로 확인 필요)
        if local_shelter_data.gdf is None or local_shelter_data.gdf.empty:
            print(
                f"경고: 반경 {filter_radius}km 내 대피소가 없거나, 원본 데이터 자체가 없습니다."
            )

        # 3. 가장 가까운 대피소 및 네트워크 경로 탐색
        network_search_radius = filter_radius
        print(f"네트워크 탐색 시작 (반경: {network_search_radius}km)...")

        closest_shelter, network_graph, shortest_route_nodes, min_dist_km = (
            extract_closest_shelter(
                local_shelter_data, user_location, network_search_radius
            )
        )

        # 4. 지도 시각화 (그래프와 경로 노드 전달)
        print("지도 시각화 중...")
        fmap = visualize_shelters_on_map(
            local_shelter_data,  # 필터링된 (또는 전체) 대피소 목록
            closest_shelter,  # 네트워크 상 가장 가까운 대피소 정보 (row/Series)
            user_location,  # 사용자 위치
            disaster_type,  # 재난 유형
            graph=network_graph,  # 네트워크 그래프 전달
            route_nodes=shortest_route_nodes,  # 경로 노드 리스트 전달
            min_distance_km=min_dist_km,  # 계산된 거리 전달 (툴팁용)
        )

        # 생성된 지도의 HTML 표현 반환
        map_html_output = fmap._repr_html_()
        # fmap.save("shelter.html") # 테스트용
        return map_html_output

    except ValueError as ve:
        # 설정 또는 데이터 관련 오류 (예: 잘못된 재난 유형, 컬럼 없음 등)
        print(f"설정 또는 데이터 오류: {ve}")
        return f"<h2>지도 생성 오류: {ve}</h2>"
    except ImportError as ie:
        # 필요한 라이브러리가 설치되지 않은 경우
        print(f"라이브러리 누락 오류: {ie}. 필요한 라이브러리를 설치하세요.")
        return f"<h2>지도 생성 오류: 라이브러리 누락 ({ie})</h2>"
    except Exception as e:
        # 기타 예상치 못한 오류 처리
        import traceback

        print(f"지도 생성 중 예상치 못한 오류 발생: {e}")
        traceback.print_exc()  # 오류 상세 내용 콘솔 출력 (디버깅용)
        return f"<h2>지도 생성 중 예상치 못한 오류가 발생했습니다: {e}</h2>"
