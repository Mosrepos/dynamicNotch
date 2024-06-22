//
//  DynamicNotchApp.swift
//  DynamicNotch
//
//  Created by Mohamad Abdo on 16.06.24.
//

import SwiftUI
import DynamicNotchKit

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController!
    var chargingAnimationController: ChargingAnimationController!
    var airPodsAnimationController: AirPodsAnimationController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        chargingAnimationController = ChargingAnimationController()
        airPodsAnimationController = AirPodsAnimationController()
    }
}
