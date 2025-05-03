from fastapi import APIRouter, Depends, Query, HTTPException
import logging
import pandas as pd

from config.settings import settings
from app.schemas.response_models import (
    DistrictsResponse,
    DongsResponse,
    CoordinatesReponse,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api")

DATA_DIR = settings.DATASETS_DIR / "coord" / "seoul_districts_coordinates.csv"
df = pd.read_csv(DATA_DIR).dropna(axis=0)


@router.get("/districts", response_model=DistrictsResponse)
async def get_districts() -> DistrictsResponse:
    """
    서울시 전체 "구"목록 반환
    """
    logger.info(f"Districts API request received")
    error = ""

    try:
        districts = list(df["시군구"].unique())
    except Exception as e:
        logger.exception(f"Error getting districts info: {e}")
        districts = []
        error = e

    response = DistrictsResponse(districts=districts, error=error)

    return response


@router.get("/dongs", response_model=DongsResponse)
async def get_dongs(gu: str = Query(...)):
    """
    "구"에 포함되는 모든 행정동 반환
    """

    logger.info(f"Dongs API request received: {gu}")
    error = ""

    try:
        district_df = df[df["시군구"] == gu]
        dongs = list(district_df["읍면동/구"].unique())
    except Exception as e:
        logger.exception(f"Error getting dongs info: {e}")
        dongs = []
        error = e

    response = DongsResponse(dongs=dongs, error=error)

    return response


@router.get("/coordinates", response_model=CoordinatesReponse)
async def get_coords(
    gu: str = Query(...), dong: str = Query(...)
) -> CoordinatesReponse:
    """
    행정동에 맞는 위 경도 좌표 반환
    """
    logger.info(f"Coordinates API request recieved: Gu - {gu}, Dong - {dong}")
    error = ""

    try:
        filtered_df = df[(df["시군구"] == gu) & (df["읍면동/구"] == dong)]
        print(filtered_df)
        lat = filtered_df["위도"]
        lon = filtered_df["경도"]
    except Exception as e:
        logger.info(f"Error getting Coordinates info: {e}")
        raise HTTPException(status_code=404, detail="Dong not found in specified Gu")

    response = CoordinatesReponse(latitude=lat, longitude=lon, error=error)
    return response
