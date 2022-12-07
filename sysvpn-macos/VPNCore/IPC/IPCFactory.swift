//
//  IPCFactory.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 16/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation

enum IPCServiceProto: String {
    case openVPN = "com.sysvpn.macos.openvpn"
    case wireGuard = "com.sysvpn.macos.wireguard"

    public var machServiceName: String {
        let teamId = CoreAppConstants.AppGroups.teamId
        return "\(teamId).group.\(rawValue)"
    }
}

class IPCFactory {
    static let shared = IPCFactory()
    private lazy var openVPNIPC = XPCServiceUser(withExtension: IPCServiceProto.openVPN.machServiceName, logger: { print("\($0)") })
    
    private lazy var wireGuardIPC = XPCServiceUser(withExtension: IPCServiceProto.wireGuard.machServiceName, logger: { print("\($0)") })
    
    class func makeIPCService(proto: IPCServiceProto) -> XPCServiceUser {
        switch proto {
        case .wireGuard:
            return IPCFactory.shared.wireGuardIPC
        case .openVPN:
            return IPCFactory.shared.openVPNIPC
        }
    }

    class func makeIPCRequestService() -> XPCServiceUser {
        return IPCFactory.shared.openVPNIPC
    }
}
