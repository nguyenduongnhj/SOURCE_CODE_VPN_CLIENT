//
//  RenameProfileComponent.swift
//  sysvpn-macos
//
//  Created by doragon on 02/12/2022.
//

import SwiftUI

struct RenameProfileComponent: View {
    @State var itemEdit: UserProfileTemp?
    @State var profileInput: String = ""
    @State var isShowErrorEmptyName: Bool = false
    
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                profileInputItem
            
                HStack(spacing: 16) {
                    Button {
                        onCancel?()
                    } label: {
                        Text(L10n.Global.cancel)
                            .foregroundColor(.white)
                            .font(Font.system(size: 13, weight: .semibold))
                    }
                    .frame(height: 40)
                    .buttonStyle(ButtonCTAStyle(bgColor: Asset.Colors.popoverBgSelected.swiftUIColor, radius: 6))
                     
                    Button {
                        if profileInput.isEmpty || profileInput == "" {
                            isShowErrorEmptyName = true
                        } else {
                            isShowErrorEmptyName = false
                            
                            if GlobalAppStates.shared.listProfile.isEmpty {
                                AppDataManager.shared.readListProfile()
                            }
                            let profile = GlobalAppStates.shared.listProfile
                            
                            itemEdit?.profileName = profileInput
                            
                            let index = profile.firstIndex { item in
                                return item.id == itemEdit?.id
                            } ?? 0
                            
                            GlobalAppStates.shared.listProfile[index] = itemEdit!
                            AppDataManager.shared.saveProfile()
                            onCancel?()
                        }
                    } label: {
                        Text(L10n.Global.rename)
                            .foregroundColor(.black)
                            .font(Font.system(size: 13, weight: .semibold))
                    }
                    .frame(height: 40)
                    .buttonStyle(ButtonCTAStyle(bgColor: Asset.Colors.primaryColor.swiftUIColor, radius: 6))
                }
            }
            .padding(32)
            .contentShape(Rectangle())
            .background(Asset.Colors.bodySettingColor.swiftUIColor)
        }
        .cornerRadius(16)
        .frame(width: 450, height: 230, alignment: .center)
        .frame(minWidth: 10, maxWidth: 450)
    }
    
    var profileInputItem: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Global.renameProfile)
                .foregroundColor(.white)
                .font(Font.system(size: 16, weight: .semibold))
                .padding(.bottom, 12)
            HStack(spacing: 0) {
                Spacer().frame(width: 20)
                TextField(L10n.Global.profileName, text: $profileInput)
                    .textFieldStyle(PlainTextFieldStyle())
                Spacer().frame(width: 20)
            }
            .frame(height: 50)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(style: .init(lineWidth: 1.2))
                .foregroundColor(Asset.Colors.borderColor.swiftUIColor))
            if isShowErrorEmptyName {
                Text(L10n.Global.profileEmpty)
                    .foregroundColor(Asset.Colors.textErrorColor.swiftUIColor)
                    .font(Font.system(size: 13, weight: .regular))
            }
        }
    }
}
 