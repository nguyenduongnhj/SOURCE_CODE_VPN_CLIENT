//
//  SysVPNCore.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 01/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation

class SysVPNCore: SysVPNGatewayProtocol {
    var connection: ConnectionStatus = .disconnected
    var currentConnectingRequest: SysVPNConnectionRequest?
    static let connectionChanged = Notification.Name("VpnGatewayConnectionChanged")
    static let activeServerTypeChanged = Notification.Name("VpnGatewayActiveServerTypeChanged")
    static let needsReconnectNotification = Notification.Name("VpnManagerNeedsReconnect")
    
    var lastConnectionConiguration: ConnectionConfiguration? {
        set {
            newValue.saveUserDefault(keyUserDefault: "lastConnectionConiguration")
        }
        get {
            return ConnectionConfiguration.readUserDefault(keyUserDefault: "lastConnectionConiguration")
        }
    }
    
    var vpnService: SysVPNService
    var appStateManager: AppStateManagement
    init(vpnService: SysVPNService, appStateManager: AppStateManagement) {
        self.vpnService = vpnService
        self.appStateManager = appStateManager
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appStateChanged),
                                               name: AppStateManagerNotification.stateChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnectOnNotification),
                                               name: Self.needsReconnectNotification,
                                               object: nil)
    }
    
    func autoConnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self._checkAutoConnect()
        }
    }
    
    func _checkAutoConnect() {
        if connection == .disconnected {
            appStateManager.isOnDemandEnabled { [weak self] enabled in
                
                if enabled {
                    NetworkChecker.shared.isStart = true
                }
                guard let self = self, !enabled else {
                    return
                }
                if let lastConfig = self.lastConnectionConiguration, let id = lastConfig.serverInfo.id {
                    self.connectTo(connectType: .serverId(id: id), params: self.lastConnectionConiguration?.connectionParam)
                } else {
                    self.quickConnect()
                }
            }
        } else if connection == .connecting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.connection == .connecting {
                    NetworkChecker.shared.isStart = true
                }
            }
        }
    }
    
    func quickConnect() {
        connect(with: quickConnectConnectionRequest())
    }
    
    func quickConnectConnectionRequest() -> SysVPNConnectionRequest {
        return SysVPNConnectionRequest(connectType: .quick, params: SysVPNConnectParams(isHop: false))
    }
    
    func connectTo(connectType: ConnectionType, params: SysVPNConnectParams?, isRetry: Bool = false) {
        let request = SysVPNConnectionRequest(connectType: connectType, params: params, retry: isRetry)
        connect(with: request)
    }
    
    func retryConnection(_: Int) {
        if let lastConnectionConiguration = lastConnectionConiguration, let lastSessionCode = lastConnectionConiguration.connectionDetermine.disconnectParam?.sessionId, let id = lastConnectionConiguration.serverInfo.id {
            /* connectTo(connectType: .lastSessionCode(code: lastSessionCode, id: id), params: lastConnectionConiguration?.connectionParam, isRetry: true) */
            connect(with: .init(connectType: .lastSessionCode(code: lastSessionCode, id: id, deepId: lastConnectionConiguration.deepId), params: lastConnectionConiguration.connectionParam, retry: true))
        } else {
            quickConnect()
        }
    }
    
    func connect(with request: SysVPNConnectionRequest) {
        print("[VPN-Core] start connect vpn")
        
        if !request.retry {
            DispatchQueue.main.async {
                self.appStateManager.prepareToConnect()
            }
            PropertiesManager.shared.intentionallyDisconnected = false
        } else {
            PropertiesManager.shared.intentionallyDisconnected = true
        }
        
        currentConnectingRequest = request
        vpnService.prepareConection(connectType: request.connectType, params: request.params, callback: { response in
            
            /* if case AppState.disconnected = self.appStateManager.state {
                 return
             }*/
            switch response {
            case let .failure(e):
                print("[VPN-Core] request determine vpn config failed \(e) ")
                if !request.retry {
                    DispatchQueue.main.async { [weak self] in
                        // To-do: push error
                        self?.stopConnecting(userInitiated: false)
                    }
                    AppAlertManager.shared.showAlert(title: "Connection failed", message: e.localizedDescription)
                }
            case let .success(result):
                var deepId: String? = request.nodeInfo?.deepId
                
                if case let .lastSessionCode(_, _, id) = request.connectType {
                    deepId = id
                }
                let connectionConfig = ConnectionConfiguration(connectionDetermine: result, connectionParam: request.params, vpnProtocol: result.vpnProtocol, serverInfo: result.serverInfo, isRetry: request.retry, deepId: deepId)
                
                self.lastConnectionConiguration = connectionConfig
                if result.vpnProtocol == .wireGuard {
                    PropertiesManager.shared.lastWireguardConnection = connectionConfig
                } else {
                    PropertiesManager.shared.lastOpenVpnConnection = connectionConfig
                }
                print("[VPN-Core] request determine vpn config success")
                IPCFactory.makeIPCRequestService().setProtocol(result.vpnProtocol.name)
                DispatchQueue.main.async { [weak self] in
                    self?.appStateManager.checkNetworkConditionsAndCredentialsAndConnect(withConfiguration: connectionConfig)
                }
            }
             
        })
    }
    
    func stopConnecting(userInitiated: Bool) {
        appStateManager.cancelConnectionAttempt()
    }
    
    public func disconnect() {
        PropertiesManager.shared.intentionallyDisconnected = false
        disconnect {
            DispatchQueue.main.async {
                if self.connection != .disconnected {
                    self.appStateManager.refreshState()
                }
            }
        }
    }
    
    func disconnect(completion: @escaping () -> Void) {
        let completionWrapper: () -> Void = { [weak self] in
            completion()
            
            guard let self = self else {
                return
            }
            self.vpnService.disconnectLastSession(disconnectParam: self.lastConnectionConiguration?.connectionDetermine.disconnectParam) { response in
                switch response {
                case .success:
                    print("disconnect call success")
                case let .failure(error):
                    print("disconnect call failes \(error)")
                }
            }
        }
        
        appStateManager.disconnect(completion: completionWrapper)
    }
    
    func postConnectionInformation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            NotificationCenter.default.post(name: SysVPNCore.connectionChanged,
                                            object: self.connection,
                                            userInfo: [AppState.appStateKey: self.appStateManager.state])
        }
    }
    
    @objc private func appStateChanged(_ notification: Notification) {
        guard let state = notification.object as? AppState else {
            return
        }
        connection = ConnectionStatus.forAppState(state)
        postConnectionInformation()
    }
    
    @objc private func reconnectOnNotification(_: Notification) {}
    
    func connectTo(node info: INodeInfo, isRetry: Bool) -> Bool {
        let dj = DependencyContainer.shared
        if let city = info as? CountryCity {
            dj.vpnCore.connect(with: .init(connectType: .cityId(id: city.id ?? 0), nodeInfo: info))
            return true
        } else if let country = info as? CountryAvailables {
            dj.vpnCore.connect(with: .init(connectType: .countryId(id: country.id ?? 0), nodeInfo: info))
            return true
        } else if let staticServer = info as? CountryStaticServers {
            dj.vpnCore.connect(with: .init(connectType: .serverId(id: staticServer.serverId ?? 0), nodeInfo: info))
            return true
        } else if let multiplehop = info as? MultiHopResult {
            dj.vpnCore.connect(with: .init(connectType: .serverId(id: multiplehop.entry?.serverId ?? 0), params: SysVPNConnectParams(isHop: true), nodeInfo: info))
            multiplehop.entry?.city?.country = multiplehop.entry?.country
            multiplehop.exit?.city?.country = multiplehop.exit?.country
            MapAppStates.shared.connectedNode = multiplehop
            return true
        }
        
        return false
    }
}
