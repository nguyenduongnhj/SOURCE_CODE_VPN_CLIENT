//
//  VpnMapViewModel.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 03/09/2022.
//

import Foundation
import SwiftUI
import Kingfisher


extension VpnMapView {
    @MainActor class VpnMapViewModel: ObservableObject {
        
        @Published var listCity: [NodePoint] = []
        @Published var listCountry: [NodePoint] = []
        @Published var isLoaded: Bool = false
         
        init() {
           
            refreshApi()
        }
        
        func refreshApi() {
            _ = APIServiceManager.shared.getListCountry().subscribe { event in
                switch event {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.asyncAfter(deadline: .now()  + 2) { [weak self] in
                        self?.refreshApi()
                    }
                case .success(let success):
                    AppDataManager.shared.userCountry = success
                }
                self.loadListNode()
                self.isLoaded = true
            }
        }
        
        func loadListNode() {
            let listCountry = AppDataManager.shared.userCountry?.availableCountries ?? []
            var listCity: [CountryCity] = [];
            
            for country  in listCountry {
                guard let cities =  country.city else {
                    continue
                }
                cities.forEach { city in
                    var updateCity = city
                    updateCity.country = country
                    listCity.append(updateCity)
                }
               
            } 
            self.listCountry = listCountry.map { country in
                return NodePoint(point: CGPoint(x: NodePoint.convertX (country.x), y: NodePoint.convertY(country.y) ), info: country)
            }
            
            self.listCity = listCity.map({ city in
                return NodePoint(point: CGPoint(x: NodePoint.convertX(Double(city.x ?? 0)), y: NodePoint.convertY(Double(city.y ?? 0))), info:  city)
            })
        }
    }
    
}


extension NodePoint {
    static func convertX(_ value: Double? , scale: Double = 1) -> CGFloat {
        return (value ?? 0) * 588/1588
    }
    
    static func convertY(_ value: Double? , scale: Double = 1) -> CGFloat {
        return (value ?? 0) * 588/1588
    }
}

extension CountryStaticServers: INodeInfo, Equatable {
 
    
    static func == (lhs: CountryStaticServers, rhs: CountryStaticServers) -> Bool {
        return CountryStaticServers.equal(lhs: lhs, rhs: rhs)
    }
    var state: VpnMapPontState {
        if GlobalAppStates.shared.displayState == .connected {
            if let connectedNode = MapAppStates.shared.connectedNode {
                if CountryAvailables.equal(lhs: connectedNode, rhs: self)  {
                    return .activated
                }
            }
            return .disabled
        }
        return .normal
    }
    
    var localtionIndex: Int? {
        return nil
    }
    
    var locationName: String {
        return self.countryName ?? ""
    }
    
    var image: Kingfisher.KFImage? {
        guard let flagUrl = self.flag,  let url = URL(string: flagUrl ) else {
            return nil
        }
        return  KFImage.url(url).placeholder { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle())

        }
    }
    
    var locationDescription: String? {
        return nil
    }
    
    var locationSubname: String? {
        return nil
    }
     
    
}
extension CountryCity : INodeInfo, Equatable  {
    static func == (lhs: CountryCity, rhs: CountryCity) -> Bool {
        return CountryCity.equal(lhs: lhs, rhs: rhs)
    }
 
    var locationDescription: String? {
        return nil
    }
    
    var locationSubname: String? {
        return self.name
    }
    
    var locationName: String{
        return self.country?.name ?? ""
    }
    
    var state: VpnMapPontState {
        if GlobalAppStates.shared.displayState == .connected {
            if let connectedNode = MapAppStates.shared.connectedNode {
                if CountryAvailables.equal(lhs: connectedNode, rhs: self)  {
                    return .activated
                }
            }
            return .disabled
        }
        return .normal
    }
    
    var localtionIndex: Int? {
        return nil
    }
    
    var image: KFImage? {
        guard let flagUrl = country?.flag,  let url = URL(string: flagUrl ) else {
            return nil
        }
        return  KFImage.url(url).placeholder { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle())

        }
    }
}

extension CountryAvailables : INodeInfo, Equatable {
    static func == (lhs: CountryAvailables, rhs: CountryAvailables) -> Bool {
        return CountryAvailables.equal(lhs: lhs, rhs: rhs)
    }
    
    var locationDescription: String? {
        return nil
    }
    
    var locationSubname: String? {
        return nil
    }
    
    var locationName: String{
        return name ?? ""
    }
    
    var state: VpnMapPontState {
       
        if GlobalAppStates.shared.displayState == .connected {
            if let connectedNode = MapAppStates.shared.connectedNode {
                if CountryAvailables.equal(lhs: connectedNode, rhs: self)  {
                    return .activated
                }
            }
            return .disabled
        }
       
        return .normal
    }
    
    var localtionIndex: Int? {
        return nil
    }
    
    var image: KFImage? {
        guard let flagUrl = flag,  let url = URL(string: flagUrl) else {
            return nil
        }
        return  KFImage.url(url).placeholder { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle())

        }
    }
}

extension MultiHopResult: INodeInfo, Equatable {
    var state: VpnMapPontState {
        if GlobalAppStates.shared.displayState == .connected {
            return .disabled
        }
        return .normal
    }
    
    var localtionIndex: Int? {
        return nil
    }
    
    var locationName: String {
        let name = self.entry?.country?.locationName ?? ""
        let name2 = self.exit?.country?.locationName ?? ""
        
        return "Multihop \(name)-\(name2)"
    }
    
    var image: KFImage? {
        guard let flagUrl = self.entry?.country?.flag,  let url = URL(string: flagUrl) else {
            return nil
        }
        return  KFImage.url(url).placeholder { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle())
        }
    }
    
    var locationDescription: String? {
        return nil
    }
    
    var locationSubname: String? {
       
        let name = self.exit?.country?.locationName ?? ""
        return name
    }
    
    static func == (lhs: MultiHopResult, rhs: MultiHopResult) -> Bool {
        return MultiHopResult.equal(lhs: lhs, rhs: rhs)
    }
     
}


extension INodeInfo {
    func toNodePoint (_ content: String? = nil) -> NodePoint {
        
        if let cacheNode = self.cacheNode {
            return cacheNode
        }
        
        var result: NodePoint
        
        if let country = self as? CountryAvailables {
            result =  NodePoint(point: CGPoint(x: NodePoint.convertX (country.x), y: NodePoint.convertY(country.y) ), info: country, locationDescription: content)
            country.cacheNode = result
        } else  if let city = self as? CountryCity {
            let l1Point = CGPoint(x: NodePoint.convertX (city.x?.double), y: NodePoint.convertY(city.y?.double) )
            var l2Point:CGPoint? = nil
            if let country = city.country {
                l2Point = CGPoint(x: NodePoint.convertX (country.x), y: NodePoint.convertY(country.y) )
            } 
            result = NodePoint(point: l1Point, info: city, locationDescription: content, l2Point: l2Point)
            city.cacheNode = result
        } else  if let staticServer = self as? CountryStaticServers {
            result =   NodePoint(point: CGPoint(x: NodePoint.convertX (staticServer.x), y: NodePoint.convertY(staticServer.y) ), info: staticServer, locationDescription: content)
            staticServer.cacheNode = result
        } else  if let multipleHop = self as? MultiHopResult ,let  node = multipleHop.exit?.city {
            
            result =   NodePoint(point: CGPoint(x: NodePoint.convertX (node.x?.double), y: NodePoint.convertY(node.y?.double) ), info:  multipleHop.exit?.city ?? multipleHop, locationDescription: content)
            multipleHop.cacheNode = result
        }
        else {
            result = NodePoint(point: .zero, info: NodeInfoTest(state: .disabled))
        }
        return result
    }
}



