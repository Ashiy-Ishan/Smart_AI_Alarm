from flask import Flask, request, jsonify
from pymongo import MongoClient
import datetime

app = Flask(__name__)

MONGO_URL = "mongodb+srv://ashinshanaishanuni_db_user:ashiyishan@smartalarmdb.xb7hcvb.mongodb.net/?appName=SmartAlarmDB"
HOST = "0.0.0.0"
PORT = 2000

client = MongoClient(MONGO_URL)

db = client["SmartAlarmDB"]
collection = db["sensor_history"]

@app.route('/api/data', methods=['POST'])
def receive_data():
    try:
        print(f"\n--- Incoming request from {request.remote_addr} ---")
        data = request.get_json()
        print(f"Data received: {data}")

        if not data:
            print("Error: No data in request")
            return jsonify({"status": "error", "message": "No data received"}), 400

        data["timestamp"] = datetime.datetime.now().strftime(
            "%Y-%m-%d %H:%M:%S"
        )

        result = collection.insert_one(data)

        return jsonify({
            "status": "success",
            "id": str(result.inserted_id)
        }), 200

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host=HOST, port=PORT, debug=True)