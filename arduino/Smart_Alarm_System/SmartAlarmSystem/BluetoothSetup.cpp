#include "BluetoothSetup.h"
#include "Config.h"
#include "Globals.h"
#include "DeviceMemory.h"
#include "DisplayUI.h"

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
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
      String rxValue = pCharacteristic->getValue(); 
      
      if (rxValue.length() > 0) {
        // App sends format: "ssid,password,uid"
        int firstComma = rxValue.indexOf(',');
        int secondComma = rxValue.indexOf(',', firstComma + 1);
        
        if (firstComma > 0 && secondComma > firstComma) {
          String s = rxValue.substring(0, firstComma);
          String p = rxValue.substring(firstComma + 1, secondComma);
          String u = rxValue.substring(secondComma + 1);
          
          s.trim();
          p.trim();
          u.trim();

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
                        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                      );
  
  WiFi.mode(WIFI_STA);
  pTxCharacteristic->setValue(WiFi.macAddress().c_str());
                      
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