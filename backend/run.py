#!/usr/bin/env python
# coding: utf-8
"""
애플리케이션 시작 스크립트
Flask 애플리케이션을 초기화하고 개발 서버를 실행합니다.
"""
import os
import logging
from app import create_app
from waitress import serve

# 로깅 설정
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """애플리케이션 메인 함수"""
    # app/__init__.py에 정의된 create_app 함수를 호출하여 Flask 앱 인스턴스 생성
    app = create_app()

    # 환경 변수에서 포트 설정을 가져오거나 기본값 사용
    port = int(os.environ.get("PORT", 5000))

    # 개발 모드 설정
    debug = os.environ.get("FLASK_ENV", "development") == "development"

    # 애플리케이션 실행 정보 출력
    logger.info(f"Starting application on port {port} (debug={debug})")

    # Flask 개발 서버 실행
    serve(app, host="0.0.0.0", port=port, threads=4)


if __name__ == "__main__":
    main()
