//
//  HomeProfileMenuView.swift
//  sysvpn-macos
//
//  Created by doragon on 28/11/2022.
//

import SwiftUI

struct HomeProfileMenuView: View {
    var sizeDot: CGFloat = 4.0
    @StateObject var viewModel = HomeProfileMenuViewModel()
    var onTapCreate: (() -> Void)?
    var onTapMore: (() -> Void)?
    var body: some View {
        VStack(spacing: 10) {
            if viewModel.listShow.isEmpty || viewModel.listShow.isEmpty {
                profileEmptyView
            } else {
                ForEach(viewModel.listShow) { item in
                    ItemProfile(title: item.profileName ?? "")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.connect(to: item.serverId)
                        }
                }
                footerProfile
                    .padding(.top, 10)
            }
        }
        .padding(.horizontal, 16)
    }
    
    var footerProfile: some View {
        HStack(spacing: 10) {
            HStack(alignment: .center, spacing: 2) {
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(.white)
                    .padding(.leading, 26)
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(.white)
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(.white)
                    .padding(.trailing, 26)
            }
            .frame(height: 36)
            .background(Asset.Colors.dividerColor.swiftUIColor)
            .cornerRadius(18)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapMore?()
            }
            
            Button {
                onTapCreate?()
            } label: {
                HStack(spacing: 8) {
                    Asset.Assets.icAdd.swiftUIImage
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text(L10n.Global.createNew)
                        .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                        .font(Font.system(size: 13, weight: .medium))
                }
            }
            .frame(height: 36)
            .buttonStyle(ButtonCTAStyle(bgColor: Asset.Colors.bgButtonColor.swiftUIColor))
        }
    }
    
    var profileEmptyView: some View {
        VStack {
            VStack(spacing: 0) {
                Text(L10n.Global.emptyProfileDesc)
                    .font(Font.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white)
                    .padding(16)
                
                Button {
                    onTapCreate?()
                } label: {
                    HStack(spacing: 8) {
                        Asset.Assets.icAdd.swiftUIImage
                            .resizable()
                            .frame(width: 14, height: 14)
                        Text(L10n.Global.createNew)
                            .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                            .font(Font.system(size: 13, weight: .medium))
                    }
                }
                .frame(height: 36)
                .buttonStyle(ButtonCTAStyle(bgColor: Asset.Colors.bgButtonColor.swiftUIColor))
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .background(Asset.Colors.bgButtonColor.swiftUIColor)
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
        }
    }
}

struct ItemProfile: View {
    var title: String
    var body: some View {
        HStack(spacing: 16) {
            Asset.Assets.icGame.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.leading, 12)
            Text(title)
                .font(Font.system(size: 13, weight: .medium))
                .foregroundColor(Color.white)
                .padding(.trailing, 12)
            
            Spacer()
        }
        .frame(height: 36)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(style: .init(lineWidth: 1.1))
            .foregroundColor(Asset.Colors.dividerColor.swiftUIColor))
    }
}
 