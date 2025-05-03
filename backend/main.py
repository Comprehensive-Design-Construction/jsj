from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import asyncio

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

from core.shelter.shelter_loader import load_shelter_by_type
import core.shelter.config as shelter_config

# 로깅 설정
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(title="JSJ API", description="API for contest")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 전역 스케줄러 인스턴스 생성
scheduler = BackgroundScheduler(daemon=True)


def _schedule_job(job_func, cron_config=None, run_immediately=True):
    """스케줄러 작업 등록 및 즉시 실행 헬퍼 함수"""
    if cron_config:
        scheduler.add_job(job_func, "cron", **cron_config)
    if run_immediately:
        # 즉시 실행은 add_job의 기본 동작이므로 별도 호출 대신,
        # 스케줄러 시작 후 바로 실행되도록 하거나, 필요시 앱 시작 시 직접 호출 고려
        # 여기서는 run_immediately=True 시 스케줄러 시작 시 바로 실행되는 것으로 가정
        # 또는 별도 함수로 빼서 startup에서 직접 호출
        pass  # 아래 startup에서 직접 호출 방식으로 변경


async def _run_job_now(job_func):
    """주어진 작업을 즉시 비동기적으로 실행"""
    logger.info(f"Running job immediately: {job_func.__name__}")
    try:
        # 비동기 함수인지 동기 함수인지 확인 후 실행
        if asyncio.iscoroutinefunction(job_func):
            await job_func()
        else:
            # 동기 함수는 asyncio.to_thread 사용 권장 (uvicorn 환경 등에서)
            # 혹은 직접 실행 (BackgroundScheduler가 별도 스레드에서 실행하므로 괜찮을 수 있음)
            job_func()
    except Exception as e:
        logger.error(
            f"Error running job {job_func.__name__} immediately: {e}", exc_info=True
        )


# 주기적 업데이트 작업 함수들 (기존과 동일)
def update_flood_trace_job_sync():  # BackgroundScheduler는 동기 함수를 직접 실행
    logger.info("Scheduler: Running Flood Trace update job...")
    try:
        data = _fetch_flood_trace_html()
        update_flood_trace_cache(data)
    except Exception as e:
        logger.error(
            f"Scheduler Error: Failed to update flood trace: {e}", exc_info=True
        )


async def update_uv_job_async():  # 비동기 함수
    logger.info("Scheduler: Running UV update job...")
    try:
        data = await fetch_uv_index()
        update_uv_cache(data)
        try:
            map_data = fetch_uv_map(data)  # 동기 함수로 가정
            update_uv_map_cache(map_data)
        except Exception as e:
            logger.error(
                f"Scheduler Error: Failed to update UV map: {e}", exc_info=True
            )
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update UV: {e}", exc_info=True)


async def update_fine_dust_job_async():  # 비동기 함수
    logger.info("Scheduler: Running Fine Dust update job...")
    try:
        data = await fetch_fine_dust_data()
        update_fine_dust_cache(data)
        try:
            map_data = fetch_air_quality_map(data)  # 동기 함수로 가정
            update_fine_dust_map_cache(map_data)
        except Exception as e:
            logger.error(
                f"Scheduler Error: Failed to update fine dust map: {e}", exc_info=True
            )
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update Fine Dust: {e}", exc_info=True)


def update_poison_index_job_sync():  # 동기 함수
    logger.info("Scheduler: Running food poisoning index update job...")
    try:
        data = fetch_food_poisoning_data()
        update_food_poisoning_cache(data)
    except Exception as e:
        logger.error(
            f"Scheduler Error: Failed to update food poisoning index: {e}",
            exc_info=True,
        )


# 앱 시작 이벤트
@app.on_event("startup")
async def startup_event():
    logger.info("Application startup event initiated.")

    # --- 변경: 대피소 데이터 선제적 로딩 ---
    logger.info("Pre-loading shelter data...")
    shelter_types_to_load = (
        shelter_config.ALL_DISASTER_TYPES
    )  # 설정 파일의 모든 재난 유형
    successful_loads = 0
    for disaster_type in shelter_types_to_load:
        try:
            # 수정된 로더 함수 호출 (캐시 메커니즘 내장)
            # 여기서 로드된 객체를 사용할 필요는 없지만, 호출 자체로 캐시에 저장됨
            load_shelter_by_type(disaster_type)
            logger.info(f"Successfully pre-loaded shelter data for '{disaster_type}'.")
            successful_loads += 1
        except Exception as e:
            # 특정 유형 로딩 실패 시 오류 로깅 후 계속 진행
            logger.error(
                f"Failed to pre-load shelter data for '{disaster_type}': {e}",
                exc_info=True,
            )
    logger.info(
        f"Shelter data pre-loading complete. Successfully loaded {successful_loads}/{len(shelter_types_to_load)} types."
    )
    # -----------------------------------

    # 스케줄러 설정 및 시작
    cron_config = {"hour": "*", "minute": "1"}  # 매시간 1분마다 실행

    # 주기적 작업 등록
    scheduler.add_job(
        update_fine_dust_job_async, "cron", **cron_config, id="update_fine_dust_job"
    )
    scheduler.add_job(update_uv_job_async, "cron", **cron_config, id="update_uv_job")
    scheduler.add_job(
        update_poison_index_job_sync,
        "cron",
        **cron_config,
        id="update_poison_index_job",
    )
    # 홍수 추적은 매시간 실행할 필요가 있는지 확인 필요 (예: 매일 특정 시간)
    # scheduler.add_job(update_flood_trace_job_sync, "cron", hour='3', minute='5', id="update_flood_trace_job") # 예: 매일 새벽 3시 5분

    # 앱 시작 시 즉시 실행할 작업들 (await 사용)
    await _run_job_now(update_fine_dust_job_async)
    await _run_job_now(update_uv_job_async)
    await _run_job_now(update_poison_index_job_sync)
    await _run_job_now(update_flood_trace_job_sync)  # 동기지만 await 가능하게 처리됨

    # 스케줄러 시작
    try:
        if not scheduler.running:
            scheduler.start()
            logger.info("Scheduler started successfully.")
    except Exception as e:
        logger.error(f"Failed to start scheduler: {e}", exc_info=True)

    logger.info("Application startup complete.")


# 앱 종료 이벤트
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Application shutdown event initiated.")
    if scheduler.running:
        scheduler.shutdown()
        logger.info("Scheduler shutdown gracefully.")


# 라우터 등록
from app.routers import index, map, env_map, weather, environment, coord

app.include_router(index.router)
app.include_router(map.router)
app.include_router(env_map.router)
app.include_router(weather.router)
app.include_router(environment.router)
app.include_router(coord.router)


@app.get("/")
async def root():
    return {"message": "Welcome to the Backend API!"}


if __name__ == "__main__":
    # 로컬 개발 환경 실행
    # reload=True는 개발 중에 유용하지만, 프로덕션에서는 False로 설정하거나 Gunicorn 등 사용
    # workers=12는 로컬 테스트에는 과할 수 있음. CPU 코어 수 고려하여 조절.
    uvicorn.run(
        "main:app", host="0.0.0.0", port=5000, reload=True
    )  # 개발 시 workers=1, reload=True 권장
