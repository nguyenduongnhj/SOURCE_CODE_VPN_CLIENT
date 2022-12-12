//
//  HomeListCountryNodeView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/10/2022.
//

import Foundation
import Kingfisher
import SwiftUI

struct HomeListCountryNodeView: View {
    var selectedItem: HomeMenuItem
    var countries: [HomeListCountryModel]
    var isShowCity: Bool
    var countrySelected: HomeListCountryModel?
    var onTouchItem: ((INodeInfo) -> Void)?
    var onTouchQuestion: (() -> Void)?
    var onDetailCountry: ((HomeListCountryModel) -> Void)?
    @State var textInput: String = ""
    
    var listFilter: [HomeListCountryModel] {
        if textInput.isEmpty {
            return countries
        } else {
            return countries.filter { item in
                if item.type == .spacing || item.type == .header || !item.canFilter {
                    return false
                }
                return item.title.localizedCaseInsensitiveContains(textInput)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if selectedItem == .multiHop {
                questionHeader
                    .padding(.bottom, 20)
            }
            if countries.count >= 5 {
                SearchInputView(textInput: $textInput)
                    .padding(.top, 2)
                    .padding(.bottom, 12)
            }
            
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(listFilter) { item in
                        Group {
                            switch item.type {
                            case .spacing:
                                Spacer().frame(height: 30)
                            case .country:
                                if item.origin is CountryAvailables {
                                    CountryItemView(countryName: item.title, imageUrl: item.imageUrl, totalCity: item.totalCity)
                                        .onTapGesture {
                                            if item.totalCity > 1 {
                                                /* self.isShowCity = true
                                                 self.countrySelected = item*/
                                                onDetailCountry?(item)
                                            } else {
                                                guard let origin = item.origin else {
                                                    return
                                                }
                                                onTouchItem?(origin)
                                            }
                                        }
                                } else if item.origin is CountryCity {
                                    CountryItemView(countryName: item.title, imageUrl: item.imageUrl, totalCity: item.totalCity)
                                        .onTapGesture {
                                            if item.totalCity > 1 {
                                                /* self.isShowCity = true
                                                 self.countrySelected = item */
                                                onDetailCountry?(item)
                                            } else {
                                                guard let origin = item.origin else {
                                                    return
                                                }
                                                onTouchItem?(origin)
                                            }
                                        }
                                } else if let data = item.origin as? MultiHopResult {
                                    MultiHopItemView(countryNameStart: data.entry?.country?.name ?? "", countryNameEnd: data.exit?.country?.name ?? "", imageUrlStart: item.imageUrl, imageUrlEnd: item.imageUrl2 ?? data.exit?.country?.imageUrl ?? "")
                                        .onTapGesture {
                                            guard let origin = item.origin else {
                                                return
                                            }
                                            onTouchItem?(origin)
                                        }
                                } else if item.origin is CountryStaticServers {
                                    StaticItemView(countryName: item.title, cityName: item.cityName, imageUrl: item.imageUrl, serverNumber: item.serverNumber, percent: item.serverStar)
                                        .onTapGesture {
                                            guard let origin = item.origin else {
                                                return
                                            }
                                            onTouchItem?(origin)
                                        }
                                } else {
                                    Spacer()
                                }
                            case .header:
                                if selectedItem == .manualConnection || selectedItem == .multiHop {
                                    VStack {
                                        Text(item.title)
                                            .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                                            .font(Font.system(size: 14, weight: .regular))
                                        Spacer().frame(height: 21)
                                    }
                                } else if selectedItem == .staticIp {
                                    HStack {
                                        Text(item.title)
                                            .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                                            .font(Font.system(size: 14, weight: .regular))
                                        Spacer()
                                        Text(L10n.Global.currentLoadLabel)
                                            .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                                            .font(Font.system(size: 11, weight: .medium))
                                    }.padding(.bottom, 16)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Asset.Colors.backgroundColor.swiftUIColor)
    }
    
    var questionHeader: some View {
        HStack(spacing: 8) {
            Asset.Assets.icQuestion.swiftUIImage
                .resizable()
                .frame(width: 20, height: 20)
            Text(L10n.Global.whatIsMultihop)
                .foregroundColor(.white)
                .font(Font.system(size: 14, weight: .regular))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTouchQuestion?()
        }
    }
}

struct HomeDetailCityNodeView: View {
    var selectedItem: HomeMenuItem
    var listCity: [HomeListCountryModel]
    var isShowCity: Bool
    var countryItem: HomeListCountryModel?
    var onTouchItem: ((INodeInfo) -> Void)?
    var onBack: (() -> Void)?
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Asset.Assets.icArrowLeft.swiftUIImage
                    .resizable()
                    .frame(width: 24, height: 24)
                if countryItem?.imageUrl != nil {
                    KFImage(URL(string: (countryItem?.imageUrl!)!))
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(16)
                } else {
                    Asset.Assets.icFlagEmpty.swiftUIImage
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(16)
                }
                Text(countryItem?.title ?? "")
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 16, weight: .semibold))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onBack?()
            }
            
            ScrollView([.vertical], showsIndicators: false) {
                LazyVStack(alignment: .leading) {
                    ForEach(listCity) { item in
                        CityItemView(countryName: countryItem?.title ?? "", cityName: item.title, imageUrl: item.imageUrl)
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                            .onTapGesture {
                                guard let origin = item.origin else {
                                    return
                                }
                                onTouchItem?(origin)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background(Asset.Colors.backgroundColor.swiftUIColor)
    }
}

struct HomeListWraperView: ViewModifier {
    var onClose: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
        
            .frame(width: 300, alignment: .leading)
            .background(Asset.Colors.backgroundColor.swiftUIColor)
            .transition(
                AnyTransition.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .leading)
                ).combined(with: .opacity))
    }
}
  
enum HomeListCountryModelType {
    case header
    case country
    case spacing
}

struct HomeListCountryModel: Identifiable, Equatable {
    static func == (lhs: HomeListCountryModel, rhs: HomeListCountryModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = UUID()
    var type: HomeListCountryModelType
    var title: String = ""
    var totalCity: Int = 0
    var imageUrl: String?
    var cityName: String = ""
    var serverNumber: Int = 0
    var serverStar: Int = 1
    var idCountry: Int = 0
    var title2: String = ""
    var imageUrl2: String?
    var origin: INodeInfo?
    var canFilter: Bool = true
}

struct ListViewModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        content
    }
}
