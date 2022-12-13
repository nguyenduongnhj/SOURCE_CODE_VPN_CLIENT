//
//  AppDataManager+Recent.swift
//  sysvpn-macos
//
//  Created by macbook on 17/11/2022.
//

import Foundation
enum PrefixNodeInfo: String {
    case country = "CT_"
    case city = "CC_"
    case staticServer = "ST_"
    case multipleHop = "MH_"
}

struct SavedRecentStruct: Codable {
    var prefix: String
    var id: String
    var date: Double
}

struct BoxSaveRecent: Codable {
    var recents: [SavedRecentStruct]
}

let keyListRecent = "SAVE_LIST_RECENT_V2"
extension AppDataManager {
    var listRecents: [SavedRecentStruct] {
        get {
            return BoxSaveRecent.readUserDefault(keyUserDefault: keyListRecent)?.recents ?? []
        }
        set {
            BoxSaveRecent(recents: newValue).saveUserDefault(keyUserDefault: keyListRecent)
            UserDefaults.standard.synchronize()
        }
    }
    
    func addRecent(node: INodeInfo) {
        var id = ""
        var prefix = PrefixNodeInfo.country
        if let country = node as? CountryAvailables, let ctId = country.id {
            id = String(ctId)
            prefix = PrefixNodeInfo.country
        } else if let city = node as? CountryCity, let ccId = city.id {
            id = String(ccId)
            prefix = PrefixNodeInfo.city
        } else if let staticServer = node as? CountryStaticServers, let stId = staticServer.serverId {
            id = String(stId)
            prefix = PrefixNodeInfo.staticServer
        } else if let multipleHop = node as? MultiHopResult, let st1 = multipleHop.entry?.serverId, let st2 = multipleHop.exit?.city?.id {
            id = "\(st1)_\(st2)"
            prefix = PrefixNodeInfo.multipleHop
        }
        
        if id.isEmpty {
            return
        }
        
        var list = AppDataManager.shared.listRecents
       
        list.removeAll { value in
            return value.id == id && value.prefix == prefix.rawValue
        }
        
        if list.count >= 5 {
            list.removeFirst()
        }
        
        let saveNode = SavedRecentStruct(prefix: prefix.rawValue, id: id, date: Date().timeIntervalSince1970)
        list.append(saveNode)
        
        AppDataManager.shared.listRecents = list
        
        GlobalAppStates.shared.recentList.removeAll { model in
            return model.node.locationName == node.locationName && model.node.locationSubname == node.locationSubname
        }
        GlobalAppStates.shared.recentList.append(RecentModel(logDate: Date(), node: node))
    }
    
    func readRecent() {
        let list = AppDataManager.shared.listRecents
        guard let userCountry = userCountry else {
            return
        }
        var recents = [RecentModel]()
        for preId in list {
            let prefix = preId.prefix
            let idValue = preId.id
            
            guard let prefix = PrefixNodeInfo(rawValue: prefix) else {
                return
            }
            
            switch prefix {
            case .country:
                let id = Int(idValue) ?? 0
                if let ct = userCountry.availableCountries?.first(where: { country in
                    return country.id == id
                }) {
                    recents.append(RecentModel(logDate: Date(timeIntervalSince1970: preId.date), node: ct))
                }
            case .city:
                let id = Int(idValue) ?? 0
                for country in userCountry.availableCountries ?? [] {
                    if let city = country.city?.first(where: { city in
                        return city.id == id
                    }) {
                        city.country = country
                        recents.append(RecentModel(logDate: Date(timeIntervalSince1970: preId.date), node: city))
                        break
                    }
                }
            case .staticServer:
                let id = Int(idValue) ?? 0
                if let st = userCountry.staticServers?.first(where: { st in
                    return st.serverId == id
                }) {
                    recents.append(RecentModel(logDate: Date(timeIntervalSince1970: preId.date), node: st))
                }
            case .multipleHop:
                let ids = idValue.split(separator: "_")
                if ids.count < 2 {
                    break
                }
                let serverId = Int(ids[0])
                let exitCityId = Int(ids[1])
                if let mh = mutilHopServer?.first(where: { mh in
                    return mh.entry?.serverId == serverId && mh.exit?.city?.id == exitCityId
                }) {
                    mh.exit?.city?.country = mh.exit?.country
                    recents.append(RecentModel(logDate: Date(timeIntervalSince1970: preId.date), node: mh))
                }
            }
        }
        print("recent \(recents.count)")
        GlobalAppStates.shared.recentList = recents
    }
}
