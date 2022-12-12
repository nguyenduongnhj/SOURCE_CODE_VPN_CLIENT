//
//  PacketTunnelProvider.swift
//  OpenVpnSysExtension
//
//  Created by macbook on 17/10/2022.
//
import Foundation
import NetworkExtension
import os.log
import TunnelKitManager
import TunnelKitOpenVPNAppExtension

enum VPNProtocol {
    case openVPN
    case wireGuard
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    var lastConnectProtoAdapter: ProtoAdapter?
    
    private lazy var openVPNAdapter = OpenVPNTunnelAdapter(packetTunnelProvider: self)
    private lazy var wireguardAdapter = WireGuardTunnelAdapter(packetTunnelProvider: self)
     
    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        var tunnelProtocol: VPNProtocol = .wireGuard
        
        if let tunnel = protocolConfiguration as? NETunnelProviderProtocol {
            let protocolConfiguration = tunnel.providerConfiguration?[CoreAppConstants.VPNProtocolName.configurationField] as? String
            if protocolConfiguration == CoreAppConstants.VPNProtocolName.openVpn {
                tunnelProtocol = .openVPN
            }
        }
         
        os_log("%{public}s", log: OSLog(subsystem: "SysVPNIPC-OP", category: "IPC"), type: .default, "loadata \(tunnelProtocol)")
        
        lastConnectProtoAdapter = getTunnelByProtocol(proto: tunnelProtocol)
        lastConnectProtoAdapter?.startTunnel(options: options, completionHandler: completionHandler)
      
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        lastConnectProtoAdapter?.stopTunnel(with: reason, completionHandler: completionHandler)
     
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        lastConnectProtoAdapter?.handleAppMessage(messageData, completionHandler: completionHandler)
    }
    
    func getTunnelByProtocol(proto: VPNProtocol) -> ProtoAdapter {
        switch proto {
        case .openVPN:
            return openVPNAdapter
        case .wireGuard:
            return wireguardAdapter
        }
    }
 
    public var interfaceName: String? {
        guard let tunnelFileDescriptor = tunnelFileDescriptor else { return nil }

        var buffer = [UInt8](repeating: 0, count: Int(IFNAMSIZ))

        return buffer.withUnsafeMutableBufferPointer { mutableBufferPointer in
            guard let baseAddress = mutableBufferPointer.baseAddress else { return nil }

            var ifnameSize = socklen_t(IFNAMSIZ)
            let result = getsockopt(
                tunnelFileDescriptor,
                2,
                2,
                baseAddress,
                &ifnameSize)

            if result == 0 {
                return String(cString: baseAddress)
            } else {
                return nil
            }
        }
    }
    
    private var tunnelFileDescriptor: Int32? {
        var ctlInfo = ctl_info()
        withUnsafeMutablePointer(to: &ctlInfo.ctl_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: $0.pointee)) {
                _ = strcpy($0, "com.apple.net.utun_control")
            }
        }
        for fd: Int32 in 0...1024 {
            var addr = sockaddr_ctl()
            var ret: Int32 = -1
            var len = socklen_t(MemoryLayout.size(ofValue: addr))
            withUnsafeMutablePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    ret = getpeername(fd, $0, &len)
                }
            }
            if ret != 0 || addr.sc_family != AF_SYSTEM {
                continue
            }
            if ctlInfo.ctl_id == 0 {
                ret = ioctl(fd, CTLIOCGINFO, &ctlInfo)
                if ret != 0 {
                    continue
                }
            }
            if addr.sc_id == ctlInfo.ctl_id {
                return fd
            }
        }
        return nil
    }
}
