//
//  HomeListProfileViewModel.swift
//  sysvpn-macos
//
//  Created by doragon on 02/12/2022.
//

import Combine
import Foundation

extension HomeListProfileView {
    @MainActor class HomeListProfileViewModel: ObservableObject {
        @Published var textInput: String = ""
        @Published var indexSelect: UUID = .init()
        @Published var listProfile: [HomeListProfileModel]
        var changeSink: AnyCancellable?
        
        init() {
            listProfile = []
            getProfileUser()
            listen()
        }
        
        func listen() {
            changeSink = GlobalAppStates.shared.$listProfile.sink { listProfile in
                self.listProfile = []
                var listTemp = [HomeListProfileModel]()
                if !listProfile.isEmpty {
                    listTemp.append(HomeListProfileModel(type: .header, title: L10n.Global.allProfile))
                    for item in listProfile {
                        let item = HomeListProfileModel(type: .body, title: item.profileName ?? "", profileDetail: item)
                        listTemp.append(item)
                    }
                }
                self.listProfile = listTemp
            }
        }
        
        func getProfileUser() {
            listProfile = []
            if GlobalAppStates.shared.listProfile.isEmpty {
                AppDataManager.shared.readListProfile()
            }
            let profile = GlobalAppStates.shared.listProfile
            
            var listTemp = [HomeListProfileModel]()
            if !profile.isEmpty {
                listTemp.append(HomeListProfileModel(type: .header, title: L10n.Global.allProfile))
                for item in profile {
                    let item = HomeListProfileModel(type: .body, title: item.profileName ?? "", profileDetail: item)
                    listTemp.append(item)
                }
            }
            listProfile = listTemp
        }
        
        func deleteProfile(_ id: UUID) {
            var profileResult = UserProfileResult()
            profileResult.listProfile = []
            
            listProfile.removeAll { item in
                return item.id == id
            }
            
            for item in listProfile {
                if item.id != id {
                    if let profile = item.profileDetail as? UserProfileTemp {
                        profileResult.listProfile?.append(profile)
                    }
                }
            }
            GlobalAppStates.shared.listProfile = profileResult.listProfile ?? []
            AppDataManager.shared.saveProfile()
        }
        
        func pickToTop(_ id: UUID) {
            let item = listProfile.filter { data in
                return data.id == id
            }.first
            
            listProfile.removeAll { item in
                return item.id == id
            }
            listProfile.insert(item!, at: 1)
            var profileResult = UserProfileResult()
            profileResult.listProfile = []
            
            for item in listProfile {
                if let profile = item.profileDetail as? UserProfileTemp {
                    profileResult.listProfile?.append(profile)
                }
            }
            GlobalAppStates.shared.listProfile = profileResult.listProfile ?? []
            AppDataManager.shared.saveProfile()
        }
        
        func rename(_: UUID) {}
        
        func setLocation() {}
    }
}
