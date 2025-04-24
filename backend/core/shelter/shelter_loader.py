import warnings
import geopandas as gpd

try:
    from core.shelter.shelter import Shelter
except ImportError:
    print(
        "경고: 'core.shelter.shelter'에서 Shelter 클래스를 임포트할 수 없습니다. 임시 클래스를 사용하거나 경로를 확인하세요."
    )

import core.shelter.config as config
from config.settings import settings

warnings.filterwarnings("ignore")


def load_shelter_by_type(disaster_type: str) -> Shelter:
    """
    지정된 재난 유형에 해당하는 Shelter 객체를 생성하고 데이터를 로드합니다.
    """
    if disaster_type not in config.SHELTER_FILE_MAPPING:
        raise ValueError(
            f"유효하지 않은 재난 유형입니다: {disaster_type}. 유효한 유형: {list(config.SHELTER_FILE_MAPPING.keys())}"
        )

    data_file = config.SHELTER_FILE_MAPPING[disaster_type]
    shelter = Shelter(data_file, settings.SHELTER_ROOT_PATH)

    try:
        shelter.load_data()
        # GeoDataFrame 생성 시 사용할 컬럼명 지정 (config에서 가져오거나 직접 지정)
        shelter.create_geodataframe(
            lon_column=config.DEFAULT_LON_COL, lat_column=config.DEFAULT_LAT_COL
        )

        # 특정 재난 유형별 추가 처리 (예: FINE_DUST 유효 지오메트리 필터링)
        if disaster_type == "FINE_DUST":
            if shelter.gdf is not None and not shelter.gdf.empty:
                original_count = len(shelter.gdf)
                shelter.gdf = shelter.gdf[
                    shelter.gdf.geometry.is_valid & ~shelter.gdf.geometry.is_empty
                ].copy()
                if len(shelter.gdf) < original_count:
                    print(
                        f"FINE_DUST: 유효하지 않은 geometry {original_count - len(shelter.gdf)}개 제거됨."
                    )

        if shelter.gdf is None or shelter.gdf.empty:
            print(
                f"경고: {disaster_type} 유형의 대피소 데이터를 로드했으나 유효한 지리 정보가 없습니다."
            )
        else:
            print(
                f"성공: {disaster_type} 유형 대피소 {len(shelter.gdf)}개 로드 및 처리 완료."
            )

    except Exception as e:
        print(f"오류: {disaster_type} 유형 대피소 처리 중 오류 발생: {e}")
        # 오류 발생 시 빈 GeoDataFrame을 가진 Shelter 객체 반환 고려
        if shelter.gdf is None:
            shelter.gdf = gpd.GeoDataFrame()  # 최소한 빈 GDF 보장

    return shelter
