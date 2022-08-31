//
//  sysvpn_macosApp.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 29/08/2022.
//

import SwiftUI

@main
struct sysvpn_macosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
