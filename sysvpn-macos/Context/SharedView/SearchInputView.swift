//
//  SearchInputView.swift
//  sysvpn-macos
//
//  Created by doragon on 29/11/2022.
//

import SwiftUI

struct SearchInputView: View {
    @Binding var textInput: String
    var frameHeight: CGFloat = 40
    var borderColor: Color = Asset.Colors.subTextColor.swiftUIColor
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 12)
            Asset.Assets.icSearch.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
            Spacer().frame(width: 12)
            TextField(L10n.Global.searchStr, text: $textInput)
                .textFieldStyle(PlainTextFieldStyle())
            Spacer().frame(width: 12)
        }
        .frame(height: frameHeight)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(style: .init(lineWidth: 1.2))
            .foregroundColor(borderColor))
    }
}
 