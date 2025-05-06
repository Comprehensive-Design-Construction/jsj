import folium
import pandas as pd
import os
import geopandas as gpd
import logging
from shapely.errors import TopologicalError  # TopologicalError 임포트 추가

logger = logging.getLogger(__name__)


def _load_geojson_and_calculate_centroids(geojson_path: str) -> gpd.GeoDataFrame | None:
    """GeoJSON 파일을 로드하고 중심점을 계산하여 GeoDataFrame을 반환합니다."""
    try:
        # GeoJSON 파일 경로 확인 (상대 경로 처리 포함)
        if not os.path.exists(geojson_path):
            script_dir = (
                os.path.dirname(os.path.abspath(__file__))
                if "__file__" in globals()
                else "."
            )
            alt_geojson_path = os.path.join(
                script_dir, "seoul_municipalities_geo.json"
            )  # 스크립트 위치 기준 대체 경로

            # __file__ 기반 경로 재시도 (더 상위 디렉토리 구조 가정)
            if not os.path.exists(geojson_path) and "__file__" in globals():
                try:
                    base_dir = os.path.dirname(
                        os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
                    )
                    geojson_path_alt2 = os.path.join(
                        base_dir,
                        "backend",
                        "datasets",
                        "map",
                        "seoul_municipalities_geo.json",
                    )
                    if os.path.exists(geojson_path_alt2):
                        geojson_path = geojson_path_alt2
                        print(
                            f"Found GeoJSON at alternate project path: {geojson_path}"
                        )
                    elif os.path.exists(alt_geojson_path):  # 스크립트 위치 기준 재확인
                        geojson_path = alt_geojson_path
                        print(f"Found GeoJSON at script directory: {geojson_path}")
                    else:
                        raise FileNotFoundError  # 못 찾으면 에러 발생시킴
                except NameError:  # __file__ 정의 안된 경우 스크립트 위치 기준만 확인
                    if os.path.exists(alt_geojson_path):
                        geojson_path = alt_geojson_path
                        print(f"Found GeoJSON at script directory: {geojson_path}")
                    else:
                        raise FileNotFoundError

            elif os.path.exists(
                alt_geojson_path
            ):  # 초기 경로 없고 __file__ 없을 때 스크립트 기준 경로 확인
                geojson_path = alt_geojson_path
                print(f"Found GeoJSON at script directory: {geojson_path}")
            elif not os.path.exists(geojson_path):  # 모든 경로 탐색 실패
                print(
                    f"Error: GeoJSON file not found at primary path, script path, or project path."
                )
                return None

        # GeoJSON 로드 및 처리
        gdf = gpd.read_file(geojson_path, encoding="utf-8")
        if gdf.crs and gdf.crs.to_epsg() != 4326:
            print(f"Converting CRS from {gdf.crs} to EPSG:4326")
            gdf = gdf.to_crs(epsg=4326)

        try:
            # tolerance 값은 실험적으로 조정해야 합니다. (값이 클수록 더 많이 단순화)
            # 예: 0.0001, 0.0005, 0.001 등
            tolerance = 0.0005  # <--- 이 값을 조정해보세요
            original_memory = gdf.memory_usage(deep=True).sum()
            # preserve_topology=True 옵션은 폴리곤의 위상 관계를 유지하려 시도합니다.
            gdf["geometry"] = gdf.geometry.simplify(
                tolerance=tolerance, preserve_topology=True
            )
            simplified_memory = gdf.memory_usage(deep=True).sum()
            logger.info(
                f"Simplified GeoJSON geometry with tolerance {tolerance}. Memory usage: {original_memory} -> {simplified_memory}"
            )
        except TopologicalError as te:
            logger.warning(
                f"Could not simplify geometry due to topological error: {te}. Using original geometry."
            )
        except Exception as e:
            logger.error(
                f"Error during geometry simplification: {e}. Using original geometry."
            )
        # --- Geometry 단순화 코드 끝 ---

        # 중심점 계산
        print("Calculating centroids...")
        gdf["centroid"] = gdf.geometry.centroid

        if "SIG_KOR_NM" not in gdf.columns:
            print("Error: GeoDataFrame missing 'SIG_KOR_NM' column.")
            return None

        return gdf

    except ImportError:
        print("Error: geopandas library is required but not installed.")
        return None
    except FileNotFoundError:
        print(f"Error: GeoJSON file could not be located.")
        return None
    except Exception as e:
        print(f"Error processing GeoJSON file with geopandas: {e}")
        return None


def _create_base_map(center=[37.5165, 126.9780], zoom=11) -> folium.Map:
    """기본 Folium 지도 객체를 생성합니다."""
    return folium.Map(
        location=center, zoom_start=zoom, tiles="CartoDB positron_nolabels"
    )


def _add_choropleth(
    m: folium.Map,
    gdf: gpd.GeoDataFrame,
    data_df: pd.DataFrame,
    columns: list,
    key_on_property: str = "SIG_KOR_NM",  # GeoDataFrame의 구 이름 컬럼
    fill_color: str = "YlGn",
    legend_name: str = "",
    bins=None,
    name: str = "Choropleth Layer",
):
    """지도에 Choropleth 레이어를 추가합니다."""
    if key_on_property not in gdf.columns:
        print(
            f"Error: GeoDataFrame does not contain '{key_on_property}' column needed for key_on."
        )
        return

    # Choropleth용 GeoDataFrame 준비 (geometry + 인덱스용 컬럼)
    gdf_for_choropleth = gdf[["geometry", key_on_property]].set_index(key_on_property)

    try:
        choropleth_args = {
            "geo_data": gdf_for_choropleth,
            "data": data_df,
            "columns": columns,
            "key_on": "feature.id",
            "fill_color": fill_color,
            "fill_opacity": 0.7,
            "line_opacity": 0.4,
            "legend_name": legend_name,
            "highlight": True,
            "name": name,
        }

        if bins is not None:
            # bins 값이 유효한 타입인지 간단히 확인 (더 엄격한 검사도 가능)
            if not isinstance(bins, (int, str, list, tuple)):
                print(
                    f"Warning: Invalid type for bins ({type(bins)}). Expected int, str, list, or tuple. Ignoring bins."
                )
            else:
                choropleth_args["bins"] = bins  # 유효한 경우에만 추가

        folium.Choropleth(**choropleth_args).add_to(m)

    except Exception as e:
        print(f"Error adding Choropleth layer: {e}")


def _add_centroid_labels_and_popups(
    m: folium.Map,
    gdf: gpd.GeoDataFrame,  # 원본 gdf (centroid 포함)
    processed_data: dict,  # 조회용 데이터 딕셔너리
    popup_html_func: callable,  # 팝업 HTML 생성 함수
    name_property: str = "SIG_KOR_NM",  # GeoDataFrame의 구 이름 컬럼
):
    """지도에 중심점 라벨(DivIcon)과 팝업(Marker)을 추가합니다."""
    if "centroid" not in gdf.columns:
        print("Error: GeoDataFrame does not contain 'centroid' column.")
        return
    if name_property not in gdf.columns:
        print(f"Error: GeoDataFrame does not contain '{name_property}' column.")
        return

    for idx, row in gdf.iterrows():
        gu_name = row[name_property]
        centroid_coords = [row["centroid"].y, row["centroid"].x]

        # DivIcon 라벨
        icon_html = f'<div style="font-size: 10px; font-weight: bold; color: black; text-align: center; background-color: transparent; text-shadow: 0px 0px 2px #FFFFFF, 0px 0px 4px #FFFFFF;">{gu_name}</div>'
        icon = folium.DivIcon(icon_size=(80, 20), icon_anchor=(40, 10), html=icon_html)

        # 팝업 생성
        normalized_gu_name = gu_name.replace(" ", "")
        popup_content = popup_html_func(normalized_gu_name, processed_data)
        popup = folium.Popup(popup_content, max_width=250)

        # 마커 추가
        folium.Marker(location=centroid_coords, icon=icon, popup=popup).add_to(m)
