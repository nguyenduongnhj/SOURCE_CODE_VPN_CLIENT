//
//  MenuQuickAccessView.swift
//  sysvpn-macos
//
//  Created by doragon on 29/09/2022.
//

import SwiftUI

enum TabbarMenuItem {
    case recent
    case allCountry
    case suggest
}
 
struct MenuQuickAccessView: View {
    @StateObject private var viewModel = MenuQuickAccessModel()
    @EnvironmentObject var appState: GlobalAppStates
    @EnvironmentObject var networkState: NetworkAppStates
    
    @State var connectionState: AppDisplayState = .disconnected
    var sizeIcon: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if connectionState == .connected || connectionState == .disconnecting {
                    headerMenuConnected
                        .transition(.opacity)
                } else {
                    headerMenuNotConnect
                        .transition(.opacity)
                }
            }.frame(height: 155)
            bodyMenu
            footerMenu
        }
        .cornerRadius(8)
        .onAppear {
            connectionState = appState.displayState
        }
        .onChange(of: appState.displayState) { newValue in
            withAnimation {
                connectionState = newValue
            }
            if connectionState == .connected || connectionState == .disconnected {
                DispatchQueue.main.async {
                    viewModel.getListRecent()
                }
                viewModel.onNeedRefreshUI()
            }
        }
        .onChange(of: networkState.bitRate) { _ in
            viewModel.downloadSpeed = Bitrate.rateString(for: networkState.bitRate.download)
            viewModel.uploadSpeed = Bitrate.rateString(for: networkState.bitRate.upload)
        }
    }
    
    var headerMenuNotConnect: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(viewModel.userIp)
                    .lineLimit(nil)
                    .font(Font.system(size: 14, weight: .semibold))
                    .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                    .padding(.bottom, 1)
                Text(L10n.Login.unprotected)
                    .lineLimit(nil)
                    .font(Font.system(size: 14, weight: .semibold))
                    .foregroundColor(Asset.Colors.textErrorColor.swiftUIColor)
                    .padding(.bottom, 1)
            }
            Text(viewModel.location)
                .lineLimit(nil)
                .font(Font.system(size: 14))
                .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
            Spacer().frame(height: 15)
            if connectionState == .connecting {
                Button {
                    GlobalAppStates.shared.displayState = .disconnected
                    viewModel.onTouchDisconnect()
                } label: {
                    AppActivityIndicator()
                }.buttonStyle(LoginButtonCTAStyle())
            } else {
                Button {
                    viewModel.onTouchConnect()
                    
                } label: {
                    Text(L10n.Login.quickConnect)
                        .font(Font.system(size: 14, weight: .semibold))
                }.buttonStyle(LoginButtonCTAStyle())
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .padding(28)
        .background(Color(rgb: 0x101016))
    }
    
    var headerMenuConnected: some View {
        VStack(alignment: .leading) {
            HStack {
                if let icon = MapAppStates.shared.connectedNode?.image {
                    icon.resizable()
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).stroke(style: .init(lineWidth: 2))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(viewModel.userIp)
                            .lineLimit(nil)
                            .font(Font.system(size: 14, weight: .semibold))
                            .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                            .padding(.bottom, 1)
                        Text(L10n.Login.protected)
                            .lineLimit(nil)
                            .font(Font.system(size: 14, weight: .semibold))
                            .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                            .padding(.bottom, 1)
                    }
                    Text(viewModel.location)
                        .lineLimit(nil)
                        .font(Font.system(size: 14))
                        .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                }
            }
            Spacer().frame(height: 20)
            HStack {
                HStack {
                    HStack {
                        Asset.Assets.icArrowUp.swiftUIImage
                            .frame(width: sizeIcon, height: sizeIcon)
                        Text(viewModel.uploadSpeed)
                            .font(Font.system(size: 12, weight: .regular))
                            .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                    }.frame(maxWidth: .infinity)
                    Spacer().frame(width: 16)
                    HStack {
                        Asset.Assets.icArrowDown.swiftUIImage
                            .frame(width: sizeIcon, height: sizeIcon)
                        Text(viewModel.downloadSpeed)
                            .font(Font.system(size: 12, weight: .regular))
                            .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                    }.frame(maxWidth: .infinity)
                }
                .padding(EdgeInsets(top: 13.0, leading: 8.0, bottom: 13.0, trailing: 10.0))
                .background(Color(hexString: "FFFFFF").opacity(0.2))
                .cornerRadius(8)
                
                Button {
                    GlobalAppStates.shared.displayState = .disconnected
                    viewModel.onTouchDisconnect()
                } label: {
                    Text(L10n.Login.disconnect)
                        .font(Font.system(size: 14, weight: .semibold))
                }
                .frame(width: 120)
                .buttonStyle(LoginButtonCTAStyle(bgColor: Color(hexString: "FFFFFF")))
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .padding(28)
        .background(Color(hexString: "105175"))
    }
    
    var bodyMenu: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    viewModel.onChageTab(index: 0)
                    withAnimation {
                        viewModel.tabbarSelectedItem = .recent
                    }
                } label: {
                    TabBarButton(text: L10n.Login.recent, isSelected: .constant(viewModel.tabbarSelectedItem == .recent))
                        .frame(width: 110)
                        .contentShape(Rectangle())
                        .background(viewModel.tabbarSelectedItem == .recent ? Asset.Assets.bgTabbar.swiftUIImage : nil)
                }
                .frame(width: 110)
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    viewModel.onChageTab(index: 1)
                    withAnimation {
                        viewModel.tabbarSelectedItem = .suggest
                    }
                } label: {
                    TabBarButton(text: L10n.Login.suggest, isSelected: .constant(viewModel.tabbarSelectedItem == .suggest))
                        .frame(width: 110)
                        .contentShape(Rectangle())
                        .background(viewModel.tabbarSelectedItem == .suggest ? Asset.Assets.bgTabbar.swiftUIImage : nil)
                }
                .frame(width: 110)
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    viewModel.onChageTab(index: 2)
                    withAnimation {
                        viewModel.tabbarSelectedItem = .allCountry
                    }
                } label: {
                    TabBarButton(text: L10n.Login.allCountry, isSelected: .constant(viewModel.tabbarSelectedItem == .allCountry))
                        .frame(width: 110)
                        .contentShape(Rectangle())
                        .background(viewModel.tabbarSelectedItem == .allCountry ? Asset.Assets.bgTabbar.swiftUIImage : nil)
                }
                .frame(width: 110)
                .buttonStyle(PlainButtonStyle())
            }
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
            Spacer()
            bodyItemMenu
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
    }
    
    var bodyItemMenu: some View {
        HStack {
            if viewModel.tabbarSelectedItem == .allCountry {
                TabbarListItemView(listItem: viewModel.listCountry, onTap: { node in
                    viewModel.connect(to: node)
                })
                .transition(.opacity)
            } else if viewModel.tabbarSelectedItem == .recent {
                TabbarListItemView(listItem: viewModel.listRecent, onTap: { node in
                    viewModel.connect(to: node)
                })
                .transition(.opacity)
            } else {
                TabbarListItemView(listItem: viewModel.listSuggest, onTap: { node in
                    viewModel.connect(to: node)
                })
                .transition(.opacity)
            }
        }
    }
    
    var footerMenu: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    viewModel.onQuit()
                } label: {
                    HStack {
                        Asset.Assets.icOff.swiftUIImage
                            .frame(width: sizeIcon, height: sizeIcon)
                        Text(L10n.Login.titleQuit)
                            .font(Font.system(size: 14, weight: .semibold))
                            .foregroundColor(Asset.Colors.mainTextColor.swiftUIColor)
                    }
                }.buttonStyle(PlainButtonStyle())
                Spacer()
                Button {
                    viewModel.onOpenApp()
                } label: {
                    HStack {
                        Asset.Assets.icLogoApp.swiftUIImage
                            .frame(width: sizeIcon, height: sizeIcon)
                        Text("\(L10n.Login.titleOpen) \(L10n.Login.appName)")
                            .font(Font.system(size: 14, weight: .semibold))
                            .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                    }
                }.buttonStyle(PlainButtonStyle())
            }
            .padding(EdgeInsets(top: 25, leading: 30, bottom: 25, trailing: 30))
        }
         
        .background(Color(hexString: "101016").opacity(0.85))
    }
}
 