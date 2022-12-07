//
//  AppDataManager.swift
//  sysvpn-macos
//
//  Created by doragon on 18/09/2022.
//

import Foundation

extension String {
    static var keySaveRefreshToken = "USER_REFRESH_TOKEN_TEST_2"
    static var keySaveAccessToken = "USER_ACCESS_TOKEN_TEST_2   "
    static var keyUserIP = "USER_IP"
    static var keyUserCity = "USER_CITY"
    static var keyUserCountryCode = "USER_COUNTRY_CODE"
    static var keyUserLatitude = "USER_LATITUDE"
    static var keyUserLongitude = "USER_LONGTITUDE"
    static var keyUserIsp = "USER_ISP"
    static var keyUserIsConnect = "USER_IS_CONNECT"
    static var keyUserInfo = "KEY_USER_INFO"
    static var keySaveUserData = "KEY_USER_DATA"
    static var keySaveCountry = "KEY_SAVE_COUNTRY"
    static var keySaveUserSetting = "KEY_SAVE_USER_SETTING"
    static var keySaveUserProfile = "KEY_SAVE_USER_PROFILE"
    static var keySaveListUserProfile = "KEY_SAVE_LIST_USER_PROFILE"
    static var keySaveLastChange = "KEY_SAVE_LAST_CHANGE"
    static var keySaveMutilHop = "KEY_SAVE_MULTI_HOP"
    static var keyIsMultiplehop = "KEY_IS_MULTI_HOP"
    static var keySaveLongestSessionTime = "KEY_SAVE_LONG_ST1"
    static var keySaveWeeklyTime = "KEY_SAVE_WEEKLY_TIME1"
    static var keySaveWeeklyIndex = "KEY_SAVE_WEEKLY_TIME_INDEX1"
}

class AppDataManager {
    static var shared = AppDataManager()
    
    private var _user: AuthUser?
    
    var userData: AuthUser? {
        get {
            if !isLogin {
                return nil
            }
            if _user == nil {
                _user = AuthUser.fromSaved()
            }
            return _user
        }
        set {
            _user = newValue
            _user?.save()
        }
    }
    
    private var _cacheAccessToken: AuthAccess?
    var accessToken: AuthAccess? {
        get {
            if _cacheAccessToken == nil {
                _cacheAccessToken = AuthAccess.readUserDefault(keyUserDefault: .keySaveAccessToken) // UserDefaults.standard.string(forKey: .keySaveAccessToken)
            }
            return _cacheAccessToken
        }
        set {
            _cacheAccessToken = newValue
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: .keySaveAccessToken)
            } else {
                newValue?.saveUserDefault(keyUserDefault: .keySaveAccessToken)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    private var _cacheRefreshToken: AuthRefresh?
    var refreshToken: AuthRefresh? {
        get {
            if _cacheRefreshToken == nil {
                //  _cacheRefreshToken = UserDefaults.standard.string(forKey: .keySaveRefreshToken)
                _cacheRefreshToken = AuthRefresh.readUserDefault(keyUserDefault: .keySaveRefreshToken)
            }
            return _cacheRefreshToken
        }
        set {
            _cacheRefreshToken = newValue
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: .keySaveRefreshToken)
            } else {
                newValue?.saveUserDefault(keyUserDefault: .keySaveRefreshToken)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    var isLogin: Bool {
        return accessToken != nil
    }
    
    var userIp: String {
        get {
            return UserDefaults.standard.string(forKey: .keyUserIP) ?? "127.0.0.1"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserIP)
        }
    }
    
    var userCity: String {
        get {
            return UserDefaults.standard.string(forKey: .keyUserCity) ?? "Ha Noi"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserCity)
        }
    }
    
    var userCountryCode: String {
        get {
            return UserDefaults.standard.string(forKey: .keyUserCountryCode) ?? "VN"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserCountryCode)
        }
    }
    
    var latitude: Double {
        get {
            return UserDefaults.standard.double(forKey: .keyUserLatitude)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserLatitude)
        }
    }
    
    var longitude: Double {
        get {
            return UserDefaults.standard.double(forKey: .keyUserLongitude)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserLongitude)
        }
    }
    
    var userIsp: String {
        get {
            return UserDefaults.standard.string(forKey: .keyUserIsp) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserIsp)
        }
    }
    
    var isConnect: Bool {
        get {
            return UserDefaults.standard.bool(forKey: .keyUserIsConnect)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keyUserIsConnect)
        }
    }
    
    var isMultipleHop: Bool {
        // return UserDefaults.standard.bool(forKey: .keyIsMultiplehop)
        return DependencyContainer.shared.vpnCore.lastConnectionConiguration?.connectionParam?.isHop == true
    }
    
    func saveIpInfo(info: AppSettingIpInfo?) {
        userIp = info?.ip ?? "127.0.0.1"
        userCity = info?.city ?? "Unknown"
        userCountryCode = info?.countryCode ?? " "
        latitude = info?.latitude ?? 0.0
        longitude = info?.longitude ?? 0.0
        userIsp = info?.isp ?? ""
        DispatchQueue.main.async {
            GlobalAppStates.shared.userIpAddress = self.userIp
        }
    }
    
    private var _userEtting: AppSettingResult?
    
    var userSetting: AppSettingResult? {
        get {
            if _userEtting == nil {
                _userEtting = AppSettingResult.getUserSetting()
            }
            return _userEtting
        }
        set {
            objc_sync_enter(self)
            defer{
                objc_sync_exit(self)
            }
            _userEtting = newValue
            _userEtting?.saveUserSetting()
        }
    }
    
    var lastChange: Double {
        get {
            return UserDefaults.standard.double(forKey: .keySaveLastChange)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keySaveLastChange)
        }
    }
    
    private var _userCountry: CountryResult?
    
    var userCountry: CountryResult? {
        get {
            if _userCountry == nil {
                _userCountry = CountryResult.getListCountry()
            }
            return _userCountry
        }
        set {
            _userCountry = newValue
            _userCountry?.saveListCountry()
        }
    }
     
    private var _mutilHopServer: [MultiHopResult]?
    
    var mutilHopServer: [MultiHopResult]? {
        get {
            if _mutilHopServer == nil {
                _mutilHopServer = MultiHopSaveWraper.getListMultiHop()?.hop
            }
            return _mutilHopServer
        }
        set {
            _mutilHopServer = newValue
            let value = MultiHopSaveWraper(hop: newValue)
            value.saveListMultiHop()
        }
    }
    
    func getStaticNodeByServerInfo(server: VPNServer) -> INodeInfo? {
        if let node = userCountry?.staticServers?.first(where: { sInfo in
            return sInfo.serverId == server.id
        }) {
            return node
        }
        
        return nil
    }
    
    func getNodeByCountryId(countryId: Int) -> INodeInfo? {
        guard let country = userCountry?.availableCountries?.first(where: { ct in
            return ct.id == countryId
        }) else {
            return nil
        }
        return country
    }
    
    func getNodeByDeepId(deepId: String) -> INodeInfo? {
        if deepId.starts(with: PrefixNodeInfo.multipleHop.rawValue) {
            guard let hop = mutilHopServer?.first(where: { sv in
                return sv.deepId == deepId
            }) else {
                return nil
            }
            hop.entry?.city?.country = hop.entry?.country
            hop.exit?.city?.country = hop.exit?.country
            return hop
        } else if deepId.starts(with: PrefixNodeInfo.city.rawValue) {
            guard let country = userCountry?.availableCountries?.first(where: { ct in
                return ct.city?.contains(where: { city in
                    return city.deepId == deepId
                }) ?? false
            }) else {
                return nil
            }
            
            guard let city = country.city?.first(where: { city in
                return city.deepId == deepId
            }) else {
                return country
            }
            let updateCity = city
            updateCity.country = country
            return updateCity
        } else if deepId.starts(with: PrefixNodeInfo.country.rawValue) {
            guard let country = userCountry?.availableCountries?.first(where: { ct in
                return ct.deepId == deepId
            }) else {
                return nil
            }
            return country
        } else if deepId.starts(with: PrefixNodeInfo.staticServer.rawValue) {
            if let node = userCountry?.staticServers?.first(where: { sInfo in
                return sInfo.deepId == deepId
            }) {
                return node
            }
        }
        return nil
    }
    
    func getNodeByServerInfo(server: VPNServer) -> INodeInfo? {
        if isMultipleHop {
            guard let hop = mutilHopServer?.first(where: { sv in
                return sv.entry?.serverId == server.id
            }) else {
                return nil
            }
            hop.entry?.city?.country = hop.entry?.country
            hop.exit?.city?.country = hop.exit?.country
            return hop
        }
        
        guard let country = userCountry?.availableCountries?.first(where: { ct in
            return ct.city?.contains(where: { city in
                return city.id == server.cityId
            }) ?? false
        }) else {
            return getStaticNodeByServerInfo(server: server)
        }
        
        guard let city = country.city?.first(where: { city in
            return city.id == server.cityId
        }) else {
            return country
        }
        let updateCity = city
        updateCity.country = country
        
        return updateCity
    }
    
    func logOut(openWindow: Bool = false, manual: Bool = true, completion: (() -> Void)? = nil) {
        _ = APIServiceManager.shared.onLogout().subscribe { _ in
            AppDataManager.shared.refreshToken = nil
        }
        
        if manual {
            DependencyContainer.shared.vpnCore.disconnect()
        }
        
        NotificationCenter.default.post(name: .endJobUpdate, object: nil)
        accessToken = nil
        if openWindow {
            OpenWindows.LoginView.open()
        }
        DispatchQueue.main.async {
            completion?()
        }
    }
}
