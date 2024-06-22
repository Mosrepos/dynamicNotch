//
//  ChargingAnimationController.swift
//  DynamicNotch
//
//  Created by Mohamad Abdo on 21.06.24.
//

import Foundation
import AppKit
import IOKit.ps
import DynamicNotchKit

class ChargingAnimationController: NSObject {
    private var previousIsCharging: Bool? = nil
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.startListeningForBatteryChanges()
        }
    }
    
    private func showChargingNotch(level: Int, status: String) {
        let notchInfo = DynamicNotchInfo(
            systemImage: "battery.100",
            title: "Battery Status",
            description: "\(level)% - \(status)"
        )
        notchInfo.show(for: 2)
    }
    
    private func startListeningForBatteryChanges() {
        let runLoopSource = IOPSNotificationCreateRunLoopSource({ (context) in
            let unmanagedContext = Unmanaged<ChargingAnimationController>.fromOpaque(context!)
            unmanagedContext.takeUnretainedValue().handleBatteryStatusChange()
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())).takeRetainedValue()
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }
    
    private func handleBatteryStatusChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateBatteryStatus()
        }
    }
    
    private func updateBatteryStatus() {
        let batteryStatus = fetchBatteryStatus()
        
        if batteryStatus.isCharging != previousIsCharging {
            previousIsCharging = batteryStatus.isCharging
            showChargingNotch(level: batteryStatus.level, status: batteryStatus.isCharging ? "Charging" : "Not Charging")
        }
    }
    
    private func fetchBatteryStatus() -> (level: Int, isCharging: Bool) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        for ps in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: Any] {
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 0
                let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
                let batteryLevel = (currentCapacity * 100) / maxCapacity
                return (level: batteryLevel, isCharging: isCharging)
            }
        }
        return (level: 0, isCharging: false)
    }
}
