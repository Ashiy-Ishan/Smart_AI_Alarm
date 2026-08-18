from pymongo import MongoClient

client = MongoClient("mongodb+srv://ashinshanaishanuni_db_user:ashiyishan@smartalarmdb.xb7hcvb.mongodb.net/?appName=SmartAlarmDB")
db = client["SmartAlarmDB"]
collection = db["sensor_history"]

for document in collection.find():
    print(document)