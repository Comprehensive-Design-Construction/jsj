# run.py
import os
from app import create_app

# app/__init__.py 에 정의된 create_app 함수를 호출하여 Flask 앱 인스턴스 생성
app = create_app()

if __name__ == "__main__":
    # Flask 개발 서버 실행
    # debug=True: 코드 변경 시 자동 재시작, 자세한 오류 로그 출력 (개발 중에만 사용)
    # host='0.0.0.0': 로컬 네트워크의 다른 기기에서도 접속 허용 (기본값은 '127.0.0.1')
    # port=5000: 사용할 포트 번호 (기본값)
    app.run(debug=True, host="0.0.0.0", port=5000)

    # 참고: 운영 환경에서는 Gunicorn, uWSGI 같은 WSGI 서버를 사용하여 앱을 실행해야 합니다.
    # 예: gunicorn -w 4 -b 0.0.0.0:5000 run:app
