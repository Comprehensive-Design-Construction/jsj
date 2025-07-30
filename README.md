# JSJ 프로젝트 개요

이 저장소는 재난 및 환경 정보를 제공하는 **FastAPI 기반 백엔드**와 이를 소비하는 **Flutter 모바일 앱**으로 구성되어 있습니다. 백엔드는 날씨·건강 지수 계산, 미세먼지·자외선 지수 조회, 대피소 지도 생성 등을 담당하며, 프론트엔드는 이러한 데이터를 이용해 사용자에게 직관적인 UI를 제공합니다.

## 폴더 구조

```
# We
backend/    FastAPI 서버 구현
front/      Flutter 애플리케이션
```

## 백엔드

- `main.py`에서 FastAPI 앱과 APScheduler를 초기화하여 주기적으로 데이터를 갱신합니다.【F:backend/main.py†L1-L40】【F:backend/main.py†L100-L160】
- 외부 API 키와 경로 등 주요 설정은 `config/settings.py`에서 관리하며 `.env` 파일을 통해 주입합니다.【F:backend/config/settings.py†L10-L41】
- `/api/index`, `/api/environment/*`, `/api/map` 등의 엔드포인트를 제공하여 날씨, 건강 지수, 환경 지도, 대피소 지도 데이터를 반환합니다.

백엔드 실행 예시:
```bash
cd backend
uvicorn main:app --reload
```

## 프론트엔드

- Flutter로 작성되었으며 `front/lib` 이하에 앱 코드가 위치합니다.
- API 기본 URL과 주요 엔드포인트는 `app_constants.dart`에 정의되어 있습니다.【F:front/lib/core/constants/app_constants.dart†L3-L23】
- `main.dart`에서 사용자 온보딩 여부를 확인한 뒤 `MyApp`을 실행합니다.【F:front/lib/main.dart†L1-L14】

프론트 실행 예시:
```bash
cd front
flutter run
```

## 의존성 설치

```bash
pip install -r requirements.txt
flutter pub get   # front 디렉터리에서 실행
```

## 테스트 스크립트

`backend/test_api.py`를 이용해 각 API의 동작을 확인할 수 있습니다.
