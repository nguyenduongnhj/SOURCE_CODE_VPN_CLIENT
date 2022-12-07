//
//  ProfileSelectLocationView.swift
//  sysvpn-macos
//
//  Created by doragon on 29/11/2022.
//

import SwiftUI

struct ProfileSelectLocationView: View {
    var onCancel: (() -> Void)?
    var isEdit: Bool = false
    @StateObject var viewModel = ProfileSelectLocationViewModel()
    
    @State var itemEdit: UserProfileTemp?
    @State var serverId: Int = 0
    
    private let adaptiveColums = [
        GridItem(.adaptive(minimum: 120))
    ]
    
    var listFilter: [CountryAvailables] {
        if viewModel.searchInput.isEmpty {
            return viewModel.listCountry
        } else {
            return viewModel.listCountry.filter { item in
                return item.name?.localizedCaseInsensitiveContains(viewModel.searchInput) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !isEdit {
                profileInputItem
            }
            searchItem
            listItemCountry
                .frame(height: viewModel.isShowErrorEmptyCountry ? 240 : 230)
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
                    if isEdit {
                        if GlobalAppStates.shared.listProfile.isEmpty {
                            AppDataManager.shared.readListProfile()
                        }
                        let profile = GlobalAppStates.shared.listProfile
                        
                        itemEdit?.serverId = serverId
                        
                        let index = profile.firstIndex { item in
                            return item.id == itemEdit?.id
                        } ?? 0
                        
                        GlobalAppStates.shared.listProfile[index] = itemEdit!
                        AppDataManager.shared.saveProfile()
                        onCancel?()
                    } else {
                        viewModel.onCreate(serverId: serverId, onComplete: {
                            onCancel?()
                        })
                    }
                   
                } label: {
                    Text(isEdit ? L10n.Global.select : L10n.Global.create)
                        .foregroundColor(.black)
                        .font(Font.system(size: 13, weight: .semibold))
                }
                .frame(height: 40)
                .buttonStyle(ButtonCTAStyle(bgColor: Asset.Colors.primaryColor.swiftUIColor, radius: 6))
            }
        }
        .padding(32)
        .frame(width: 470, height: isEdit ? 470 : viewModel.isShowErrorEmptyName ? 600 : 580)
        .background(Asset.Colors.bodySettingColor.swiftUIColor)
        .cornerRadius(16)
    }
    
    var profileInputItem: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Global.createNewProfile)
                .foregroundColor(.white)
                .font(Font.system(size: 16, weight: .semibold))
                .padding(.bottom, 12)
            HStack(spacing: 0) {
                Spacer().frame(width: 20)
                TextField(L10n.Global.profileName, text: $viewModel.profileInput)
                    .textFieldStyle(PlainTextFieldStyle())
                Spacer().frame(width: 20)
            }
            .frame(height: 50)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(style: .init(lineWidth: 1.2))
                .foregroundColor(Asset.Colors.borderColor.swiftUIColor))
            if viewModel.isShowErrorEmptyName {
                Text(L10n.Global.profileEmpty)
                    .foregroundColor(Asset.Colors.textErrorColor.swiftUIColor)
                    .font(Font.system(size: 13, weight: .regular))
            }
        }
    }
    
    var searchItem: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isEdit {
                Text(L10n.Global.setLocation)
                    .foregroundColor(.white)
                    .font(Font.system(size: 16, weight: .semibold))
                SearchInputView(textInput: $viewModel.searchInput, borderColor: Asset.Colors.borderColor.swiftUIColor)
                    .padding(.top, 2)
            } else {
                Text(L10n.Global.selectLocation)
                    .foregroundColor(.white)
                    .font(Font.system(size: 14, weight: .regular))
                SearchInputView(textInput: $viewModel.searchInput, borderColor: Asset.Colors.borderColor.swiftUIColor)
                    .padding(.top, 2)
            }
        }
    }
    
    var listItemCountry: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: adaptiveColums, alignment: .leading, spacing: 16) {
                    ForEach(listFilter) { item in
                        HStack(spacing: 0) {
                            if item.image != nil {
                                item.image!
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .cornerRadius(14)
                                    .padding(8)
                            } else {
                                Asset.Assets.icFlagEmpty.swiftUIImage
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .cornerRadius(14)
                            }
                            Text(item.name ?? "")
                                .foregroundColor(Color.white)
                                .font(Font.system(size: 12, weight: .regular))
                            Spacer()
                        }
                        .frame(width: 128)
                        .background(item.id == serverId ? Asset.Colors.popoverBgSelected.swiftUIColor : .clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            serverId = item.id ?? 0
                        }
                    }
                }
            }
            if viewModel.isShowErrorEmptyCountry {
                Text(L10n.Global.countryEmpty)
                    .foregroundColor(Asset.Colors.textErrorColor.swiftUIColor)
                    .font(Font.system(size: 13, weight: .regular))
            }
        }
    }
}
 