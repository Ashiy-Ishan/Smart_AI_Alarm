#include "BluetoothSetup.h"
#include "Config.h"
#include "Globals.h"
#include "DeviceMemory.h"
#include "DisplayUI.h"

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <ArduinoJson.h>
#include <WiFi.h>

BLEServer *pServer = NULL;
BLECharacteristic *pTxCharacteristic;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; }
    void onDisconnect(BLEServer* pServer) { deviceConnected = false; }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      // FIX: Changed std::string to Arduino String for ESP32 Core V3.x
      String rxValue = pCharacteristic->getValue(); 
      
      if (rxValue.length() > 0) {
        JsonDocument doc; 
        DeserializationError error = deserializeJson(doc, rxValue);
        
        if (!error) {
          String s = doc["ssid"].as<String>();
          String p = doc["pass"].as<String>();
          String u = doc["user"].as<String>();
          
          saveConfigAsJSON(s, p, u);
          
          drawBootScreen("Setup Complete!");
          delay(2000);
          ESP.restart(); 
        }
      }
    }
};

void startBluetooth() {
  BLEDevice::init("Smart_AI_Alarm");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(BLE_SERVICE_UUID);

  pTxCharacteristic = pService->createCharacteristic(
                        BLE_CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
                      
  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
                                           BLE_CHARACTERISTIC_UUID_RX,
                                           BLECharacteristic::PROPERTY_WRITE
                                         );
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();
  pServer->getAdvertising()->start();
  isBleSetupMode = true;
}

void handleBluetooth() {
  if (deviceConnected) {
    String macAddress = WiFi.macAddress();
    pTxCharacteristic->setValue(macAddress.c_str());
    pTxCharacteristic->notify();
    delay(1000); 
  }
}