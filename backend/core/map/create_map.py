import folium
import pandas as pd
from core.map.common_functions import (
    _load_geojson_and_calculate_centroids,
    _create_base_map,
    _add_choropleth,
    _add_centroid_labels_and_popups,
)
import logging

logger = logging.getLogger(__name__)


def _create_air_quality_popup_html(gu_name_lookup: str, data_dict: dict) -> str:
    """대기질 데이터용 팝업 HTML을 생성합니다."""
    air_info = data_dict.get(gu_name_lookup)
    if air_info:
        html = f"""<h4><b>{gu_name_lookup} 대기질 정보</b></h4>
                   <p><b>등급:</b> {air_info.get('GRADE', 'N/A')}</p>
                   <p><b>통합지수(MAXINDEX):</b> {air_info.get('MAXINDEX', 'N/A')}</p>
                   <p><b>미세먼지(PM10):</b> {air_info.get('PM10', 'N/A')} µg/m³</p>
                   <p><b>초미세먼지(PM25):</b> {air_info.get('PM25', 'N/A')} µg/m³</p>"""
    else:
        html = f"<h4><b>{gu_name_lookup}</b></h4><p>대기질 데이터 없음</p>"
    return html


def _create_uv_popup_html(gu_name_lookup: str, data_dict: dict) -> str:
    """UV 데이터용 팝업 HTML을 생성합니다."""
    uv_value = data_dict.get(gu_name_lookup, "N/A")
    # UV 등급 계산 로직
    uv_grade = "N/A"
    if uv_value != "N/A":
        try:
            uv = int(uv_value)
            if uv <= 2:
                uv_grade = "낮음 (Low)"
            elif uv <= 5:
                uv_grade = "보통 (Moderate)"
            elif uv <= 7:
                uv_grade = "높음 (High)"
            elif uv <= 10:
                uv_grade = "매우 높음 (Very High)"
            else:
                uv_grade = "위험 (Extreme)"
        except (ValueError, TypeError):
            uv_grade = "N/A"

    html = f"""<h4><b>{gu_name_lookup} 자외선 정보</b></h4>
               <p><b>자외선 지수(UV):</b> {uv_value}</p>
               <p><b>등급:</b> {uv_grade}</p>"""
    return html


# --- 최종 지도 생성 함수 (래퍼 함수) ---


def fetch_air_quality_map(
    air_quality_data: dict, geojson_path: str = None
) -> str | None:
    """서울시 대기질 현황 지도를 생성합니다."""

    # geojson_path 기본값 설정 (None일 경우 기본 경로 사용 시도)
    if geojson_path is None:
        geojson_path = "./backend/datasets/map/seoul_municipalities_geo.json"  # 기본 경로 (필요시 수정)

    # 1. GeoJSON 로드 및 중심점 계산
    gdf = _load_geojson_and_calculate_centroids(geojson_path)
    if gdf is None:
        return "Error: Failed to load or process GeoJSON."

    # 2. 데이터 전처리
    processed_data = {}
    value_list = []  # Choropleth용 데이터 리스트
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
            value_list.append({"GuName": normalized_gu_name, "Value": max_index})
        except (ValueError, TypeError):
            print(
                f"Warning: Could not convert MAXINDEX for {normalized_gu_name}. Using 0."
            )
            processed_data[normalized_gu_name] = {
                "MAXINDEX": 0,
                "GRADE": "N/A",
                "PM10": "N/A",
                "PM25": "N/A",
            }
            value_list.append({"GuName": normalized_gu_name, "Value": 0})

    data_df = pd.DataFrame(value_list)
    if data_df.empty:
        print("Warning: No valid air quality data processed for Choropleth.")
        # 빈 데이터프레임으로 Choropleth 생성 시도 또는 기본 지도만 반환 결정 가능
        # return _create_base_map()._repr_html_() # 예: 기본 지도만 반환

    # 3. 기본 지도 생성
    m = _create_base_map()

    # 4. Choropleth 추가
    _add_choropleth(
        m=m,
        gdf=gdf,
        data_df=data_df,
        columns=["GuName", "Value"],  # DataFrame의 컬럼명과 일치해야 함
        key_on_property="SIG_KOR_NM",
        fill_color="YlOrRd",
        legend_name="통합대기환경지수(MAXINDEX)",
        bins=None,  # 필요시 구간 설정 [0, 50, 100, 150, 200, max(250, data_df['Value'].max())] 등
        name="대기질 Choropleth",
    )

    # 5. 라벨 및 팝업 추가
    _add_centroid_labels_and_popups(
        m=m,
        gdf=gdf,
        processed_data=processed_data,  # 팝업 내용 조회용
        popup_html_func=_create_air_quality_popup_html,  # 대기질 팝업 함수 전달
        name_property="SIG_KOR_NM",
    )

    # 6. 레이어 컨트롤 추가 및 HTML 반환
    folium.LayerControl().add_to(m)

    try:
        map_html_content = m._repr_html_()
        html_size_bytes = len(map_html_content.encode("utf-8"))
        html_size_mb = html_size_bytes / (1024 * 1024)
        logger.info(
            f"Generated Fine Dust Map HTML size: {html_size_mb:.2f} MB"
        )  # 크기를 MB 단위로 로깅
        return map_html_content
    except Exception as e:
        logger.error(f"Error generating or logging Fine Dust map HTML: {e}")
        return "Error generating map HTML."  # 오류 발생 시 대체 문자열 반환


def fetch_uv_map(uv_data: dict, geojson_path: str = None) -> str | None:
    """서울시 자외선 지수 현황 지도를 생성합니다."""

    # geojson_path 기본값 설정
    if geojson_path is None:
        geojson_path = "./backend/datasets/map/seoul_municipalities_geo.json"  # 기본 경로 (필요시 수정)

    # 1. GeoJSON 로드 및 중심점 계산
    gdf = _load_geojson_and_calculate_centroids(geojson_path)
    if gdf is None:
        return "Error: Failed to load or process GeoJSON."

    # 2. 데이터 전처리
    processed_data = {}
    value_list = []
    for gu_name, uv_index in uv_data.items():
        normalized_gu_name = gu_name.replace(" ", "")
        try:
            uv_val = int(uv_index)
            processed_data[normalized_gu_name] = uv_val
            value_list.append({"GuName": normalized_gu_name, "Value": uv_val})
        except (ValueError, TypeError):
            print(
                f"Warning: Invalid UV index '{uv_index}' for {normalized_gu_name}. Skipping."
            )
            # processed_data[normalized_gu_name] = None # 또는 0
            # value_list.append({"GuName": normalized_gu_name, "Value": 0}) # 또는 스킵

    data_df = pd.DataFrame(value_list)
    if data_df.empty:
        print("Warning: No valid UV data processed for Choropleth.")

    # 3. 기본 지도 생성
    m = _create_base_map()

    # 4. Choropleth 추가
    # 값 변경 필요.
    uv_bins = [
        0,
        3,
        6,
        8,
        11,
        max(12, data_df["Value"].max() if not data_df.empty else 12),
    ]
    _add_choropleth(
        m=m,
        gdf=gdf,
        data_df=data_df,
        columns=["GuName", "Value"],
        key_on_property="SIG_KOR_NM",
        fill_color="YlOrRd",  # UV에 YlOrRd 사용
        legend_name="자외선 지수 (UV Index)",
        bins=uv_bins,
        name="자외선 지수 Choropleth",
    )

    # 5. 라벨 및 팝업 추가
    _add_centroid_labels_and_popups(
        m=m,
        gdf=gdf,
        processed_data=processed_data,  # UV 값 조회용
        popup_html_func=_create_uv_popup_html,  # UV 팝업 함수 전달
        name_property="SIG_KOR_NM",
    )

    # 6. 레이어 컨트롤 추가 및 HTML 반환
    folium.LayerControl().add_to(m)

    # <<< fit_bounds 코드 추가 시작 >>>

    if gdf is not None and not gdf.empty:
        # GeoDataFrame의 전체 경계를 가져옵니다.
        min_lon, min_lat, max_lon, max_lat = gdf.total_bounds
        # fit_bounds에 전달할 경계 좌표를 생성합니다: [[남서쪽_lat, 남서쪽_lon], [북동쪽_lat, 북동쪽_lon]]
        bounds = [[min_lat, min_lon], [max_lat, max_lon]]
        m.fit_bounds(bounds)
        # 필요하다면 경계에 약간의 여백(padding)을 줄 수 있습니다.
        # 예: m.fit_bounds(bounds, padding=(0.01, 0.01)) # 상하좌우 1% 여백

    try:
        map_html_content = m._repr_html_()
        html_size_bytes = len(map_html_content.encode("utf-8"))
        html_size_mb = html_size_bytes / (1024 * 1024)
        logger.info(
            f"Generated UV Map HTML size: {html_size_mb:.2f} MB"
        )  # 크기를 MB 단위로 로깅
        return map_html_content
    except Exception as e:
        logger.error(f"Error generating or logging UV map HTML: {e}")
        return "Error generating map HTML."


# --- 사용 예시 ---

if __name__ == "__main__":

    # GeoJSON 파일 경로 (스크립트 실행 위치 기준 또는 절대 경로)
    # geojson_file = "./backend/datasets/map/seoul_municipalities_geo.json"
    # 만약 위 함수들에서 경로 탐색이 잘 안된다면 여기서 명시적으로 지정
    geojson_file = None  # 함수 내에서 기본 경로 또는 탐색 사용

    # 1. 미세먼지 데이터 지도 생성 예시
    air_quality_input_data = {
        "종로구": {"MAXINDEX": "83", "GRADE": "보통", "PM10": "75", "PM25": "36"},
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
        "양천 구": {"MAXINDEX": "77", "GRADE": "보통", "PM10": "71", "PM25": "25"},
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
    map_html_air = fetch_air_quality_map(
        air_quality_input_data, geojson_path=geojson_file
    )
    if map_html_air and not map_html_air.startswith("Error:"):
        output_filename_air = "seoul_air_quality_map_refactored.html"
        with open(output_filename_air, "w", encoding="utf-8") as f:
            f.write(map_html_air)
        print(f"Air quality map saved to {output_filename_air}")
    elif map_html_air:
        print(map_html_air)  # 오류 메시지 출력

    print("-" * 30)

    # 2. UV 데이터 지도 생성 예시
    uv_input_data = {
        "종로구": 6,
        "중구": 6,
        "용산구": 6,
        "성동구": 5,
        "광진구": 6,
        "동대문구": 5,
        "중랑구": 5,
        "성북구": 5,
        "강북구": 6,
        "도봉구": 5,
        "노원구": 6,
        "은평구": 6,
        "서대문구": 6,
        "마포구": 6,
        "양천구": 6,
        "강서구": 6,
        "구로구": 6,
        "금천구": 6,
        "영등포구": 6,
        "동작구": 6,
        "관악구": 6,
        "서초구": 6,
        "강남구": 6,
        "송파구": 5,
        "강동구": 5,
    }
    map_html_uv = fetch_uv_map(uv_input_data, geojson_path=geojson_file)
    if map_html_uv and not map_html_uv.startswith("Error:"):
        output_filename_uv = "seoul_uv_index_map_refactored.html"
        with open(output_filename_uv, "w", encoding="utf-8") as f:
            f.write(map_html_uv)
        print(f"UV index map saved to {output_filename_uv}")
    elif map_html_uv:
        print(map_html_uv)  # 오류 메시지 출력
