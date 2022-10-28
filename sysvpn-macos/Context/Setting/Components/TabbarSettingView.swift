//
//  TabbarSettingView.swift
//  sysvpn-macos
//
//  Created by doragon on 27/10/2022.
//

import SwiftUI

enum TabbarSettingType  {
    case general
    case vpnSetting
    case account
    case statistics
    case appearence
    case supportCenter
    
    func toString() -> String{
        switch self {
        case .general:
            return L10n.Global.general
        case .vpnSetting:
            return L10n.Global.vpnSetting
        case .account:
            return L10n.Global.account
        case .statistics:
            return L10n.Global.statistics
        case .appearence:
            return L10n.Global.appearence
        case .supportCenter:
            return L10n.Global.supportCenter
        }
    }
}

struct TabbarSettingItem: Identifiable, Hashable {
    var id = UUID()
    var type: TabbarSettingType
}

struct TabbarSettingView: View {
    @Binding var selectedItem: TabbarSettingType
    
    var listItem: [TabbarSettingItem]
    
    var body: some View {
        bodyMenu
    }
    
    var bodyMenu: some View {
        HStack(spacing: 0) {
            ForEach(listItem, id: \.self) { item in
                Button {
                    withAnimation {
                        selectedItem = item.type
                    }
                } label: {
                    TabBarButton(text: item.type.toString(), isSelected: .constant(selectedItem == item.type))
                        .frame(width: 110)
                        .contentShape(Rectangle())
                        .background(selectedItem == item.type ? Asset.Assets.bgTabbar.swiftUIImage : nil)
                }
                .frame(width: 110)
                .buttonStyle(PlainButtonStyle())
            } 
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }
    
}
 
