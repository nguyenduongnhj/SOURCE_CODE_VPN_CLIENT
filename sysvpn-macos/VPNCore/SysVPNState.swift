//
//  SysVPNState.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 01/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation


public struct AppStateManagerNotification {
    public static var stateChange: Notification.Name = Notification.Name("AppStateManagerStateChange")
    public static var displayStateChange: Notification.Name = Notification.Name("AppStateManagerDisplayStateChange")
}

public struct ServerDescriptor {
    
    public let username: String
    public let address: String
    
    public init(username: String, address: String) {
        self.username = username
        self.address = address
    }
    
    public var description: String {
        return "Server address: \(address)"
    }
}

extension ServerDescriptor: Equatable {
    
    public static func == (lhs: ServerDescriptor, rhs: ServerDescriptor) -> Bool {
        return lhs.username == rhs.username && lhs.address == rhs.address
    }
}

public enum VpnState {
    case invalid
    case disconnected
    case connecting(ServerDescriptor)
    case connected(ServerDescriptor)
    case reasserting(ServerDescriptor)
    case disconnecting(ServerDescriptor)
    case error(Error)
    
    public var description: String {
        let base = "VPN state - "
        switch self {
        case .invalid:
            return base + "Invalid"
        case .disconnected:
            return base + "Disconnected"
        case .connecting(let descriptor):
            return base + "Connecting to: \(descriptor)"
        case .connected(let descriptor):
            return base + "Connected to: \(descriptor)"
        case .reasserting(let descriptor):
            return base + "Reasserting connection to: \(descriptor)"
        case .disconnecting(let descriptor):
            return base + "Disconnecting from: \(descriptor)"
        case .error(let error):
            return base + "Error: \(error.localizedDescription)"
        }
    }
    
    public var logDescription: String {
        let base = "VPN state - "
        switch self {
        case .invalid:
            return base + "Invalid"
        case .disconnected:
            return base + "Disconnected"
        case .connecting(let descriptor):
            return base + "Connecting to: \(descriptor.address)"
        case .connected(let descriptor):
            return base + "Connected to: \(descriptor.address)"
        case .reasserting(let descriptor):
            return base + "Reasserting connection to: \(descriptor.address)"
        case .disconnecting(let descriptor):
            return base + "Disconnecting from: \(descriptor.address)"
        case .error(let error):
            return base + "Error: \(error.localizedDescription)"
        }
    }
     
    public var stableConnection: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
     
    public var volatileConnection: Bool {
        switch self {
        case .connecting, .reasserting, .disconnecting:
            return true
        default:
            return false
        }
    }
}

extension VpnState: Equatable {
    
    public static func == (lhs: VpnState, rhs: VpnState) -> Bool {
        switch (lhs, rhs) {
        case (.invalid, .invalid):
            return true
        case (.disconnected, .disconnected):
            return true
        case (.connecting(let descriptorLhs), .connecting(let descriptorRhs)):
            return descriptorLhs == descriptorRhs
        case (.connected(let descriptorLhs), .connected(let descriptorRhs)):
            return descriptorLhs == descriptorRhs
        case (.reasserting(let descriptorLhs), .reasserting(let descriptorRhs)):
            return descriptorLhs == descriptorRhs
        case (.disconnecting(let descriptorLhs), .disconnecting(let descriptorRhs)):
            return descriptorLhs == descriptorRhs
        case (.error(let errorLhs), .error(let errorRhs)):
            return (errorLhs as NSError).isEqual((errorRhs as NSError))
        default:
            return false
        }
    }
}



enum AppState {
    
    case disconnected
    case preparingConnection
    case connecting(ServerDescriptor)
    case connected(ServerDescriptor)
    case disconnecting(ServerDescriptor)
    case aborted(userInitiated: Bool)
    case error(Error)
    
    public var description: String {
        let base = "AppState - "
        switch self {
        case .disconnected:
            return base + "Disconnected"
        case .preparingConnection:
            return base + "Preparing connection"
        case .connecting(let descriptor):
            return base + "Connecting to: \(descriptor.description)"
        case .connected(let descriptor):
            return base + "Connected to: \(descriptor.description)"
        case .disconnecting(let descriptor):
            return base + "Disconnecting from: \(descriptor.description)"
        case .aborted(let userInitiated):
            return base + "Aborted, user initiated: \(userInitiated)"
        case .error(let error):
            return base + "Error: \(error.localizedDescription)"
        }
    }
    
    public var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    public var isDisconnected: Bool {
        switch self {
        case .disconnected, .preparingConnection, .connecting, .aborted, .error:
            return true
        default:
            return false
        }
    }
    
    public var isStable: Bool {
        switch self {
        case .disconnected, .connected, .aborted, .error:
            return true
        default:
            return false
        }
    }
    
    public var isSafeToEnd: Bool {
        switch self {
        case .connecting, .connected, .disconnecting:
            return false
        default:
            return true
        }
    }
    
    public var descriptor: ServerDescriptor? {
        switch self {
        case .connecting(let desc), .connected(let desc), .disconnecting(let desc):
            return desc
        default:
            return nil
        }
    }

    public static let appStateKey: String = "AppStateKey"
}


protocol SysVPNStateConfigurationFactory {
    func makeVpnStateConfiguration() -> SysVPNStateConfiguration
}

struct VpnStateConfigurationInfo {
     let state: VpnState
     let hasConnected: Bool
     let connection: ConnectionConfiguration?
}

protocol SysVPNStateConfiguration {
    func determineActiveVpnProtocol( completion: @escaping ((VpnProtocol?) -> Void))
    func determineActiveVpnState(vpnProtocol: VpnProtocol, completion: @escaping ((Result<(NEVPNManagerWrapper, VpnState), Error>) -> Void))
    func determineNewState(vpnManager: NEVPNManagerWrapper) -> VpnState
    func getInfo(completion: @escaping ((VpnStateConfigurationInfo) -> Void))
}



class SysVPNStateConfigurationManager: SysVPNStateConfiguration {
 
    private let openVpnProtocolFactory: VpnProtocolFactory
    private let wireguardProtocolFactory: VpnProtocolFactory
   
    /// App group is used to read errors from OpenVPN in user defaults
    private let appGroup: String

    init( openVpnProtocolFactory: VpnProtocolFactory, wireguardProtocolFactory: VpnProtocolFactory, appGroup: String) {
         self.openVpnProtocolFactory = openVpnProtocolFactory
         self.wireguardProtocolFactory = wireguardProtocolFactory
         self.appGroup = appGroup
    }

    func determineNewState(vpnManager: NEVPNManagerWrapper) -> VpnState {
        let status = vpnManager.vpnConnection.status
        let username = vpnManager.protocolConfiguration?.username ?? ""
        let serverAddress = vpnManager.protocolConfiguration?.serverAddress ?? ""

        switch status {
        case .invalid:
            return .invalid
        case .disconnected:
            if let error = lastError() {
                switch error {
                case SysVPNError.tlsServerVerification, SysVPNError.tlsInitialisation:
                    return .error(error)
                default: break
                }
            }
            return .disconnected
        case .connecting:
            return .connecting(ServerDescriptor(username: username, address: serverAddress))
        case .connected:
            return .connected(ServerDescriptor(username: username, address: serverAddress))
        case .reasserting:
            return .reasserting(ServerDescriptor(username: username, address: serverAddress))
        case .disconnecting:
            return .disconnecting(ServerDescriptor(username: username, address: serverAddress))
        }
    }

    private func getFactory(for vpnProtocol: VpnProtocol) -> VpnProtocolFactory {
        switch vpnProtocol {
        case .openVpn:
            return openVpnProtocolFactory
        case .wireGuard:
            return wireguardProtocolFactory
        }
    }

    func determineActiveVpnProtocol(completion: @escaping ((VpnProtocol?) -> Void)) {
        let protocols: [VpnProtocol] = [ .openVpn(.tcp), .wireGuard]
        var activeProtocols: [VpnProtocol] = []

        let dispatchGroup = DispatchGroup()
        for vpnProtocol in protocols {
            dispatchGroup.enter()
            self.getFactory(for: vpnProtocol).vpnProviderManager(for: .status) { [weak self] manager, error in
                defer { dispatchGroup.leave() }
                guard let self = self, let manager = manager else {
                    guard let error = error else { return }

                        // log.error("Couldn't determine if protocol \"\(vpnProtocol.localizedString)\" is active: \"\(String(describing: error))\"", category: .connection)
                    return
                }

                let state = self.determineNewState(vpnManager: manager)
                if state.stableConnection || state.volatileConnection {
                    activeProtocols.append(vpnProtocol)
                }
            }
        }

        dispatchGroup.notify(queue: .main) { 
            if activeProtocols.contains(.openVpn(.tcp)) {
                completion(.openVpn(.tcp))
            } else if activeProtocols.contains(.wireGuard) {
                completion(.wireGuard)
            } else {
                completion(nil)
            }
        }
    }

    public func determineActiveVpnState(vpnProtocol: VpnProtocol, completion: @escaping ((Result<(NEVPNManagerWrapper, VpnState), Error>) -> Void)) {
        getFactory(for: vpnProtocol).vpnProviderManager(for: .status) { [weak self] vpnManager, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let self = self, let vpnManager = vpnManager else {
                return
            }

            let newState = self.determineNewState(vpnManager: vpnManager)
            completion(.success((vpnManager, newState)))
        }
    }

    public func getInfo(completion: @escaping ((VpnStateConfigurationInfo) -> Void)) {
        determineActiveVpnProtocol() { [weak self] vpnProtocol in
            guard let self = self else {
                return
            }

            guard let vpnProtocol = vpnProtocol else {
                completion(VpnStateConfigurationInfo(state: .disconnected,
                                                     hasConnected:   PropertiesManager.shared.hasConnected,
                                                     connection: nil))
                return
            }

            let connection: ConnectionConfiguration?
            switch vpnProtocol {
            case .openVpn:
                connection = PropertiesManager.shared.lastOpenVpnConnection
            case .wireGuard:
                connection = PropertiesManager.shared.lastWireguardConnection
            }

            self.determineActiveVpnState(vpnProtocol: vpnProtocol) { result in
                switch result {
                case let .failure(error):
                    completion(VpnStateConfigurationInfo(state: VpnState.error(error),
                                                         hasConnected: PropertiesManager.shared.hasConnected,
                                                         connection: connection))
                case let .success((_, state)):
                    completion(VpnStateConfigurationInfo(state: state,
                                                         hasConnected: PropertiesManager.shared.hasConnected,
                                                         connection: connection))
                }
            }
        }
    }

    private func lastError() -> Error? {
        let defaults = UserDefaults(suiteName: appGroup)
        let errorKey = "TunnelKitLastError"
        guard let lastError = defaults?.object(forKey: errorKey) as? String else {
            return nil
        }

        switch lastError {
        case "tlsServerVerification":
            return SysVPNError.tlsServerVerification
        case "tlsInitialization":
            return SysVPNError.tlsInitialisation
        default:
            return NSError(domain: lastError, code: 1)
        }
    }
}