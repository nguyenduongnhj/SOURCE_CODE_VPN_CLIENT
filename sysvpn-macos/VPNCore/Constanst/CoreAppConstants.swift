//
//  CoreAppConstants.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 09/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation

public class CoreAppConstants {
    struct LogFiles {
        static var openVpn = "debug.log"
        static var wireGuard = "WireGuard.log"
    }
    
    struct UpdateTime {
        static let quickUpdateTime: TimeInterval = 3.0
        static let quickReconnectTime: TimeInterval = 0.5
        static let announcementRefreshTime: TimeInterval = 12 * 60 * 60
    }
    
    static var appBundleId: String = (Bundle.main.bundleIdentifier ?? "om.sysvpn.client.macos").asMainAppBundleIdentifier
    
    struct AppGroups {
        static let main = "JM6FBPTUR3.group.com.sysvpn.macos"
        static let teamId = "JM6FBPTUR3"
    }
     
    struct NetworkExtensions {
        /*
         static let openVpn = "\(appBundleId).OpenVpnSysExtension"
         static let wireguard = "\(appBundleId).WireGuardSysExtension"
          */
        // static let openVpn = "\(appBundleId).OpenVpnAppExtension"
        static let openVpn = "\(appBundleId).AppVpnAppExtension"
        //  static let wireguard = "\(appBundleId).WireGuardAppExtension"
        static let wireguard = "\(appBundleId).AppVpnAppExtension"
    }
    
    struct SystemExtensions {
        static let openVpn = "\(appBundleId).AppSysExtension"
        static let wireguard = "\(appBundleId).AppSysExtension"
        // static let wireguard = "\(appBundleId).WireGuardSysExtension"
    }
    
    struct VPNProtocolName {
        static let openVpn = "OPENVPN"
        static let wireguard = "WIREGUARD"
        static let configurationField = "vpnProtocolConfiguration"
    }
}

extension String {
    var asMainAppBundleIdentifier: String {
        var result = replacingOccurrences(of: ".widget", with: "")
        result = result.replacingOccurrences(of: ".AppSysExtension", with: "")
        result = result.replacingOccurrences(of: ".AppVpnAppExtension", with: "")
        return result
    }
}
