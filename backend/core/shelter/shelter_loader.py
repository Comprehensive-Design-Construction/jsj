import warnings
import geopandas as gpd
import logging  # 로깅 추가

try:
    from core.shelter.shelter import Shelter
except ImportError:
    print(
        "경고: 'core.shelter.shelter'에서 Shelter 클래스를 임포트할 수 없습니다. 임시 클래스를 사용하거나 경로를 확인하세요."
    )

    # Fallback or define a dummy class if necessary
    class Shelter:
        def __init__(self, data_file, root_path):
            self.data_file = data_file
            self.root_path = root_path
            self.df = None
            self.gdf = None

        def load_data(self):
            pass

        def create_geodataframe(self, lon_column, lat_column):
            pass


import core.shelter.config as config
from config.settings import settings

warnings.filterwarnings("ignore")
logger = logging.getLogger(__name__)  # 로거 설정

# --- 변경: 로드된 Shelter 객체를 저장할 캐시 ---
shelter_data_cache = {}
# ------------------------------------------


def load_shelter_by_type(disaster_type: str) -> Shelter:
    """
    지정된 재난 유형에 해당하는 Shelter 객체를 생성하고 데이터를 로드합니다.
    데이터 로딩 결과를 캐시하여 중복 로딩을 방지합니다.
    """
    # --- 변경: 캐시 확인 ---
    if disaster_type in shelter_data_cache:
        logger.info(f"Cache hit: Returning cached Shelter object for '{disaster_type}'")
        return shelter_data_cache[disaster_type]
    # --------------------

    logger.info(f"Cache miss: Loading shelter data for '{disaster_type}'")

    if disaster_type not in config.SHELTER_FILE_MAPPING:
        raise ValueError(
            f"유효하지 않은 재난 유형입니다: {disaster_type}. 유효한 유형: {list(config.SHELTER_FILE_MAPPING.keys())}"
        )

    data_file = config.SHELTER_FILE_MAPPING[disaster_type]
    shelter = Shelter(data_file, settings.SHELTER_ROOT_PATH)

    try:
        shelter.load_data()
        # 데이터 로드 실패 시 처리 (예: shelter.df가 None일 경우)
        if shelter.df is None:
            raise RuntimeError(
                f"'{disaster_type}' 유형의 데이터를 로드하지 못했습니다 ({data_file})."
            )

        shelter.create_geodataframe(
            lon_column=config.DEFAULT_LON_COL, lat_column=config.DEFAULT_LAT_COL
        )

        # 특정 재난 유형별 추가 처리
        if disaster_type == "FINE_DUST":
            if shelter.gdf is not None and not shelter.gdf.empty:
                original_count = len(shelter.gdf)
                shelter.gdf = shelter.gdf[
                    shelter.gdf.geometry.is_valid & ~shelter.gdf.geometry.is_empty
                ].copy()
                if len(shelter.gdf) < original_count:
                    logger.warning(  # print 대신 로거 사용
                        f"FINE_DUST: 유효하지 않은 geometry {original_count - len(shelter.gdf)}개 제거됨."
                    )

        if shelter.gdf is None or shelter.gdf.empty:
            logger.warning(  # print 대신 로거 사용
                f"경고: {disaster_type} 유형의 대피소 데이터를 로드했으나 유효한 지리 정보가 없습니다."
            )
            # 유효 데이터 없더라도 빈 GeoDataFrame을 가진 객체를 캐시할지 결정 필요
            # 여기서는 빈 객체라도 캐싱하여 반복적인 로딩 시도를 막음
            shelter_data_cache[disaster_type] = shelter
            return shelter
        else:
            logger.info(  # print 대신 로거 사용
                f"성공: {disaster_type} 유형 대피소 {len(shelter.gdf)}개 로드 및 처리 완료."
            )
            # --- 변경: 성공 시 캐시에 저장 ---
            shelter_data_cache[disaster_type] = shelter
            # --------------------------

    except Exception as e:
        logger.error(
            f"오류: {disaster_type} 유형 대피소 처리 중 오류 발생: {e}", exc_info=True
        )
        # 오류 발생 시 빈 GeoDataFrame을 가진 Shelter 객체 반환하거나, None 반환 또는 예외 재발생 고려
        # 여기서는 오류 시 캐싱하지 않고 예외를 다시 발생시켜 상위 호출자에게 알림
        raise e  # 오류 발생 시 캐시에 저장하지 않고 예외 전파

    return shelter
