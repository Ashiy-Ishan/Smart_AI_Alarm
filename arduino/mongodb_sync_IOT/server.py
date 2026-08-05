from flask import Flask, request, jsonify
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import datetime

app = Flask(__name__)
load_dotenv()
#need to create env file and add MONGO_URL, HOST
MONGO_URL = os.getenv("MONGO_URL")
HOST=os.getenv("HOST","0.0.0.0")
PORT=int(os.getenv("PORT","5000"))

client = MongoClient(MONGO_URL)

db = client["SmartAlarmDB"]
collection = db["sensor_history"]

@app.route('/api/data', methods=['POST'])
def receive_data():
    try:
        data = request.get_json()

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
