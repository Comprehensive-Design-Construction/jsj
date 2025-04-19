# app/__init__.py
from flask import Flask, jsonify
from pydantic import ValidationError
from apscheduler.schedulers.background import BackgroundScheduler
import atexit
import logging
import asyncio

from config import settings

# from utils.helpers import load_shelter_data  # 대피소 데이터 로딩

# 캐시 업데이트 함수 임포트
from app.cache import (
    update_food_poisoning_cache,
    update_fine_dust_cache,
    update_uv_cache,
    update_fine_dust_map_cache,
    update_uv_map_cache,
)

# 데이터 수집 함수 임포트
from core.indexing.get_poison import _fetch_food_poisoning_sync
from core.indexing.get_fine_dust import _fetch_fine_dust_sync
from core.indexing.get_uv import _fetch_uv_sync
from core.map.create_map import fetch_air_quality_map, fetch_uv_map

# 로깅 설정
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

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


def update_uv_job():
    """UV 지수 데이터 및 맵 업데이트 작업"""
    logger.info("Scheduler: Running UV update job...")
    try:
        data = asyncio.run(_fetch_uv_sync())
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
        data = asyncio.run(_fetch_fine_dust_sync())
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
        data = _fetch_food_poisoning_sync()
        update_food_poisoning_cache(data)
    except Exception as e:
        logger.error(f"Scheduler Error: Failed to update food poisoning index: {e}")


def create_app():
    """Flask 애플리케이션 인스턴스를 생성하고 설정"""
    app = Flask(__name__)
    app.config.from_object(settings)

    # --- 스케줄러 설정 및 시작 ---
    # 모든 작업을 매시간 1분에 실행하도록 설정
    cron_config = {"minute": "01"}

    # 작업 등록
    _schedule_job(update_fine_dust_job, cron_config, run_immediately=True)
    _schedule_job(update_uv_job, cron_config, run_immediately=True)
    _schedule_job(update_poison_index_job, cron_config, run_immediately=True)

    # 스케줄러 시작
    try:
        if not scheduler.running:
            scheduler.start()
            logger.info("Scheduler started successfully.")
            # 앱 종료 시 스케줄러가 안전하게 종료되도록 등록
            atexit.register(lambda: scheduler.shutdown())
    except Exception as e:
        logger.error(f"Failed to start scheduler: {e}")
    # --------------------------

    # 블루프린트 등록
    from app.routes import index as index_routes
    from app.routes import map as map_routes
    from app.routes import env_map as env_map_routes

    app.register_blueprint(index_routes.bp)
    app.register_blueprint(map_routes.bp)
    app.register_blueprint(env_map_routes.bp)

    # 에러 핸들러 등록
    @app.errorhandler(ValidationError)
    def handle_validation_error(error):
        return jsonify({"error": "Validation Error", "details": error.errors()}), 400

    @app.errorhandler(404)
    def page_not_found(error):
        return jsonify({"error": "Page not found"}), 404

    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"error": "Internal server error"}), 500

    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"error": "Bad request"}), 400

    @app.route("/")
    def index():
        return jsonify({"message": "Welcome to the Backend API!"})

    return app
