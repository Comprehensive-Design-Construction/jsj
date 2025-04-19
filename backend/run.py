#!/usr/bin/env python
# coding: utf-8
"""
애플리케이션 시작 스크립트
Flask 애플리케이션을 초기화하고 개발 서버를 실행합니다.
"""
import os
import logging
from app import create_app

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
    app.run(
        debug=debug,  # 디버그 모드: 코드 변경 시 자동 재시작, 자세한 오류 로그 (개발 중에만 사용)
        host="0.0.0.0",  # 모든 네트워크 인터페이스에서 접속 허용
        port=port,  # 사용할 포트 번호
    )

    # 참고: 운영 환경에서는 Gunicorn, uWSGI 같은 WSGI 서버를 사용하는 것이 권장됩니다.
    # 예: gunicorn -w 4 -b 0.0.0.0:5000 run:app


if __name__ == "__main__":
    main()
