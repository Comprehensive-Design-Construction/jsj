import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
import os


class Shelter:
    """대피소 데이터를 처리하는 기본 클래스"""

    def __init__(
        self, data_file_name: str, root_path: str = "./datasets/shelter"
    ) -> None:
        self.data_file_name = data_file_name
        self.root_path = root_path
        self.data_path = os.path.join(root_path, data_file_name).replace("\\", "/")
        self.df: pd.DataFrame | None = None
        self.gdf: gpd.GeoDataFrame | None = None
        print(f"Shelter initialized with data path: {self.data_path}")

    def load_data(self) -> pd.DataFrame:
        """CSV 파일에서 대피소 데이터를 로드합니다.

        Returns:
            pd.DataFrame: 로드된 데이터프레임

        Raises:
            FileNotFoundError: 파일을 찾을 수 없는 경우
            ValueError: 데이터 로드 중 오류 발생시
        """
        file_path = self.data_path

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"파일을 찾을 수 없습니다: {file_path}")

        try:
            self.df = pd.read_csv(file_path, encoding="euc-kr")
        except:
            self.df = pd.read_csv(file_path)

    def create_geodataframe(self, lon_column: str = "경도", lat_column: str = "위도"):
        """Pandas DataFrame을 GeoDataFrame으로 변환합니다."""
        if self.df is None or self.df.empty:
            print("Cannot create GeoDataFrame: DataFrame is not loaded or empty.")
            self.gdf = None
            return

        if lat_column not in self.df.columns or lon_column not in self.df.columns:
            print(
                f"Error: Latitude ('{lat_column}') or Longitude ('{lon_column}') column not found in DataFrame."
            )
            self.gdf = None
            return

        # 유효한 좌표 데이터만 필터링 (결측치 제거, 타입 변환)
        df_filtered = self.df.dropna(subset=[lon_column, lat_column]).copy()
        try:
            df_filtered[lon_column] = pd.to_numeric(
                df_filtered[lon_column], errors="coerce"
            )
            df_filtered[lat_column] = pd.to_numeric(
                df_filtered[lat_column], errors="coerce"
            )
            df_filtered = df_filtered.dropna(subset=[lon_column, lat_column])
        except Exception as e:
            print(f"Error converting coordinate columns to numeric: {e}")
            self.gdf = None
            return

        if df_filtered.empty:
            print("No valid coordinate data found after filtering.")
            self.gdf = None
            return

        try:
            geometry = [
                Point(xy)
                for xy in zip(df_filtered[lon_column], df_filtered[lat_column])
            ]
            self.gdf = gpd.GeoDataFrame(
                df_filtered, geometry=geometry, crs="EPSG:4326"
            )  # WGS84 좌표계 설정
            print(f"GeoDataFrame created successfully. Shape: {self.gdf.shape}")
        except Exception as e:
            print(f"Error creating GeoDataFrame: {e}")
            self.gdf = None

    def get_filtered_by_radius(
        self, user_location: Point, radius_km: float
    ) -> gpd.GeoDataFrame | None:
        """사용자 위치 기준 반경 내 대피소 GeoDataFrame을 반환합니다."""
        if self.gdf is None or self.gdf.empty:
            print("No GeoDataFrame available for filtering.")
            return None

        try:
            gdf_proj = self.gdf.to_crs(epsg=5179)
            user_location_proj = gpd.GeoSeries([user_location], crs="EPSG:4326").to_crs(
                epsg=5179
            )[0]

            # 반경(km)을 미터(m)로 변환
            radius_meters = radius_km * 1000
            # 사용자 위치 주변 버퍼 생성
            user_buffer = user_location_proj.buffer(radius_meters)

            # 버퍼 내에 포함되는 대피소 인덱스 찾기
            indices_within = self.gdf.index[gdf_proj.within(user_buffer)]

            if not indices_within.empty:
                # 원본 gdf에서 해당 인덱스 데이터 추출 (CRS는 원본 유지)
                filtered_gdf = self.gdf.loc[indices_within].copy()
                print(
                    f"Found {len(filtered_gdf)} shelters within {radius_km} km radius."
                )
                return filtered_gdf
            else:
                print(f"No shelters found within {radius_km} km radius.")
                return gpd.GeoDataFrame(
                    columns=self.gdf.columns, geometry=[], crs=self.gdf.crs
                )  # 빈 GeoDataFrame 반환

        except Exception as e:
            print(f"Error during radius filtering: {e}")
            return None
