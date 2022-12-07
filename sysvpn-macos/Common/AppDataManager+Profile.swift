//
//  AppDataManager+Profile.swift
//  sysvpn-macos
//
//  Created by doragon on 02/12/2022.
//

import Foundation

struct UserProfileResult: Codable {
    var listProfile: [UserProfileTemp]?
    
    enum CodingKeys: String, CodingKey {
        case listProfile
    }
    
    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        listProfile = try container.decodeIfPresent([UserProfileTemp].self, forKey: .listProfile)
    }
    
    func saveUserProfile() {
        saveFile(fileName: .keySaveListUserProfile)
    }
    
    static func getUserProfile() -> UserProfileResult? {
        return UserProfileResult.readFile(fileName: .keySaveListUserProfile) as? UserProfileResult
    }
}

extension AppDataManager {
    func saveProfile() {
        var profile = UserProfileResult()
        profile.listProfile = GlobalAppStates.shared.listProfile
        profile.saveUserProfile()
    }
    
    func readListProfile() {
        GlobalAppStates.shared.listProfile = UserProfileResult.getUserProfile()?.listProfile ?? []
    }
}
