//
//  GlobalAppState.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 02/10/2022.
//

import Foundation

class GlobalAppStates: ObservableObject {
    static let shared = GlobalAppStates()
    @Published var displayState: AppDisplayState = .disconnected
    @Published var recentList = [RecentModel]()
    @Published var listProfile = [UserProfileTemp]()
    var onReady: (() -> Void)?
    var isInitApp = false
    var isWaitingInitApp = false
    @Published var userIpAddress: String = ""
    
    var sessionStartTime: Double? {
        return DependencyContainer.shared.appStateMgr.sessionStartTime
    }
    
    func initApp(_ ready: (() -> Void)?) -> Bool {
        if isInitApp {
            ready?()
            return false
        }
        onReady = ready
        isWaitingInitApp = true
        isInitApp = true
        if DependencyContainer.shared.appStateMgr.sessionStartTime != nil {
            print("hasConnected")
        }
        
        OSExtensionManager.shared.onReady = {
            let ipc = IPCFactory.makeIPCRequestService()
            ipc.checkConnect {
                DispatchQueue.main.async {
                    self.initData()
                    NotificationCenter.default.post(name: .appReadyStart, object: nil)
                    DependencyContainer.shared.vpnManager.whenReady(queue: DispatchQueue.main) {
                        self.onVPNReady()
                    }
                    DependencyContainer.shared.vpnManager.prepareManagers(forSetup: true)
                }
            }
        }
        return true
    }
    
    func onVPNReady() {
        NetworkChecker.shared.checkInternet()
        if !AppDataManager.shared.isLogin {
            return
        }
        if PropertiesManager.shared.getAutoConnect(for: AppDataManager.shared.userData?.email ?? "default").enabled {
            DependencyContainer.shared.vpnCore.autoConnect()
        }
    }

    func initData() {
        if AppDataManager.shared.userSetting == nil {
            _ = AppDataManager.shared.loadSetupData {
                self.onNext()
            }
        } else {
            _ = AppDataManager.shared.loadSetupData {
                print("[MGR] refresh done")
            }
            onNext()
        }
    }
    
    func onStartApp() {
        if AppDataManager.shared.isLogin {
            NotificationCenter.default.post(name: .startJobUpdateCountry, object: nil)
        } else {
            NotificationCenter.default.post(name: .endJobUpdate, object: nil)
        }
    }
    
    func onNext() {
        isWaitingInitApp = false
        onReady?()
        onStartApp()
    }
}

class NetworkAppStates: ObservableObject {
    static let shared = NetworkAppStates()
    @Published var bitRate: Bitrate = .init(download: 0, upload: 0)
}

class MapAppStates: ObservableObject {
    static let shared = MapAppStates()
    @Published var connectedNode: INodeInfo? = nil
    @Published var selectedNode: INodeInfo? = nil
    @Published var hoverNode: NodePoint? = nil
    @Published var serverInfo: VPNServer? = nil
}
