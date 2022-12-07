//
//  AppDataManager+Cache.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 27/10/2022.
//

import Foundation

extension AppDataManager {
    func loadSetupData(complete: @escaping () -> Void) -> DispatchGroup {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        loadAppSetting {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        loadCountry {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        loadListMultiHop {
            dispatchGroup.leave()
        }
         
        dispatchGroup.notify(queue: DispatchQueue.main) {
            complete()
        }
        
        return dispatchGroup
    }
    
    func loadAppSetting(completion: @escaping () -> Void) {
        _ = APIServiceManager.shared.getAppSetting().subscribe { event in
            defer {
                completion()
            }
            switch event {
            case let .success(response):
                DispatchQueue.global(qos: .background).async {
                    AppDataManager.shared.saveIpInfo(info: response.ipInfo)
                    AppDataManager.shared.userSetting = response
                }
                // AppDataManager.shared.lastChange > 0 && 
                if AppDataManager.shared.lastChange != (response.lastChange ?? 0) {
                    NotificationCenter.default.post(name: .needUpdateServerInfo, object: nil)
                }
                AppDataManager.shared.lastChange = response.lastChange ?? 0
            case let .failure(e):
                guard let error = e as? ResponseError else {
                    return
                }
                print(error)
            }
        }
    }
    
    func loadCountry(completion: @escaping () -> Void) {
        _ = APIServiceManager.shared.getListCountry().subscribe { result in
            defer {
                completion()
            }
            switch result {
            case let .success(response):
                DispatchQueue.global(qos: .background).async {
                    AppDataManager.shared.userCountry = response
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .updateCountry, object: nil)
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    func loadListMultiHop(completion: @escaping () -> Void) {
        _ = APIServiceManager.shared.getListMultiHop().subscribe { result in
            defer {
                completion()
            }
            switch result {
            case let .success(response):
                DispatchQueue.global(qos: .background).async {
                    AppDataManager.shared.mutilHopServer = response
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .updateMultipleHop, object: nil)
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    func loadUpdateStast(completion: @escaping () -> Void) {
        if AppDataManager.shared.userCountry != nil {
            _ = APIServiceManager.shared.getStartServer().subscribe { result in
                defer {
                    completion()
                }
                switch result {
                case let .success(response):
                    DispatchQueue.global(qos: .background).async {
                        response.updateStarCountry()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .reloadServerStar, object: nil)
                        }
                    }
                case .failure:
                    break
                }
            }
        } else {
            completion()
        }
    }
    
    func updaterServerIP() {
        if let hostName = URL(string: Constant.API.root)?.host {
            let userDefaultsShared = UserDefaults(suiteName: CoreAppConstants.AppGroups.main)
            let info = IPCHelper.urlToIPGetHostByName(hostname: hostName)
            userDefaultsShared?.setValue(info, forKey: "server_ips")
        }
    }
    
    func asyncLoadConfig<T>(_ onLoad: @escaping () -> T, completion: @escaping (T) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let result = onLoad()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    var longestSessiontime: Double {
        get {
            return UserDefaults.standard.double(forKey: .keySaveLongestSessionTime)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keySaveLongestSessionTime)
        }
    }
    
    var weeklyIndex: Int {
        get {
            return UserDefaults.standard.integer(forKey: .keySaveWeeklyIndex)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keySaveWeeklyIndex)
        }
    }
    
    var weeklySessionTime: Double {
        get {
            return UserDefaults.standard.double(forKey: .keySaveWeeklyTime)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: .keySaveWeeklyTime)
        }
    }
}
