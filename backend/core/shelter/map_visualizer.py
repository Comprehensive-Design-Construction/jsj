import folium
import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
from typing import Optional, Dict, Any, List

# 재난 유형별 아이콘 스타일 정의
DISASTER_ICON_STYLES: Dict[str, Dict[str, str]] = {
    "HEAT_WAVE": {"icon": "fire", "color": "red", "prefix": "fa"},
    "COLD_WAVE": {"icon": "snowflake", "color": "blue", "prefix": "fa"},
    "FINE_DUST": {"icon": "lungs-virus", "color": "gray", "prefix": "fa"},
    "FLOOD": {"icon": "house-flood-water", "color": "cadetblue", "prefix": "fa"},
    "EARTHQUAKE": {"icon": "house-crack", "color": "orange", "prefix": "fa"},
    "DEFAULT": {"icon": "home", "color": "darkgray", "prefix": "fa"},  # 기본값
}


def _get_shelter_popup_html(
    row: pd.Series,
    disaster_type: str,
    is_closest: bool,
    distance_m: Optional[int],
    time_sec: Optional[int],
) -> str:
    """대피소 정보 팝업 HTML을 생성합니다."""
    name = row.get("시설명", row.get("명칭", "이름 없음"))  # 데이터 컬럼명 확인 필요
    address = row.get(
        "주소", row.get("도로명주소", row.get("소재지도로명주소", "주소 정보 없음"))
    )
    capacity = row.get(
        "수용가능인원", row.get("최대수용인원", row.get("수용인원", None))
    )

    popup_title = f"{disaster_type} 대피소"
    if is_closest:
        distance_km_str = (
            f" ({distance_m / 1000:.2f}km)" if distance_m is not None else ""
        )
        popup_title = f"⭐ 최단 거리 대피소{distance_km_str} ⭐"

    content = [f"<h4 style='margin-bottom: 3px; font-size: 1.1em;'>{popup_title}</h4>"]
    content.append(f"<p style='margin:0;'><b>이름:</b> {name}</p>")
    content.append(f"<p style='margin:0;'><b>주소:</b> {address}</p>")
    if capacity:
        try:
            content.append(
                f"<p style='margin:0;'><b>수용인원:</b> {int(capacity):,}명</p>"
            )
        except:
            content.append(f"<p style='margin:0;'><b>수용인원:</b> {capacity}</p>")

    if is_closest:
        if distance_m is not None:
            content.append(
                f"<p style='margin:0;'><b>거리:</b> {distance_m / 1000:.2f} km</p>"
            )
        if time_sec is not None:
            content.append(
                f"<p style='margin:0;'><b>예상 시간:</b> 약 {time_sec / 60:.1f} 분</p>"
            )

    lat = row.geometry.y
    lon = row.geometry.x
    content.append(
        f"<p style='margin:0; font-size: 0.9em; color: grey;'>좌표: {lat:.5f}, {lon:.5f}</p>"
    )

    return f"<div style='font-family: sans-serif; font-size: 13px; min-width: 200px;'>{''.join(content)}</div>"


def create_shelter_map(
    shelter_gdf: Optional[gpd.GeoDataFrame],
    closest_shelter_row: Optional[pd.Series],
    user_location: Point,
    disaster_type: str,
    min_distance_m: Optional[int] = None,
    min_time_sec: Optional[int] = None,
    route_coordinates: Optional[List[List[float]]] = None,  # 경로 좌표 인자 추가
) -> folium.Map:
    """
    Folium 지도를 생성하여 반환합니다.
    가장 가까운 대피소까지의 경로를 포함하여 시각화합니다.
    """
    print(f"지도 생성 시작: {disaster_type} (경로 포함)...")
    fmap = folium.Map(
        location=(user_location.y, user_location.x),
        zoom_start=15,
        tiles="CartoDB positron",
    )

    # 사용자 위치 마커 추가
    folium.Marker(
        location=(user_location.y, user_location.x),
        popup="<b style='font-size: 1.1em;'>현재 위치</b>",
        icon=folium.Icon(color="purple", icon="user", prefix="fa"),
        tooltip="현재 위치",
    ).add_to(fmap)

    # 지도에 표시할 대피소 목록 결정
    display_gdf = (
        shelter_gdf if (shelter_gdf is not None and not shelter_gdf.empty) else None
    )

    # 대피소 마커 추가
    if display_gdf is not None:
        print(
            f"지도 생성: {len(display_gdf)}개의 {disaster_type} 대피소 마커 추가 중..."
        )
        icon_style = DISASTER_ICON_STYLES.get(
            disaster_type, DISASTER_ICON_STYLES["DEFAULT"]
        )

        for idx, row in display_gdf.iterrows():
            shelter_geom = row.geometry
            # 유효한 Point 지오메트리 확인
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

            # 아이콘 설정 (가장 가까운 곳은 별 모양)
            marker_icon = (
                folium.Icon(color="black", icon="star", prefix="fa")
                if is_closest
                else folium.Icon(
                    color=icon_style["color"],
                    icon=icon_style["icon"],
                    prefix=icon_style["prefix"],
                )
            )

            # 팝업 HTML 생성
            popup_html = _get_shelter_popup_html(
                row, disaster_type, is_closest, min_distance_m, min_time_sec
            )

            # 툴팁 텍스트 설정
            name = row.get("시설명", row.get("명칭", "이름 없음"))
            tooltip_text = f"{disaster_type}: {name}"
            if is_closest:
                distance_km_str = (
                    f" ({min_distance_m / 1000:.2f}km)"
                    if min_distance_m is not None
                    else ""
                )
                tooltip_text = f"⭐ 최단 거리{distance_km_str}: {name}"

            # 마커 추가
            folium.Marker(
                location=(lat, lon),
                popup=folium.Popup(popup_html, max_width=300),
                icon=marker_icon,
                tooltip=tooltip_text,
            ).add_to(fmap)
    elif closest_shelter_row is not None:
        # 필터링된 대피소는 없지만, API 결과로 가장 가까운 곳만 있는 경우 (예: 반경 밖)
        print(
            f"지도 생성: 필터링된 목록은 없으나, 최단 거리 대피소({closest_shelter_row.name}) 1개 추가 중..."
        )
        lat, lon = closest_shelter_row.geometry.y, closest_shelter_row.geometry.x
        popup_html = _get_shelter_popup_html(
            closest_shelter_row, disaster_type, True, min_distance_m, min_time_sec
        )
        name = closest_shelter_row.get(
            "시설명", closest_shelter_row.get("명칭", "이름 없음")
        )
        distance_km_str = (
            f" ({min_distance_m / 1000:.2f}km)" if min_distance_m is not None else ""
        )
        tooltip_text = f"⭐ 최단 거리{distance_km_str}: {name}"
        folium.Marker(
            location=(lat, lon),
            popup=folium.Popup(popup_html, max_width=300),
            icon=folium.Icon(color="black", icon="star", prefix="fa"),
            tooltip=tooltip_text,
        ).add_to(fmap)

    if route_coordinates:
        print(f"지도 생성: 최단 경로(좌표 {len(route_coordinates)}개) 추가 중...")
        try:
            # TMAP 좌표는 [lon, lat] 순서, Folium PolyLine은 [lat, lon] 순서 필요
            route_latlons = [[coord[1], coord[0]] for coord in route_coordinates]

            # 경로 선 생성
            folium.PolyLine(
                locations=route_latlons,
                color="purple",  # 경로 색상
                weight=5,  # 경로 두께
                opacity=0.8,  # 경로 투명도
                tooltip=(
                    f"최단 경로 ({min_distance_m / 1000:.2f} km)"
                    if min_distance_m
                    else "최단 경로"
                ),
            ).add_to(fmap)
        except Exception as e:
            print(f"오류: 경로 PolyLine 생성 중 오류 발생: {e}")

    # 지도 범위 자동 조절 (fit_bounds)
    try:
        bounds_points = [(user_location.y, user_location.x)]
        # 가장 가까운 대피소가 있으면 해당 위치 추가
        if (
            closest_shelter_row is not None
            and "geometry" in closest_shelter_row
            and closest_shelter_row.geometry
        ):
            bounds_points.append(
                (closest_shelter_row.geometry.y, closest_shelter_row.geometry.x)
            )
        elif display_gdf is not None and len(display_gdf) > 0:
            sample_points = display_gdf.geometry.representative_point()  # 폴리곤 대비
            # sample_points = display_gdf.geometry # Point의 경우 그대로 사용
            # 간단히 첫번째 점 추가 예시
            if not sample_points.empty:
                first_point = sample_points.iloc[0]
                bounds_points.append((first_point.y, first_point.x))

        if len(bounds_points) >= 2:
            fmap.fit_bounds(bounds=bounds_points, padding=(0.005, 0.005))  # 패딩값 조절
    except Exception as e:
        print(f"지도 범위 자동 조절(fit_bounds) 중 오류 발생: {e}")

    print(f"지도 생성 완료: {disaster_type}")
    return fmap
