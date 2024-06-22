//
//  AirPodsAnimationController.swift
//  DynamicNotch
//
//  Created by Mohamad Abdo on 21.06.24.
//

import Foundation
import CoreBluetooth
import DynamicNotchKit
import IOBluetooth

class AirPodsAnimationController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var connectedAirPods: CBPeripheral?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let deviceName = peripheral.name, deviceName.contains("AirPods") {
            if connectedAirPods == nil {
                connectedAirPods = peripheral
                connectedAirPods?.delegate = self
                centralManager.stopScan()
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "2A19") { // Battery Level Characteristic
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "2A19"), let batteryLevel = characteristic.value?.first {
            handleAirPodsConnection(model: peripheral.name ?? "AirPods", batteryLevels: ["Left": Int(batteryLevel), "Right": Int(batteryLevel), "Case": Int(batteryLevel)])
        }
    }
    
    private func handleAirPodsConnection(model: String, batteryLevels: [String: Int?]) {
        DispatchQueue.main.async {
            self.showAirPodsNotch(model: model, batteryLevels: batteryLevels)
        }
    }
    
    private func showAirPodsNotch(model: String, batteryLevels: [String: Int?]) {
        let systemImage: String
        switch model {
        case "AirPods Pro":
            systemImage = "airpodspro"
        case "AirPods Max":
            systemImage = "airpodsmax"
        default:
            systemImage = "airpods"
        }
        
        var description = ""
        if let left = batteryLevels["Left"], let right = batteryLevels["Right"], let airPodsCase = batteryLevels["Case"] {
            description = "Left: \(left ?? -1)%, Right: \(right ?? -1)%, Case: \(airPodsCase ?? -1)%"
        } else {
            description = "Battery Level: Error fetching battery level"
        }
        
        let notchInfo = DynamicNotchInfo(
            systemImage: systemImage,
            title: model,
            description: description
        )
        notchInfo.show(for: 2)
    }
}
