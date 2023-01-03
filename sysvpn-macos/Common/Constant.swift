//
//  Constant.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 31/08/2022.
//

import Foundation
struct Constant {
    struct API {
        #if DEBUG
            static let root = "https://prod.sysvpnconnect.com"
//         static let root = "https://api.sysvpnconnect.com"
        #else
            static let root = "https://prod.sysvpnconnect.com"
        #endif
        
        static let baseUrl = "http://localhost:3000"
        
        struct Path {
            static let listCountry2 = "/v1/country/get_list"
            static let requestCertV2 = "/v1/vpn/request_cert"
            static let loginV2 = "/v1/auth/login"
            
            static let ipInfo = "/app/module_server/v1/app_setting/get_app_settings"
            static let listCountry = "/app/module_server/v1/country/get_list"
            static let requestCert = "/app/module_server/v1/vpn/request_certificate"
            static let getStartServer = "/app/module_server/v1/server_stats/get_static_server_stats"
            static let mutilHopServer = "/app/module_server/v1/multi_hop/get_list"
            
            static let logout = "/shared/module_auth/v1/logout"
            static let login = "/shared/module_auth/v1/login"
            static let disconnectSession = "/shared/module_server/v1/vpn/disconnect_session"
            static let resfreshToken = "/shared/module_auth/v1/refresh-tokens"
            static let changePassword = "/shared/module_user/v1/change-password"
            static let loginSocial = "/shared/module_auth/v1/login-social"
        }
    }
    struct SERVER {
        static let PublicKey =  "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtHUE1ilipG7XgvbCjSj7knAW85x4\nMJBULkTpMGspQm4rBKDbkAGLAva1Ed12APxxh46CtiV62zU51WcxqdbHmg==\n-----END PUBLIC KEY-----"
        
    }
}
