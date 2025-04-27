import matplotlib.colors as mcolors
import folium
import geopandas as gpd
import branca
import pandas as pd


def convert_to_hex_color(color_value, default_color="#808080"):
    """값이 유효한 Hex 문자열인지 확인하고, RGBA 튜플이면 Hex로 변환, 그 외는 기본값 반환."""
    if isinstance(color_value, str) and color_value.startswith("#"):
        return color_value
    elif isinstance(color_value, (tuple, list)) and len(color_value) in [3, 4]:
        try:
            hex_color = mcolors.to_hex(color_value, keep_alpha=False)
            return hex_color
        except Exception as e:
            return default_color
    else:
        return default_color


def _fetch_flood_trace_html():
    # --- 파일 읽기 ---
    try:
        gdf = gpd.read_file("./backend/datasets/map/flood.gpkg")
    except Exception as e:
        print(f"Error reading GeoPackage: {e}")
        return
    if "depth_category" not in gdf.columns:
        print("Error: 'depth_category' column not found.")
        return

    # --- 색상 맵 생성 (Branca에서 Hex 가져옴) ---
    unique_cats = sorted(
        [
            cat
            for cat in gdf["depth_category"].unique()
            if pd.notna(cat) and cat != "기타"
        ]
    )
    n_unique_cats = len(unique_cats)
    base_colors = branca.colormap.linear.Blues_09.colors

    if len(base_colors) > n_unique_cats and n_unique_cats > 1:
        effective_base_colors = base_colors[1:]
    else:
        effective_base_colors = base_colors
    n_colors_available = len(effective_base_colors)

    colors_list = []
    if n_unique_cats > 0:
        if n_unique_cats == 1:
            colors_list = [effective_base_colors[len(effective_base_colors) // 2]]
        elif n_unique_cats <= len(effective_base_colors):
            indices = [
                int(i * (len(effective_base_colors) - 1) / (n_unique_cats - 1))
                for i in range(n_unique_cats)
            ]
            colors_list = [effective_base_colors[idx] for idx in indices]
        else:
            colors_list = [
                effective_base_colors[i % len(effective_base_colors)]
                for i in range(n_unique_cats)
            ]
    else:
        colors_list = []

    color_map = dict(zip(unique_cats, colors_list))
    default_color_value = "#808080"
    color_map["기타"] = default_color_value
    # --- 색상 맵 생성 끝 ---

    # --- *** map_color 컬럼 적용 및 변환 *** ---
    gdf["map_color_raw"] = (
        gdf["depth_category"].map(color_map).fillna(default_color_value)
    )

    gdf["map_color"] = gdf["map_color_raw"].apply(
        convert_to_hex_color, default_color=default_color_value
    )

    gdf = gdf.drop(columns=["map_color_raw"])
    # --- *** 변환 완료 *** ---

    gdf_cleaned = gdf[
        [
            "ID",
            "LAYER",
            "depth_category",
            "ELEVATION",
            "THICKNESS",
            "map_color",
            "geometry",
        ]
    ].copy()

    # --- 3. Folium 지도 생성 ---
    try:
        min_lon, min_lat, max_lon, max_lat = gdf_cleaned.total_bounds
        map_center = [(min_lat + max_lat) / 2, (min_lon + max_lon) / 2]
    except Exception:
        map_center = [37.5665, 126.9780]

    m = folium.Map(
        location=map_center,
        zoom_start=11,  # tiles="CartoDB positron"
    )

    def style_function(feature):
        hex_color = feature["properties"].get("map_color", default_color_value)
        if not isinstance(hex_color, str) or not hex_color.startswith("#"):
            hex_color = default_color_value
        return {
            "fillColor": hex_color,
            "color": "#000000",
            "weight": 1.5,
            "fillOpacity": 0.85,
        }

    tooltip_fields = ["depth_category"]
    tooltip_aliases = ["침수 깊이:"]
    folium.GeoJson(
        gdf_cleaned,
        style_function=style_function,
        tooltip=folium.features.GeoJsonTooltip(
            fields=tooltip_fields, aliases=tooltip_aliases, localize=True, sticky=False
        ),
    ).add_to(m)

    legend_html = """
         <div style="position: fixed; bottom: 50px; left: 50px; width: 180px; height: auto; border:2px solid grey; z-index:9999; font-size:14px; background-color: white; padding: 10px; opacity: 0.9;">
         <b>범례: 침수 깊이</b><br>"""
    for category in unique_cats:
        color = convert_to_hex_color(color_map.get(category, "#FFFFFF"))
        legend_html += f'<i style="background:{color}; width:18px; height:18px; display: inline-block; vertical-align: middle;"></i> {category}<br>'

    legend_html += "</div>"
    m.get_root().html.add_child(folium.Element(legend_html))

    return m._repr_html_()


if __name__ == "__main__":
    print(_fetch_flood_trace_html())
