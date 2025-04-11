from flask import Flask, request, jsonify

app = Flask(__name__)


@app.route("/location", methods=["POST"])
def receive_location():
    data = request.get_json()
    latitude = data.get("latitude")
    longitude = data.get("longitude")

    if latitude is None or longitude is None:
        return jsonify({"message": "위치 정보 누락"}), 400

    # 서버 콘솔에 위치정보 출력 (실제 상황에서는 데이터베이스 저장 등 추가 처리)
    print(f"받은 위치: 위도 {latitude}, 경도 {longitude}")

    return jsonify({"message": "위치 정보 수신 성공"}), 200


if __name__ == "__main__":
    # 로컬 네트워크의 모든 IP에서 접근 가능하도록 host 지정
    app.run(host="0.0.0.0", port=5000)
