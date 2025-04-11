from pathlib import Path
from typing import Optional, Tuple

import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
from pyproj import Transformer


class Shelter:
    """대피소 데이터를 처리하는 기본 클래스"""

    def __init__(self, data_path: str | Path, root_path: str | Path) -> None:
        self.data_path = Path(data_path)
        self.root_path = Path(root_path)
        self.df: Optional[pd.DataFrame] = None
        self.gdf: Optional[gpd.GeoDataFrame] = None

    def load_data(self) -> pd.DataFrame:
        """CSV 파일에서 대피소 데이터를 로드합니다.

        Returns:
            pd.DataFrame: 로드된 데이터프레임

        Raises:
            FileNotFoundError: 파일을 찾을 수 없는 경우
            ValueError: 데이터 로드 중 오류 발생시
        """
        file_path = self.root_path / self.data_path

        if not file_path.exists():
            raise FileNotFoundError(f"파일을 찾을 수 없습니다: {file_path}")

        try:
            self.df = pd.read_csv(file_path, encoding="euc-kr")
        except:
            self.df = pd.read_csv(file_path)

        return self.df

    def transform_geometry(
        self,
        x_column: str,
        y_column: str,
        from_crs: str = "epsg:5186",
        to_crs: str = "epsg:4326",
    ) -> Tuple[pd.Series, pd.Series]:
        """좌표계를 변환합니다.

        Args:
            x_column: X좌표(경도) 컬럼명
            y_column: Y좌표(위도) 컬럼명
            from_crs: 원본 좌표계 (기본값: EPSG:5186)
            to_crs: 대상 좌표계 (기본값: EPSG:4326)

        Returns:
            Tuple[pd.Series, pd.Series]: 변환된 (경도, 위도) 시리즈

        Raises:
            ValueError: 데이터프레임이 로드되지 않은 경우
        """
        if self.df is None:
            raise ValueError("데이터를 먼저 로드해주세요.")

        transformer = Transformer.from_crs(from_crs, to_crs, always_xy=True)
        lon, lat = transformer.transform(
            self.df[x_column].values, self.df[y_column].values
        )

        self.df["경도"] = lon
        self.df["위도"] = lat

        return lon, lat

    def create_geodataframe(
        self, lon_column: str = "경도", lat_column: str = "위도", crs: str = "epsg:4326"
    ) -> gpd.GeoDataFrame:
        """포인트 지오메트리를 생성하여 GeoDataFrame을 만듭니다.

        Args:
            lon_column: 경도 컬럼명
            lat_column: 위도 컬럼명
            crs: 좌표계 (기본값: EPSG:4326)

        Returns:
            gpd.GeoDataFrame: 생성된 지오데이터프레임

        Raises:
            ValueError: 데이터프레임이 로드되지 않은 경우
        """
        if self.df is None:
            raise ValueError("데이터를 먼저 로드해주세요.")

        geometry = [Point(xy) for xy in zip(self.df[lon_column], self.df[lat_column])]
        self.gdf = gpd.GeoDataFrame(self.df, geometry=geometry, crs=crs)

        return self.gdf
