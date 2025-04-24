from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import asyncio
import atexit
from apscheduler.schedulers.background import BackgroundScheduler
import uvicorn

# 캐시 업데이트 함수 임포트
from app.cache import (
    update_food_poisoning_cache,
    update_fine_dust_cache,
    update_uv_cache,
    update_fine_dust_map_cache,
    update_uv_map_cache,
    update_flood_trace_cache,
)

# 데이터 수집 함수 임포트
from core.indexing.get_poison import fetch_food_poisoning_data
from core.indexing.get_fine_dust import fetch_fine_dust_data
from core.indexing.get_uv import fetch_uv_index
from core.map.create_map import fetch_air_quality_map, fetch_uv_map
from core.map.flood_trace_map import _fetch_flood_trace_html

# 로깅 설정
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(title="JSJ API", description="건강 지수 및 대피소 API")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 오리진 허용
    allow_credentials=True,
    allow_methods=["*"],  # 모든 메서드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

# 전역 스케줄러 인스턴스 생성
scheduler = BackgroundScheduler(daemon=True)


def _schedule_job(job_func, cron_config=None, run_immediately=True):
    """스케줄러 작업 등록 및 즉시 실행 헬퍼 함수

    Args:
        job_func: 실행할 작업 함수
        cron_config: 크론 스케줄 설정 (예: {'minute': '01'})
        run_immediately: 즉시 한 번 실행 여부
    """
    if cron_config:
        scheduler.add_job(job_func, "cron", **cron_config)

    if run_immediately:
        scheduler.add_job(job_func)


def update_flood_trace_job():
    logger.info("Scheduler: Running UV update job...")
    try:
        data = _fetch_flood_trace_html()
        update_flood_trace_cache(data)
    except Exception as e:
        logger.info(f"Scheduler Error: Failed to update flood trace: {e}")


def update_uv_job():
    """UV 지수 데이터 및 맵 업데이트 작업"""
    logger.info("Scheduler: Running UV update job...")
    try:
        data = asyncio.run(fetch_uv_index())
        update_uv_cache(data)

        # UV 맵 업데이트
        try:
            map_data = fetch_uv_map(data)
            update_uv_map_cache(map_data)
        except Exception as e:
            logger.error(f"Scheduler Error: Failed to update UV map: {e}")
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update UV: {e}")


def update_fine_dust_job():
    """미세먼지 데이터 및 맵 업데이트 작업"""
    logger.info("Scheduler: Running Fine Dust update job...")
    try:
        data = asyncio.run(fetch_fine_dust_data())
        update_fine_dust_cache(data)

        # 미세먼지 맵 업데이트
        try:
            map_data = fetch_air_quality_map(data)
            update_fine_dust_map_cache(map_data)
        except Exception as e:
            logger.error(f"Scheduler Error: Failed to update fine dust map: {e}")
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update Fine Dust: {e}")


def update_poison_index_job():
    """식중독 지수 업데이트 작업"""
    logger.info("Scheduler: Running food poisoning index update job...")
    try:
        data = fetch_food_poisoning_data()
        update_food_poisoning_cache(data)
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update food poisoning index: {e}")


# 앱 시작 이벤트에 스케줄러 시작 등록
@app.on_event("startup")
async def startup_event():
    # 스케줄러 설정 및 시작
    # 모든 작업을 매시간 1분에 실행하도록 설정
    cron_config = {"minute": "01"}

    # 작업 등록
    _schedule_job(update_fine_dust_job, cron_config, run_immediately=True)
    _schedule_job(update_uv_job, cron_config, run_immediately=True)
    _schedule_job(update_poison_index_job, cron_config, run_immediately=True)
    _schedule_job(update_flood_trace_job, run_immediately=True)

    # 스케줄러 시작
    try:
        if not scheduler.running:
            scheduler.start()
            logger.info("Scheduler started successfully.")
    except Exception as e:
        logger.error(f"Failed to start scheduler: {e}")


# 앱 종료 이벤트에 스케줄러 종료 등록
@app.on_event("shutdown")
async def shutdown_event():
    if scheduler.running:
        scheduler.shutdown()
        logger.info("Scheduler shutdown")


# 라우터 등록
from app.routers import index, map, env_map

app.include_router(index.router)
app.include_router(map.router)
app.include_router(env_map.router)


@app.get("/")
async def root():
    return {"message": "Welcome to the Backend API!"}


if __name__ == "__main__":
    # python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
