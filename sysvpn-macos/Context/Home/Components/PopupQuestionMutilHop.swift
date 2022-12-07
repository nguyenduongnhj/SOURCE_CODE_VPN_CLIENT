//
//  PopupQuestionMutilHop.swift
//  sysvpn-macos
//
//  Created by doragon on 25/11/2022.
//

import SwiftUI

struct PopupQuestionMutilHop: View {
    var onCancel: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(L10n.Global.whatIsMultihop)
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 16, weight: .semibold))
                    .padding(.top, 30)
                 
                Text(L10n.Global.whatIsMultihop)
                    .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                    .font(Font.system(size: 13, weight: .regular))
                    .padding(EdgeInsets(top: 12, leading: 32, bottom: 0, trailing: 32))
            
                Button {
                    onCancel?()
                } label: {
                    Text(L10n.Global.cancel)
                        .foregroundColor(Color.white)
                        .font(Font.system(size: 13, weight: .semibold))
                }.buttonStyle(LoginButtonCTAStyle(bgColor: Asset.Colors.buttonCancelColor.swiftUIColor))
                    .frame(width: 110, height: 40)
                    .padding(16)
            }
            .contentShape(Rectangle())
            .background(Asset.Colors.bodySettingColor.swiftUIColor)
        }
        .cornerRadius(16)
        .frame(width: 400, height: 200, alignment: .center)
        .frame(minWidth: 10, maxWidth: 350)
    }
}
 