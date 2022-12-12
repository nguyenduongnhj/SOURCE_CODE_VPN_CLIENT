//
//  APIService.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 31/08/2022.
//

import Alamofire
import AppKit
import Moya

enum APIService {
    case getAppSettings
    case login(email: String, password: String)
    case getListCountry
    case logout
    case requestCert(vpnParam: VpnParamRequest)
    case disconnectSession(sectionId: String, disconnectedBy: String)
    case getStartServer
    case getListMutilHop
    case refreshToken
    case changePassword(oldPassword: String, newPassword: String)
    case loginSocial(provider: String, token: String)
}

extension APIService: TargetType {
    // This is the base URL we'll be using, typically our server.
    var baseURL: URL {
        switch self {
        case .getAppSettings, .login, .logout, .requestCert, .disconnectSession, .getStartServer, .getListMutilHop, .refreshToken, .changePassword, .loginSocial:
            return URL(string: Constant.API.root)!
            
        case .getListCountry:
            return URL(string: Constant.API.baseUrl)!
        }
    }

    // This is the path of each operation that will be appended to our base URL.
    var path: String {
        switch self {
        case .refreshToken:
            return Constant.API.Path.resfreshToken
        case .getAppSettings:
            return Constant.API.Path.ipInfo
        case .login:
            return Constant.API.Path.login
        case .getListCountry:
            return Constant.API.Path.listCountry2
        case .logout:
            return Constant.API.Path.logout
        case .requestCert:
            return Constant.API.Path.requestCert
        case .disconnectSession:
            return Constant.API.Path.disconnectSession
        case .getStartServer:
            return Constant.API.Path.getStartServer
        case .getListMutilHop:
            return Constant.API.Path.mutilHopServer
        case .changePassword:
            return Constant.API.Path.changePassword
        case .loginSocial:
            return Constant.API.Path.loginSocial
        }
    }

    // Here we specify which method our calls should use.
    var method: Moya.Method {
        switch self {
        case .getAppSettings, .getListCountry, .requestCert, .getStartServer, .getListMutilHop:
            return .get
        case .login, .logout, .loginSocial, .refreshToken:
            return .post
        case .disconnectSession:
            return .patch
        case .changePassword:
            return .put
        }
    }

    // Here we specify body parameters, objects, files etc.
    // or just do a plain request without a body.
    // In this example we will not pass anything in the body of the request.
    var task: Task {
        var param: [String: Any] = [:]
        param["deviceInfo"] = nil 
        param["deviceInfo"] = AppSetting.shared.getDeviceInfo()
        switch self {
        case .getAppSettings:
            param["platform"] = "macos"
            return .requestParameters(parameters: param, encoding: URLEncoding.queryString)
        case let .login(email, password):
            param["email"] = email
            param["password"] = password
            return .requestParameters(parameters: param, encoding: URLEncoding.default)
        case .logout:
            param["refreshToken"] = AppDataManager.shared.refreshToken
            return .requestParameters(parameters: param, encoding: URLEncoding.default)
        case .getListCountry:
            return .requestParameters(parameters: param, encoding: URLEncoding.queryString)
        case let .requestCert(vpnParam):
            param["proto"] = vpnParam.proto
            param["dev"] = vpnParam.dev
            param["countryId"] = vpnParam.countryId
            param["prevSessionId"] = vpnParam.prevSessionId
            param["serverId"] = vpnParam.serverId
            param["cityId"] = vpnParam.cityId
            param["cybersec"] = vpnParam.cybersec
            param["isHop"] = vpnParam.isHop
            param["tech"] = vpnParam.tech?.vpnTypeStr ?? "ovpn"
            return .requestParameters(parameters: param, encoding: URLEncoding.queryString)
        case let .disconnectSession(sectionId, disconnectedBy):
            param["sessionId"] = sectionId
            param["disconnectedBy"] = disconnectedBy
            return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
        case .getStartServer, .getListMutilHop:
            return .requestParameters(parameters: param, encoding: URLEncoding.default)
        case .refreshToken:
            param["deviceInfo"] = AppSetting.shared.getDeviceInfo()
            param["refreshToken"] = AppDataManager.shared.refreshToken?.token
            return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
            
        case let .changePassword(oldPassword, newPassword):
            param["oldPassword"] = oldPassword
            param["newPassword"] = newPassword
            return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
            
        case let .loginSocial(provider, token):
            param["provider"] = provider
            param["token"] = token
            param["deviceInfo"] = AppSetting.shared.getDeviceInfo()
            return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
        }
    }

    // These are the headers that our service requires.
    // Usually you would pass auth tokens here.
    var headers: [String: String]? {
        switch self {
        case .getListCountry, .requestCert, .disconnectSession, .getStartServer, .getListMutilHop, .changePassword:
            return ["Content-type": "application/x-www-form-urlencoded",
                    "Authorization": "Bearer " + (AppDataManager.shared.accessToken?.token ?? ""),
                    "x-device-info": AppSetting.shared.getDeviceInfo()
            ]
        default:
            return ["Content-type": "application/x-www-form-urlencoded"]
        }
    }
}
