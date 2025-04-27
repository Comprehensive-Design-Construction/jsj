@echo off
echo FastAPI 서버 시작 중...
cd %~dp0
python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload 