//
//  OpenVPNProtocolFactory.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 09/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation
import NetworkExtension
import TunnelKitOpenVPNAppExtension
import TunnelKitOpenVPNCore

class OpenVpnProtocolFactory {
    private let debugLogFormat = "$Dyyyy-MM-dd'T'HH:mm:ss.SSSZ$d $L protocol $N.$F:$l - $M"
    var bundleId: String {
        if IPCFactory.makeIPCRequestService().isAvailable {
            return CoreAppConstants.SystemExtensions.openVpn
        }
        return CoreAppConstants.NetworkExtensions.openVpn
    }

    private let appGroup: String
    private let vpnManagerFactory: NETunnelProviderManagerWrapperFactory
    private var vpnManager: NEVPNManagerWrapper?
    public init(appGroup: String,
                vpnManagerFactory: NETunnelProviderManagerWrapperFactory) {
        self.appGroup = appGroup
        self.vpnManagerFactory = vpnManagerFactory
    }
}

extension OpenVpnProtocolFactory: VpnProtocolFactory {
    func create(_ configuration: SysVpnManagerConfiguration) throws -> NEVPNProtocol {
        let openVpnConfig = try getOpenVpnConfig(for: configuration)
        /* let generator = tunnelProviderGenerator(for: openVpnConfig)
         let neProtocol = try generator.generatedTunnelProtocol(withBundleIdentifier: bundleId, appGroup: appGroup, context: bundleId, username: configuration.username) */
        let vpnProto = try openVpnConfig.asTunnelProtocol(withBundleIdentifier: bundleId, extra: configuration.extra)
     
        vpnProto.providerConfiguration?[CoreAppConstants.VPNProtocolName.configurationField] = CoreAppConstants.VPNProtocolName.openVpn
        return vpnProto
    }
    
    func vpnProviderManager(for requirement: VpnProviderManagerRequirement, completion: @escaping (NEVPNManagerWrapper?, Error?) -> Void) {
        if requirement == .status, let vpnManager = vpnManager {
            completion(vpnManager, nil)
        } else {
            vpnManagerFactory.tunnelProviderManagerWrapper(forProviderBundleIdentifier: bundleId) { manager, error in
                if let manager = manager {
                    self.vpnManager = manager
                }
                completion(manager, error)
            }
        }
    }
    
    func logs(completion: @escaping (String?) -> Void) {
        //    completion(log)
    }
    
    func getOpenVpnConfig(for configuration: SysVpnManagerConfiguration) throws -> OpenVPN.ProviderConfiguration {
        let cfg = (try OpenVPN.ConfigurationParser.parsed(fromContents: configuration.connection)).configuration
        var providerConfiguration = OpenVPN.ProviderConfiguration(configuration.adapterTitle, appGroup: appGroup, configuration: cfg)
        providerConfiguration.shouldDebug = true
        providerConfiguration.masksPrivateData = false
        return providerConfiguration
    }
}
