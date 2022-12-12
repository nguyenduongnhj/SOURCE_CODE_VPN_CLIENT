//
//  HomeModel.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/10/2022.
//

import Combine
import Foundation

extension HomeView {
    @MainActor class HomeViewModel: ObservableObject {
        @Published var selectedMenuItem: HomeMenuItem = .none
  
        @Published var lookScrollZoom = false
        @Published var isOpenSetting = false
        @Published var isShowPopupLogout = false
        @Published var isShowPopupQuestion = false
        @Published var isOpenCreateProfile = false
        @Published var isShowRenameProfile = false
        
        @Published var listCountry: [HomeListCountryModel]
        @Published var listStaticServer: [HomeListCountryModel]
        @Published var listMultiHop: [HomeListCountryModel]
        @Published var listProfileUser: [HomeListProfileModel]
        
        var listCity: [HomeListCountryModel]
        var countrySelected: HomeListCountryModel?
        
        var cancellabel: AnyCancellable?
        var cancellabel1: AnyCancellable?
        var cancellabel2: AnyCancellable?
        var cancellabel3: AnyCancellable?
        
        var itemProfileEdit: UserProfileTemp?
        var isEditLocation: Bool = false
        
        var isConnected: Bool = false
        
        init() {
            listCountry = []
            listStaticServer = []
            listMultiHop = []
            listCity = []
            listProfileUser = []
            getListCountry()
            getListStaticServer()
            getListMultiHop()
            getProfileUser()
            
            _ = GlobalAppStates.shared.initApp {
                print("init app success")
            }
            
            setupCancelZoom()
        }
        
        func setupCancelZoom() {
            cancellabel = Publishers.CombineLatest($selectedMenuItem, $isOpenSetting).receive(on: RunLoop.main).map {
                return $0.0 != .none || $0.1
            }.eraseToAnyPublisher().assign(to: \HomeViewModel.lookScrollZoom, on: self) as AnyCancellable
            
            cancellabel1 = Publishers.CombineLatest($selectedMenuItem, $isShowPopupLogout).receive(on: RunLoop.main).map {
                return $0.0 != .none || $0.1
            }.eraseToAnyPublisher().assign(to: \HomeViewModel.lookScrollZoom, on: self) as AnyCancellable
            
            cancellabel2 = Publishers.CombineLatest($selectedMenuItem, $isOpenCreateProfile).receive(on: RunLoop.main).map {
                return $0.0 != .none || $0.1
            }.eraseToAnyPublisher().assign(to: \HomeViewModel.lookScrollZoom, on: self) as AnyCancellable
            
            cancellabel3 = Publishers.CombineLatest($selectedMenuItem, $isShowRenameProfile).receive(on: RunLoop.main).map {
                return $0.0 != .none || $0.1
            }.eraseToAnyPublisher().assign(to: \HomeViewModel.lookScrollZoom, on: self) as AnyCancellable
        }
        
        func onViewAppear() {}
            
        func getListCountry() {
            updateAvailableContry()
        }
         
        func getProfileUser() {
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
            listProfileUser = listTemp
        }
        
        func onChangeCountry(item: HomeListCountryModel?) {
            listCity = []
            let availableCountry = AppDataManager.shared.userCountry?.availableCountries ?? []
            let countryData = availableCountry.filter { data in
                return data.id == (item?.idCountry ?? 0)
            }.first
            let arrCity = countryData?.city ?? []
                
            for dataCity in arrCity {
                let itemCityModel = HomeListCountryModel(type: .country, title: dataCity.name ?? "", origin: dataCity)
                listCity.append(itemCityModel)
            }
        }
        
        func onSignOut() {
            AppDataManager.shared.logOut(openWindow: true)
        }
            
        func updateAvailableContry() {
            var listCountryTemp = [HomeListCountryModel]()
            if GlobalAppStates.shared.recentList.isEmpty {
                AppDataManager.shared.readRecent()
            }
            
            let recentCountry = GlobalAppStates.shared.recentList
            let availableCountry = AppDataManager.shared.userCountry?.availableCountries ?? []
            let recommendCountry = AppDataManager.shared.userCountry?.recommendedCountries ?? []
            
            if !recentCountry.isEmpty {
                var insertedRecent = false
                for item in recentCountry {
                    if item.node is CountryCity || item.node is CountryAvailables {
                        var rawNode: INodeInfo = item.node
                        var totalChild = 0
                        var countryId = 0
                        if let nodeCity = item.node as? CountryCity {
                            rawNode = nodeCity.country ?? nodeCity
                            totalChild = nodeCity.country?.city?.count ?? 0
                            countryId = nodeCity.countryId ?? 0
                        }
                        let countryItemModel = HomeListCountryModel(type: .country, title: item.node.locationName, totalCity: totalChild, imageUrl: item.node.imageUrl, idCountry: countryId, title2: item.node.locationSubname ?? "", origin: rawNode, canFilter: false)
                        listCountryTemp.insert(countryItemModel, at: 0)
                        insertedRecent = true
                    }
                }
                
                if insertedRecent {
                    listCountryTemp.insert(HomeListCountryModel(type: .header, title: L10n.Global.recentLocationsLabel), at: 0)
                    listCountryTemp.append(HomeListCountryModel(type: .spacing))
                }
            }
            
            if !recommendCountry.isEmpty {
                listCountryTemp.append(HomeListCountryModel(type: .header, title: L10n.Global.recommendedLabel))
                for item in recommendCountry {
                    let countryItemModel = HomeListCountryModel(type: .country, title: item.name ?? "", totalCity: item.city?.count ?? 0, imageUrl: item.flag, idCountry: item.id ?? 0, origin: item)
                    listCountryTemp.append(countryItemModel)
                }
                listCountryTemp.append(HomeListCountryModel(type: .spacing))
            }
            if !availableCountry.isEmpty {
                listCountryTemp.append(HomeListCountryModel(type: .header, title: L10n.Global.allCountriesLabel))
                for item in availableCountry {
                    let countryItemModel = HomeListCountryModel(type: .country, title: item.name ?? "", totalCity: item.city?.count ?? 0, imageUrl: item.flag, idCountry: item.id ?? 0, origin: item)
                    listCountryTemp.append(countryItemModel)
                }
                listCountryTemp.append(HomeListCountryModel(type: .spacing))
            }
            
            listCountry = listCountryTemp
        }
            
        func getListStaticServer(firstLoadData: Bool = true) {
            listStaticServer.removeAll()
            let staticServer = AppDataManager.shared.userCountry?.staticServers ?? []
            if !staticServer.isEmpty {
                listStaticServer.append(HomeListCountryModel(type: .header, title: L10n.Global.staticIpLabel))
                for item in staticServer {
                    let score = item.score ?? 1
                    let staticItem = HomeListCountryModel(type: .country, title: item.countryName ?? "", imageUrl: item.flag, cityName: item.cityName ?? "", serverNumber: item.serverNumber ?? 1, serverStar: score + 1, origin: item)
                    listStaticServer.append(staticItem)
                }
                listStaticServer.append(HomeListCountryModel(type: .spacing))
            }
        }
            
        func getListMultiHop() {
            let multiHopServer = AppDataManager.shared.mutilHopServer ?? []
            if !multiHopServer.isEmpty {
                listMultiHop.append(HomeListCountryModel(type: .header, title: L10n.Global.multihopLabel))
                for item in multiHopServer {
                    let multiHopItem = HomeListCountryModel(type: .country, title: item.entry?.country?.name ?? "", imageUrl: item.entry?.country?.flag, title2: item.exit?.country?.name ?? "", imageUrl2: item.exit?.country?.flag, origin: item)
                    listMultiHop.append(multiHopItem)
                }
            }
        }
            
        func onChangeState() {
            if selectedMenuItem == .manualConnection {
                if listCountry.isEmpty {
                    updateAvailableContry()
                }
            }
        }
            
        func connect(to info: INodeInfo? = nil) {
            MapAppStates.shared.connectedNode = nil
            guard let info = info else {
                return
            }
            _ = DependencyContainer.shared
                .vpnCore.connectTo(node: info, isRetry: false)
        }
    }
}

extension HomeLeftPanelView {
    @MainActor class HomeLeftPanelViewModel: ObservableObject {
        @Published var selectedMenuItem: HomeMenuItem = .none
        @Published var totalCountry: Int = 0
        @Published var totalMultipleHop: Int = 0
        @Published var indexTabbar: CGFloat = 0
        
        var email: String {
            return AppDataManager.shared.userData?.email ?? ""
        }
        
        var dayPremiumLeft: Int {
            return AppDataManager.shared.userData?.dayPreniumLeft ?? 0
        }
        
        var isPremium: Bool {
            return AppDataManager.shared.userData?.isPremium ?? false
        }
        
        var dayFree: Int {
            return AppDataManager.shared.userData?.freePremiumDays ?? 0
        }

        var isConnected: Bool = false
        
        init() {
            onUpdateServer()
            onUpdateMultipleHop()
            NotificationCenter.default.addObserver(self, selector: #selector(onUpdateServer), name: .updateCountry, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(onUpdateMultipleHop), name: .updateMultipleHop, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: .updateCountry, object: nil)
            NotificationCenter.default.removeObserver(self, name: .updateMultipleHop, object: nil)
        }
        
        @objc func onUpdateServer() {
            AppDataManager.shared.asyncLoadConfig {
                return AppDataManager.shared.userCountry?.availableCountries ?? []
            } completion: { availableCountry in
                self.totalCountry = availableCountry.count
            }
        }
        
        @objc func onUpdateMultipleHop() {
            AppDataManager.shared.asyncLoadConfig {
                return AppDataManager.shared.mutilHopServer ?? []
            } completion: { availableCountry in
                self.totalMultipleHop = availableCountry.count
            }
        }
        
        func onTapConnect() {
            if GlobalAppStates.shared.displayState == .disconnected {
                MapAppStates.shared.connectedNode = nil
                let dj = DependencyContainer.shared
                if let selectedNode = MapAppStates.shared.selectedNode {
                    if !dj.vpnCore.connectTo(node: selectedNode, isRetry: false) {
                        dj.vpnCore.quickConnect()
                    }
                } else {
                    dj.vpnCore.quickConnect()
                }
            } else {
                if GlobalAppStates.shared.displayState == .disconnecting {
                    return
                }
                if GlobalAppStates.shared.displayState == .connecting {
                    DependencyContainer.shared.vpnCore.stopConnecting(userInitiated: true)
                }
                GlobalAppStates.shared.displayState = .disconnected
                DependencyContainer.shared.vpnCore.disconnect()
            }
        }
    }
}
