import folium
import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
from typing import Optional, Dict, Any, List
import branca
import logging

from core.map.common_functions import add_zoom_control_style

logger = logging.getLogger(__name__)

# 재난 유형별 아이콘 스타일 정의
DISASTER_ICON_STYLES: Dict[str, Dict[str, str]] = {
    "HEAT_WAVE": {"icon": "fire", "color": "red", "prefix": "fa"},
    "COLD_WAVE": {"icon": "snowflake", "color": "blue", "prefix": "fa"},
    "FINE_DUST": {"icon": "lungs-virus", "color": "gray", "prefix": "fa"},
    "FLOOD": {"icon": "house-flood-water", "color": "cadetblue", "prefix": "fa"},
    "EARTHQUAKE": {"icon": "house-crack", "color": "orange", "prefix": "fa"},
    "DEFAULT": {"icon": "home", "color": "darkgray", "prefix": "fa"},  # 기본값
}


def _get_shelter_popup_html(row: pd.Series, disaster_type: str) -> str:
    """대피소 정보 팝업 HTML을 생성합니다. (단순화됨)"""
    name = row.get("시설명", row.get("명칭", "이름 없음"))
    address = row.get(
        "주소", row.get("도로명주소", row.get("소재지도로명주소", "주소 정보 없음"))
    )
    capacity = row.get(
        "수용가능인원", row.get("최대수용인원", row.get("수용인원", None))
    )

    popup_title = f"{disaster_type} 대피소"  # 변경됨: 최단 거리 관련 문구 제거

    content = [f"<h4 style='margin-bottom: 3px; font-size: 1.1em;'>{popup_title}</h4>"]
    content.append(f"<p style='margin:0;'><b>이름:</b> {name}</p>")
    content.append(f"<p style='margin:0;'><b>주소:</b> {address}</p>")
    if capacity:
        try:
            content.append(
                f"<p style='margin:0;'><b>수용인원:</b> {int(capacity):,}명</p>"
            )
        except (ValueError, TypeError):
            content.append(f"<p style='margin:0;'><b>수용인원:</b> {capacity}</p>")

    # 제거됨: 최단 거리 / 시간 정보 표시 로직 제거

    lat = row.geometry.y
    lon = row.geometry.x
    content.append(
        f"<p style='margin:0; font-size: 0.9em; color: grey;'>좌표: {lat:.5f}, {lon:.5f}</p>"
    )

    return f"<div style='font-family: sans-serif; font-size: 13px; min-width: 200px;'>{''.join(content)}</div>"


# 함수 시그니처에 radius_km 추가
def create_shelter_map(
    shelter_gdf: Optional[gpd.GeoDataFrame],
    user_location: Point,
    disaster_type: str,
    radius_km: float,  # <-- 파라미터 추가
) -> folium.Map:
    """
    Folium 지도를 생성하여 반환합니다. (사용자 위치 및 반경 내 대피소 표시, fit_bounds 미사용)
    """
    print(f"지도 생성 시작 (fit_bounds 미사용): {disaster_type} (반경: {radius_km}km)")

    # --- 중심점 및 Zoom 레벨 계산 로직 추가 ---
    map_center = (user_location.y, user_location.x)  # 기본값: 사용자 위치
    zoom_level = 15  # 기본값 (대피소 없을 시)

    bounds_points = [(user_location.y, user_location.x)]
    if shelter_gdf is not None and not shelter_gdf.empty:
        valid_points_gdf = shelter_gdf[
            shelter_gdf.geometry.is_valid & (shelter_gdf.geometry.geom_type == "Point")
        ]
        if not valid_points_gdf.empty:
            shelter_coords = valid_points_gdf.geometry.apply(
                lambda p: (p.y, p.x)
            ).tolist()
            bounds_points.extend(shelter_coords)

    # 표시할 점이 2개 이상일 경우 (사용자 위치 + 대피소 1개 이상)
    if len(bounds_points) >= 2:
        try:
            # 경계 상자 계산
            min_lat = min(p[0] for p in bounds_points)
            min_lon = min(p[1] for p in bounds_points)
            max_lat = max(p[0] for p in bounds_points)
            max_lon = max(p[1] for p in bounds_points)

            # 중심점 계산
            center_lat = (min_lat + max_lat) / 2
            center_lon = (min_lon + max_lon) / 2
            map_center = [center_lat, center_lon]

            # radius_km 기반으로 Zoom 레벨 추정 (휴리스틱)
            # 이 값들은 실제 테스트를 통해 조정해야 합니다.
            if radius_km <= 1.0:
                zoom_level = 17
            elif radius_km <= 2.0:
                zoom_level = 16
            elif radius_km <= 5.0:
                zoom_level = 15
            else:
                zoom_level = 14  # 반경이 매우 클 경우
            logger.info(
                f"Calculated map center: {map_center}, Estimated zoom: {zoom_level} based on radius {radius_km}km"
            )

        except Exception as e:
            logger.error(
                f"Error calculating center/zoom: {e}. Using default center/zoom."
            )
            # 오류 발생 시 기본값 사용 (사용자 위치 중심, zoom 15)
            map_center = (user_location.y, user_location.x)
            zoom_level = 17
    # --- 중심점 및 Zoom 레벨 계산 로직 끝 ---

    # 계산된 중심점과 zoom_level 사용
    fmap = folium.Map(
        location=map_center,
        zoom_start=zoom_level,  # 계산된 zoom_level 사용
        tiles="CartoDB positron",
    )

    # 사용자 위치 마커 추가 (기존 코드 유지)
    folium.Marker(
        location=(user_location.y, user_location.x),
        popup="<b style='font-size: 1.1em;'>현재 위치</b>",
        icon=folium.Icon(color="purple", icon="user", prefix="fa"),
        tooltip="현재 위치",
    ).add_to(fmap)

    # 대피소 마커 추가 (기존 코드 유지)
    display_gdf = shelter_gdf

    # 대피소 마커 추가
    if display_gdf is not None and not display_gdf.empty:
        print(
            f"지도 생성: {len(display_gdf)}개의 {disaster_type} 대피소 마커 추가 중..."
        )
        icon_style = DISASTER_ICON_STYLES.get(
            disaster_type, DISASTER_ICON_STYLES["DEFAULT"]
        )

        for idx, row in display_gdf.iterrows():
            shelter_geom = row.geometry
            if not (
                shelter_geom
                and isinstance(shelter_geom, Point)
                and shelter_geom.is_valid
            ):
                continue

            lat, lon = shelter_geom.y, shelter_geom.x

            # 변경됨: 모든 마커에 기본 아이콘 스타일 적용 (최단 거리 구분 없음)
            marker_icon = folium.Icon(
                color=icon_style["color"],
                icon=icon_style["icon"],
                prefix=icon_style["prefix"],
            )

            # 변경됨: 단순화된 팝업 HTML 생성 함수 호출
            popup_html = _get_shelter_popup_html(row, disaster_type)

            # 변경됨: 기본 툴팁 사용 (최단 거리 관련 문구 제거)
            name = row.get("시설명", row.get("명칭", "이름 없음"))
            tooltip_text = f"{disaster_type}: {name}"

            # 마커 추가
            folium.Marker(
                location=(lat, lon),
                popup=folium.Popup(popup_html, max_width=300),
                icon=marker_icon,
                tooltip=tooltip_text,
            ).add_to(fmap)
    else:
        print(f"지도 생성: 표시할 {disaster_type} 대피소 없음 (반경 내 해당 없음).")
        # 필요 시 "반경 내 대피소 없음" 메시지 추가 가능

    # 제거됨: 가장 가까운 대피소만 별도로 처리하는 로직 제거
    # elif closest_shelter_row is not None: ...

    # 제거됨: 경로 그리기 로직 제거
    # if route_coordinates: ...

    # 지도 범위 자동 조절 (fit_bounds) - 필터링된 대피소 기준으로 조정 (기존 로직 개선하여 유지)
    # try:
    #     bounds_points = [(user_location.y, user_location.x)]
    #     if display_gdf is not None and not display_gdf.empty:
    #         # 유효한 Point 객체만 추출하여 좌표 리스트 생성
    #         valid_points_gdf = display_gdf[
    #             display_gdf.geometry.is_valid
    #             & (display_gdf.geometry.geom_type == "Point")
    #         ]
    #         if not valid_points_gdf.empty:
    #             shelter_coords = valid_points_gdf.geometry.apply(
    #                 lambda p: (p.y, p.x)
    #             ).tolist()
    #             bounds_points.extend(shelter_coords)

    #     if len(bounds_points) >= 2:  # 시작점과 최소 1개 이상의 대피소 좌표가 있어야 함
    #         fmap.fit_bounds(bounds=bounds_points, padding=(0.005, 0.005))
    #     # else: 대피소가 하나도 없으면 사용자 위치 중심으로 기본 zoom 유지됨
    # except Exception as e:
    #     print(f"지도 범위 자동 조절(fit_bounds) 중 오류 발생: {e}")

    fmap = add_zoom_control_style(fmap)
    print(f"지도 생성 완료: {disaster_type}")
    return fmap
