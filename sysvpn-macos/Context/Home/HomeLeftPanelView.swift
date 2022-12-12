//
//  HomeLeftPanelView.swift
//  sysvpn-macos
//
//  Created by doragon on 14/09/2022.
//

import Foundation
import SwiftUI
enum HomeMenuItem {
    case manualConnection
    case staticIp
    case multiHop
    case profile
    case none
}

struct HomeLeftPanelView: View {
    @Binding var selectedItem: HomeMenuItem
    @StateObject private var viewModel = HomeLeftPanelViewModel()
    var onTouchSetting: (() -> Void)?
    var onChangeTab: (() -> Void)?
    var onTapCreateProfile: (() -> Void)?
    var iconSize: CGFloat = 32
    var quickConnectButton: some View {
        VStack {
            HomeConnectionButtonView {
                viewModel.onTapConnect()
            }
            .frame(height: 250)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
    }
    
    var menuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProfileTabbarView(index: $viewModel.indexTabbar, onChangeTab: {
                onChangeTab?()
            })
            .padding(.horizontal, 16)
            Spacer().frame(height: 20)
            if viewModel.indexTabbar == 0 {
                HomeMenuButtonView(
                    active: selectedItem == .manualConnection,
                    icon: Asset.Assets.icLocation.swiftUIImage,
                    title: L10n.Global.manualConnection,
                    content: "\(viewModel.totalCountry) \(L10n.Global.manualCDesc)"
                ).onTapGesture {
                    withAnimation {
                        selectedItem = .manualConnection
                    }
                }
                HomeMenuButtonView(
                    active: selectedItem == .staticIp,
                    icon: Asset.Assets.icIpAddress.swiftUIImage,
                    title: L10n.Global.staticIP,
                    content: L10n.Global.staticIPDesc
                ).onTapGesture {
                    withAnimation {
                        selectedItem = .staticIp
                    }
                }
                HomeMenuButtonView(
                    active: selectedItem == .multiHop,
                    icon: Asset.Assets.icLink.swiftUIImage,
                    title: L10n.Global.multiHop,
                    content: "\(viewModel.totalMultipleHop) \(L10n.Global.multiHopDesc)"
                ).onTapGesture {
                    withAnimation {
                        selectedItem = .multiHop
                    }
                }
            } else {
                HomeProfileMenuView(onTapCreate: {
                    onTapCreateProfile?()
                }, onTapMore: {
                    withAnimation {
                        selectedItem = .profile
                    }
                })
            }
            
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var settingSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    onTouchSetting?()
                } label: {
                    HStack {
                        Asset.Assets.icSetting.swiftUIImage
                            .frame(width: 12, height: 12)
                        Text(L10n.Global.setting)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                }
                .buttonStyle(LoginButtonNoBackgroundStyle())
                
                Button {
                    print("Edit button was tapped")
                } label: {
                    HStack {
                        Asset.Assets.icSend.swiftUIImage
                            .frame(width: 12, height: 12)
                        Text(L10n.Global.helpCenter)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                }
                .buttonStyle(LoginButtonNoBackgroundStyle())
            }
            
        }.padding(.horizontal, 16)
    }
    
    var footerSection: some View {
        HStack {
            Asset.Assets.avatarDefault.swiftUIImage
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(20)
            VStack(alignment: .leading) {
                Text(viewModel.email)
                    .font(Font.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white)
                Spacer().frame(height: 8)
                if viewModel.isPremium {
                    HStack {
                        Text(L10n.Global.daysLeft(viewModel.dayPremiumLeft))
                            .font(Font.system(size: 12, weight: .medium))
                            .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        Text(L10n.Global.plusExtended)
                            .font(Font.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white)
                    }
                } else {
                    HStack {
                        Text(L10n.Global.daysFree(viewModel.dayFree))
                            .font(Font.system(size: 12, weight: .medium))
                            .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        Text(L10n.Global.plusExtended)
                            .font(Font.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white)
                    }
                }
            }
        }.padding(.horizontal, 16)
    }
    
    var itemSpacer: some View {
        Spacer().frame(height: 24)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            itemSpacer
            quickConnectButton
            menuSection
            Spacer(minLength: 24)
            footerSection
            itemSpacer
            Divider()
                .background(Asset.Colors.dividerColor.swiftUIColor)
                .padding(.horizontal, 16)
            itemSpacer
            settingSection
            itemSpacer
        }.background {
            ZStack {
                Rectangle().foregroundColor(Asset.Colors.backgroundColor.swiftUIColor)
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Asset.Colors.mainLinearStartColor.swiftUIColor,
                            Asset.Colors.mainLinearEndColor.swiftUIColor
                        ], startPoint: UnitPoint.top, endPoint: UnitPoint(x: 0.5, y: 0.3))
                    )
                    .edgesIgnoringSafeArea([.top])
            }
        }
    }
}

struct HomeLeftPanelView_Previews: PreviewProvider {
    @State static var selectedItem: HomeMenuItem = .none
    
    static var previews: some View {
        HomeLeftPanelView(selectedItem: $selectedItem)
            .frame(width: 240, height: 700.0)
            .environmentObject(GlobalAppStates.shared)
    }
}
 