import folium
import pandas as pd
import json
import os
import geopandas as gpd

# from shapely.geometry import Point # centroid 계산에 직접 필요하진 않음
# from IPython.display import HTML # Jupyter/Colab 환경에서 표시용


def _fetch_air_quality_map_centroid_labels(air_quality_data: dict) -> str:
    """
    주어진 대기질 데이터와 GeoJSON 파일을 사용하여 서울시 구별 대기질 현황 Folium 지도를 생성합니다.
    개선 사항:
    1. 구 이름 항상 표시 (각 구의 중심점에 Marker와 DivIcon 사용)
    2. 지도 배경 라벨 제거 ('CartoDB positron_nolabels' 타일 사용)
    3. Choropleth 시각화 복원

    Args:
        air_quality_data (dict): 구 이름을 키로, 대기질 정보(MAXINDEX, GRADE 등 포함) 딕셔너리를 값으로 가지는 데이터.

    Returns:
        str: 생성된 Folium 지도의 HTML 표현 문자열. GeoJSON/geopandas 관련 오류 발생 시 에러 메시지 반환.
    """

    # --- GeoJSON 경로 설정 및 로드 ---
    try:
        # ... (기존 경로 설정 로직과 동일) ...
        base_dir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
        )
        geojson_path = os.path.join(
            base_dir, "backend", "datasets", "map", "seoul_municipalities_geo.json"
        )
    except NameError:
        print(
            "Warning: __file__ not defined. Using relative path './backend/...' for GeoJSON."
        )
        geojson_path = "./backend/datasets/map/seoul_municipalities_geo.json"

    if not os.path.exists(geojson_path):
        alt_geojson_path = "seoul_municipalities_geo.json"
        if os.path.exists(alt_geojson_path):
            geojson_path = alt_geojson_path
            print(f"Found GeoJSON at alternate path: {geojson_path}")
        else:
            return f"Error: GeoJSON file not found at '{geojson_path}' or '{alt_geojson_path}'"

    try:
        # GeoJSON을 Geopandas DataFrame으로 로드하여 중심점 계산
        gdf = gpd.read_file(geojson_path, encoding="utf-8")
        # 올바른 좌표계가 아닐 경우 WGS84 (EPSG:4326)로 변환 시도 (선택적)
        if gdf.crs and gdf.crs.to_epsg() != 4326:
            print(f"Converting CRS from {gdf.crs} to EPSG:4326")
            gdf = gdf.to_crs(epsg=4326)
        # 중심점 계산 (geometry 컬럼이 기본)
        gdf["centroid"] = gdf.geometry.centroid
    except ImportError:
        return "Error: geopandas library is required but not installed. Please run 'pip install geopandas'."
    except Exception as e:
        return f"Error processing GeoJSON file with geopandas: {e}"

    # --- 데이터 전처리 (기존과 동일) ---
    processed_data = {}
    for gu_name, info in air_quality_data.items():
        if gu_name == "error":
            continue
        normalized_gu_name = gu_name.replace(" ", "")
        try:
            max_index = int(info.get("MAXINDEX", 0))
            processed_data[normalized_gu_name] = {
                "MAXINDEX": max_index,
                "GRADE": info.get("GRADE", "N/A"),
                "PM10": info.get("PM10", "N/A"),
                "PM25": info.get("PM25", "N/A"),
            }
        except (ValueError, TypeError):
            print(
                f"Warning: Could not convert MAXINDEX for {normalized_gu_name}. Using 0."
            )
            processed_data[normalized_gu_name] = {
                "MAXINDEX": 0,
                "GRADE": info.get("GRADE", "N/A"),
                "PM10": info.get("PM10", "N/A"),
                "PM25": info.get("PM25", "N/A"),
            }

    df = pd.DataFrame.from_dict(processed_data, orient="index")
    df.index.name = "GuName"
    df.reset_index(inplace=True)

    # --- Folium 지도 생성 ---
    map_center = [37.5165, 126.9780]
    m = folium.Map(
        location=map_center, zoom_start=11, tiles="CartoDB positron_nolabels"
    )

    # --- Choropleth 레이어 추가 (복원) ---
    try:
        folium.Choropleth(
            geo_data=geojson_path,  # GeoDataFrame 또는 GeoJSON 경로/데이터 사용 가능
            data=df,
            columns=["GuName", "MAXINDEX"],
            key_on="feature.properties.SIG_KOR_NM",  # GeoJSON 속성과 매칭될 키
            fill_color="YlOrRd",
            fill_opacity=0.7,
            line_opacity=0.4,
            legend_name="통합대기환경지수(MAXINDEX)",
            highlight=True,
            name="통합대기환경지수 Choropleth",
        ).add_to(m)
    except KeyError as e:
        return f"Error creating Choropleth: Key mismatch. Check 'key_on' ('{e}') vs GeoJSON properties and DataFrame ('GuName')."
    except Exception as e:
        return f"Error creating Choropleth layer: {e}"

    # --- 중심점에 구 이름 라벨 추가 (Marker + DivIcon) ---
    # Popup 생성 함수 (여기서 다시 정의하거나 외부에서 가져옴)
    def create_popup_html(gu_name_lookup, data_dict):
        air_info = data_dict.get(
            gu_name_lookup
        )  # 정규화된 이름으로 조회해야 할 수 있음
        if air_info:
            html = f"""<h4><b>{gu_name_lookup} 대기질 정보</b></h4>
                       <p><b>등급:</b> {air_info.get('GRADE', 'N/A')}</p>
                       <p><b>통합지수(MAXINDEX):</b> {air_info.get('MAXINDEX', 'N/A')}</p>
                       <p><b>미세먼지(PM10):</b> {air_info.get('PM10', 'N/A')} µg/m³</p>
                       <p><b>초미세먼지(PM25):</b> {air_info.get('PM25', 'N/A')} µg/m³</p>"""
        else:
            html = f"<h4><b>{gu_name_lookup}</b></h4><p>대기질 데이터 없음</p>"
        return html

    # GeoDataFrame을 순회하며 마커 추가
    for idx, row in gdf.iterrows():
        gu_name = row["SIG_KOR_NM"]  # GeoDataFrame에서 구 이름 가져오기
        # 중심점 좌표 (위도, 경도 순서 확인: .y가 위도, .x가 경도)
        centroid_coords = [row["centroid"].y, row["centroid"].x]

        # 구 이름 텍스트를 표시할 DivIcon 생성
        icon_html = f'<div style="font-size: 10px; font-weight: bold; color: black; text-align: center; width: 80px; background-color: rgba(255, 255, 255, 0.5); border-radius: 3px; padding: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{gu_name}</div>'
        icon = folium.DivIcon(
            icon_size=(80, 20),  # 아이콘 크기 (조절 가능)
            icon_anchor=(40, 10),  # 아이콘 기준점 (중앙에 가깝게)
            html=icon_html,
        )

        # Popup 내용 생성 (processed_data에서 조회 필요)
        # GeoJSON의 이름과 processed_data의 키가 정확히 일치한다고 가정
        # 만약 GeoJSON에 '양천 구' 처럼 공백이 있다면 processed_data 조회 전에 정규화 필요
        normalized_gu_name_lookup = gu_name.replace(" ", "")
        popup_content = create_popup_html(normalized_gu_name_lookup, processed_data)
        popup = folium.Popup(popup_content, max_width=250)

        # 중심점에 마커 추가 (DivIcon 사용)
        folium.Marker(
            location=centroid_coords, icon=icon, popup=popup  # Popup 추가
        ).add_to(m)

    # --- Layer Control 추가 ---
    folium.LayerControl().add_to(m)

    # --- HTML 반환 ---
    return m._repr_html_()


# --- 사용 예시 ---
input_data = {
    "종로구": {"MAXINDEX": "83", "GRADE": "보통", "PM10": "75", "PM25": "36"},
    # "error": None, # 예시에서는 일단 제외
    "중구": {"MAXINDEX": "75", "GRADE": "보통", "PM10": "65", "PM25": "31"},
    "용산구": {"MAXINDEX": "90", "GRADE": "보통", "PM10": "76", "PM25": "45"},
    "성동구": {"MAXINDEX": "78", "GRADE": "보통", "PM10": "73", "PM25": "29"},
    "광진구": {"MAXINDEX": "87", "GRADE": "보통", "PM10": "71", "PM25": "37"},
    "동대문구": {"MAXINDEX": "81", "GRADE": "보통", "PM10": "77", "PM25": "32"},
    "중랑구": {"MAXINDEX": "85", "GRADE": "보통", "PM10": "80", "PM25": "39"},
    "성북구": {"MAXINDEX": "82", "GRADE": "보통", "PM10": "66", "PM25": "36"},
    "강북구": {"MAXINDEX": "85", "GRADE": "보통", "PM10": "50", "PM25": "29"},
    "도봉구": {"MAXINDEX": "76", "GRADE": "보통", "PM10": "60", "PM25": "24"},
    "노원구": {"MAXINDEX": "79", "GRADE": "보통", "PM10": "55", "PM25": "31"},
    "은평구": {"MAXINDEX": "81", "GRADE": "보통", "PM10": "89", "PM25": "35"},
    "서대문구": {"MAXINDEX": "85", "GRADE": "보통", "PM10": "79", "PM25": "43"},
    "마포구": {"MAXINDEX": "79", "GRADE": "보통", "PM10": "75", "PM25": "29"},
    "양천 구": {
        "MAXINDEX": "77",
        "GRADE": "보통",
        "PM10": "71",
        "PM25": "25",
    },  # 공백 있는 이름 테스트
    "강서구": {"MAXINDEX": "83", "GRADE": "보통", "PM10": "67", "PM25": "25"},
    "구로구": {"MAXINDEX": "85", "GRADE": "보통", "PM10": "68", "PM25": "37"},
    "금천구": {"MAXINDEX": "78", "GRADE": "보통", "PM10": "73", "PM25": "29"},
    "영등포구": {"MAXINDEX": "74", "GRADE": "보통", "PM10": "51", "PM25": "27"},
    "동작구": {"MAXINDEX": "85", "GRADE": "보통", "PM10": "78", "PM25": "36"},
    "관악구": {"MAXINDEX": "80", "GRADE": "보통", "PM10": "73", "PM25": "30"},
    "서초구": {"MAXINDEX": "87", "GRADE": "보통", "PM10": "82", "PM25": "39"},
    "강남구": {"MAXINDEX": "82", "GRADE": "보통", "PM10": "73", "PM25": "35"},
    "송파구": {"MAXINDEX": "82", "GRADE": "보통", "PM10": "77", "PM25": "40"},
    "강동구": {"MAXINDEX": "97", "GRADE": "보통", "PM10": "98", "PM25": "51"},
}

# 개선된 함수 호출
map_html_final = _fetch_air_quality_map_centroid_labels(input_data)

# 결과 확인
if map_html_final.startswith("Error:"):
    print(map_html_final)
else:
    output_filename = "seoul_air_quality_map_final.html"
    with open(output_filename, "w", encoding="utf-8") as f:
        f.write(map_html_final)
    print(f"Final map saved to {output_filename}")
    # Jupyter/Colab 환경에서 바로 표시하려면:
    # display(HTML(map_html_final))
