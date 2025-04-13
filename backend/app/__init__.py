# app/__init__.py
from flask import Flask, jsonify
from pydantic import ValidationError
from apscheduler.schedulers.background import BackgroundScheduler  # 스케줄러 임포트
import atexit  # 앱 종료 시 스케줄러 종료용

from config import settings

# from utils.helpers import load_shelter_data  # 대피소 데이터 로딩

# 캐시 업데이트 함수 및 크롤러 함수 임포트 (경로 주의)
from app.cache import update_food_poisoning_cache
from core.indexing.crawler import _fetch_food_poisoning_sync  # 동기 크롤러 함수

# 전역 스케줄러 인스턴스 생성
scheduler = BackgroundScheduler(daemon=True)


def update_poison_index_job():
    """스케줄러가 실행할 작업 함수"""
    print("Scheduler: Running food poisoning index update job...")
    try:
        # 동기 크롤링 함수 직접 실행
        data = _fetch_food_poisoning_sync()
        # 캐시 업데이트 함수 호출
        update_food_poisoning_cache(data)
    except Exception as e:
        print(f"Scheduler Error: Failed to update food poisoning index: {e}")


def create_app():
    """Flask 애플리케이션 인스턴스를 생성하고 설정"""
    app = Flask(__name__)
    app.config.from_object(settings)

    # with app.app_context():
    #     load_shelter_data()

    # --- 스케줄러 설정 및 시작 ---
    # 예시: 매 4시간마다 실행 (cron 방식 또는 interval 방식 사용 가능)
    # scheduler.add_job(update_poison_index_job, 'interval', hours=4)
    scheduler.add_job(
        update_poison_index_job, "cron", hour="0,4,8,12,16,20"
    )  # 매 4시간 정각
    # 앱 시작 시 즉시 한 번 실행 (선택 사항)
    scheduler.add_job(update_poison_index_job)
    try:
        if not scheduler.running:
            scheduler.start()
            print("Scheduler started.")
            # 앱 종료 시 스케줄러가 안전하게 종료되도록 등록
            atexit.register(lambda: scheduler.shutdown())
    except Exception as e:
        print(f"Failed to start scheduler: {e}")
    # --------------------------

    # 블루프린트 등록
    from app.routes import main as main_routes

    app.register_blueprint(main_routes.bp)

    # 에러 핸들러 등록 (이전과 동일)
    @app.errorhandler(ValidationError)
    def handle_validation_error(error): ...
    @app.errorhandler(404)
    def page_not_found(error): ...
    @app.errorhandler(500)
    def internal_server_error(error): ...
    @app.errorhandler(400)
    def bad_request(error): ...

    @app.route("/")
    def index():
        return jsonify({"message": "Welcome to the Backend API!"})

    return app
