//
//  sysvpn_macosApp.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 29/08/2022.
//

import GoogleSignIn
import SwiftUI

@main
struct sysvpn_macosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var windowMgr = WindowMgr.shared
     
    @State var isFirstLaunch = false
    var body: some Scene {
        WindowGroup(id: "main") {
            Group {
                ZStack {
                    if WindowMgr.shared.currentWindow == .LoginView {
                        LoginView()
                            .environmentObject(GlobalAppStates.shared)
                            .environmentObject(WindowMgr.shared)
                    } else if WindowMgr.shared.currentWindow == .MainView {
                        HomeView().environmentObject(GlobalAppStates.shared)
                            .environmentObject(NetworkAppStates.shared)
                            .environmentObject(MapAppStates.shared)
                            .environmentObject(WindowMgr.shared)
                    }
                }
            }
            .withHostingWindow { window in
                if let window = window {
                    window.backgroundColor = Asset.Colors.mainBackgroundColor.color
                    window.isMovableByWindowBackground = false
                    window.standardWindowButton(.zoomButton)?.isHidden = false
                    if !isFirstLaunch {
                        if WindowMgr.shared.currentWindow == .MainView && PropertiesManager.shared.startMinimized {
                            window.performMiniaturize(self)
                        }
                        isFirstLaunch = true
                    }
                    WindowMgr.shared.nsWindow = window
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem, addition: {})
        }
        .handlesExternalEvents(matching: ["main"])
    }
}
