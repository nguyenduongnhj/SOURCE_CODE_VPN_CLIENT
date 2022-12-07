//
//  AppVpnService.swift
//  sysvpn-macos
//
//  Created by doragon on 18/10/2022.
//

import Foundation
import RxSwift

class AppVpnService: SysVPNService {
    var cancelPrepare: Disposable?
    func prepareConection(connectType: ConnectionType, params: SysVPNConnectParams?, callback: SysVPNPrepareConnecitonStringCallback?) {
        // let userSetting = AppDataManager.shared.userSetting
        cancelPrepare?.dispose()
        cancelPrepare = nil
        
        
        
        var appProtocol = PropertiesManager.shared.vpnProtocol 
        
        if appProtocol == nil {
            let userSetting = AppDataManager.shared.userSetting?.appSettings?.settingVpn
            let defaultVAlue: VpnProtocol = (userSetting?.defaultTech?.contains("wg") ?? true) ? .wireGuard : .openVpn((userSetting?.defaultProtocol?.contains("udp") ?? false) ? .udp : .tcp)
            appProtocol = defaultVAlue
        }
        
        let isWireGuard = appProtocol == .wireGuard
        var transportProtocol = OpenVpnTransport.udp
        if case let .openVpn(transport) = appProtocol {
            if transport == .tcp {
                transportProtocol = .tcp
            }
        }
        let defaultTech = isWireGuard ? VpnProtocol.wireGuard : VpnProtocol.openVpn(transportProtocol)
        //  let defaultTech = VpnProtocol.wireGuard
        let vpnParam = VpnParamRequest()
        
        vpnParam.tech = isWireGuard ? .wg : .ovpn
        vpnParam.proto = transportProtocol.rawValue
        vpnParam.dev = "tun"
        vpnParam.isHop = (params?.isHop ?? false) ? 1 : 0
        vpnParam.cybersec = PropertiesManager.shared.cybersec ? 1 : 0
        
        switch connectType {
        case .quick:
            var quickConnectId = PropertiesManager.shared.countryQuickConnect ?? (AppDataManager.shared.userCountry?.recommendedCountries?.first ?? AppDataManager.shared.userCountry?.availableCountries?.first)?.id
            vpnParam.countryId = quickConnectId
        case let .serverId(id):
            vpnParam.serverId = id
        case let .countryId(id):
            vpnParam.countryId = id
        case let .cityId(id):
            vpnParam.cityId = id
        case let .lastSessionCode(code, serverId, _):
            vpnParam.prevSessionId = code
            vpnParam.serverId = serverId
        }
        if isWireGuard {
            cancelPrepare = APIServiceManager.shared.onRequestCertWireGuard(param: vpnParam).subscribe { event in
                switch event {
                case let .success(response):
                    let strConfig = response.parseVpnConfig()
                    let disconnectParam = DisconnectVPNParams(sessionId: response.sessionId ?? "", disconnectedBy: "client")
                    let result = PrepareConnecitonStringResult(connectionString: strConfig, vpnProtocol: defaultTech, disconnectParam: disconnectParam, serverInfo: response.server ?? VPNServer())
                    callback?(.success(result))
                case let .failure(e):
                    print("[ERROR]: \(e)")
                    callback?(.failure(e))
                }
            }
        } else {
            cancelPrepare = APIServiceManager.shared.onRequestCert(param: vpnParam).subscribe { event in
                switch event {
                case let .success(response):
                    let strConfig = response.parseVpnConfig()
                    let disconnectParam = DisconnectVPNParams(sessionId: response.sessionId ?? "", disconnectedBy: "client")
                    let result = PrepareConnecitonStringResult(connectionString: strConfig, vpnProtocol: defaultTech, disconnectParam: disconnectParam, serverInfo: response.server ?? VPNServer())
                    callback?(.success(result))
                case let .failure(e):
                    print("[ERROR]: \(e)")
                    callback?(.failure(e))
                }
            }
        }
    }
    
    func disconnectLastSession(disconnectParam: DisconnectVPNParams?, callback: ((Result<Bool, Error>) -> Void)?) {
        cancelPrepare?.dispose()
        cancelPrepare = nil
        _ = APIServiceManager.shared.onDisconnect(sectionId: disconnectParam?.sessionId ?? "", disconnectedBy: disconnectParam?.disconnectedBy ?? "").subscribe { event in
            switch event {
            case .success:
                callback?(.success(true))
            case let .failure(e):
                print("[ERROR]: \(e)")
                callback?(.failure(e))
            }
        }
    }
}
