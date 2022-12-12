//
//  File.swift
//  sysvpn-macosOpenVPNTunnelExtension
//
//  Created by macbook on 23/10/2022.
//
 
import __TunnelKitUtils
import Foundation
import NetworkExtension
import os
import os.log
import SwiftyBeaver
import TunnelKitWireGuardAppExtension
import TunnelKitWireGuardCore
import TunnelKitWireGuardManager
import WireGuardKit

open class WireGuardTunnelAdapter: ProtoAdapter {
    private var cfg: WireGuard.ProviderConfiguration!
    private weak var packetTunnelProvider: NEPacketTunnelProvider!

    private lazy var adapter: WireGuardAdapter = .init(with: packetTunnelProvider) { logLevel, message in
        wg_log(logLevel.osLogLevel, message: message)
    }
    
    init(packetTunnelProvider: NEPacketTunnelProvider?) {
        self.packetTunnelProvider = packetTunnelProvider
    }

    override open func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // BEGIN: TunnelKit
        
        guard let tunnelProviderProtocol = packetTunnelProvider.protocolConfiguration as? NETunnelProviderProtocol else {
            fatalError("Not a NETunnelProviderProtocol")
        }
        guard let providerConfiguration = tunnelProviderProtocol.providerConfiguration else {
            fatalError("Missing providerConfiguration")
        }

        let tunnelConfiguration: TunnelConfiguration
        do {
            cfg = try fromDictionary(WireGuard.ProviderConfiguration.self, providerConfiguration)
            tunnelConfiguration = cfg.configuration.tunnelConfiguration
        } catch {
            completionHandler(WireGuardProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        
        configureLogging()

        // END: TunnelKit

        // Start the tunnel
        adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
            guard let adapterError = adapterError else {
                let interfaceName = self.adapter.interfaceName ?? "unknown"

                wg_log(.info, message: "Tunnel interface is \(interfaceName)")

                completionHandler(nil)
                return
            }

            switch adapterError {
            case .cannotLocateTunnelFileDescriptor:
                wg_log(.error, staticMessage: "Starting tunnel failed: could not determine file descriptor")
                self.cfg._appexSetLastError(.couldNotDetermineFileDescriptor)
                completionHandler(WireGuardProviderError.couldNotDetermineFileDescriptor)

            case let .dnsResolution(dnsErrors):
                let hostnamesWithDnsResolutionFailure = dnsErrors.map { $0.address }
                    .joined(separator: ", ")
                wg_log(.error, message: "DNS resolution failed for the following hostnames: \(hostnamesWithDnsResolutionFailure)")
                self.cfg._appexSetLastError(.dnsResolutionFailure)
                completionHandler(WireGuardProviderError.dnsResolutionFailure)

            case let .setNetworkSettings(error):
                wg_log(.error, message: "Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)")
                self.cfg._appexSetLastError(.couldNotSetNetworkSettings)
                completionHandler(WireGuardProviderError.couldNotSetNetworkSettings)

            case let .startWireGuardBackend(errorCode):
                wg_log(.error, message: "Starting tunnel failed with wgTurnOn returning \(errorCode)")
                self.cfg._appexSetLastError(.couldNotStartBackend)
                completionHandler(WireGuardProviderError.couldNotStartBackend)

            case .invalidState:
                // Must never happen
                fatalError()
            }
        }
    }

    override open func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        wg_log(.info, staticMessage: "Stopping tunnel")

        adapter.stop { error in
            // BEGIN: TunnelKit
            self.cfg._appexSetLastError(nil)
            // END: TunnelKit

            if let error = error {
                wg_log(.error, message: "Failed to stop WireGuard adapter: \(error.localizedDescription)")
            }
            completionHandler()

            #if os(macOS)
                // HACK: This is a filthy hack to work around Apple bug 32073323 (dup'd by us as 47526107).
                // Remove it when they finally fix this upstream and the fix has been rolled out to
                // sufficient quantities of users.
                exit(0)
            #endif
        }
    }

    override open func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        guard let completionHandler = completionHandler else { return }

        if messageData.count == 1 && messageData[0] == 0 {
            adapter.getRuntimeConfiguration { settings in
                var data: Data?
                if let settings = settings {
                    data = settings.data(using: .utf8)!
                }
                completionHandler(data)
            }
        } else {
            completionHandler(nil)
        }
    }
}

extension WireGuardTunnelAdapter {
    private func configureLogging() {
        let logLevel: SwiftyBeaver.Level = (cfg.shouldDebug ? .debug : .info)
        let logFormat = cfg.debugLogFormat ?? "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M"
        
        if cfg.shouldDebug {
            let console = ConsoleDestination()
            console.useNSLog = true
            console.minLevel = logLevel
            console.format = logFormat
            SwiftyBeaver.addDestination(console)
        }

        let file = FileDestination(logFileURL: cfg._appexDebugLogURL)
        file.minLevel = logLevel
        file.format = logFormat
        file.logFileMaxSize = 20000
        SwiftyBeaver.addDestination(file)

        // store path for clients
        cfg._appexSetDebugLogPath()
    }
}

extension WireGuardLogLevel {
    var osLogLevel: OSLogType {
        switch self {
        case .verbose:
            return .debug
        case .error:
            return .error
        }
    }
}
