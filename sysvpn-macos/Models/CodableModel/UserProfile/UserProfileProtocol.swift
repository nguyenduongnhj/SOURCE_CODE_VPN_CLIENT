//
//  UserProfileProtocol.swift
//  sysvpn-macos
//
//  Created by doragon on 30/11/2022.
//

import Foundation

protocol UserProfileProtocol {
    func getProfileName() -> String?
    func getServerId() -> Int?
    func getProfileIcon()
}

struct UserProfileTemp: Codable, UserProfileProtocol, Identifiable {
    func getProfileName() -> String? {
        return profileName
    }
    
    func getServerId() -> Int? {
        return serverId
    }
    
    func getProfileIcon() {}
    
    enum CodingKeys: String, CodingKey {
        case profileName
        case serverId
        case profileId
    }

    var profileName: String?
    var serverId: Int?
    var profileId: UUID?
    var id: UUID = .init()
    
    static func getFakeData() -> [UserProfileTemp] {
        var item = UserProfileTemp()
        item.profileName = "Gaming"
        item.serverId = 34
        var listTemp = [UserProfileTemp]()
        listTemp.append(item)
        listTemp.append(item)
        return listTemp
    }
    
    static func loadDataProfile() {}
    
    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileName = try container.decodeIfPresent(String.self, forKey: .profileName)
        serverId = try container.decodeIfPresent(Int.self, forKey: .serverId)
        profileId = try container.decodeIfPresent(UUID.self, forKey: .profileId)
    }
    
    func saveUserProfile() {
        saveFile(fileName: .keySaveUserProfile)
    }
    
    func getUserProfile() -> UserProfileTemp? {
        return UserProfileTemp.readFile(fileName: .keySaveUserProfile) as? UserProfileTemp
    }
}
