//
//  WindowMgr.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 28/09/2022.
//

import Foundation
import SwiftUI

enum OpenWindows: String, CaseIterable {
    case LoginView
    case MainView
    case SpashView
    
    func open() {
        /* if let url = URL(string: "sysvpn://\(rawValue)") {
             NSWorkspace.shared.open(url)
         }*/
        WindowMgr.shared.currentWindow = self
    }
}

class WindowMgr: ObservableObject {
    private static var _instance: WindowMgr = .init()
    
    weak var nsWindow: NSWindow?
    
    static var shared: WindowMgr {
        return _instance
    }

    init() {
        if AppDataManager.shared.isLogin {
            currentWindow = .MainView
        } else {
            currentWindow = .LoginView
        }
    }
    
    @Published var currentWindow: OpenWindows = .LoginView
}
