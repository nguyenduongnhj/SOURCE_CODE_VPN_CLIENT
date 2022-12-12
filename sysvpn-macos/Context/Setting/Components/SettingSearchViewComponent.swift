//
//  SettingSelectViewComponent.swift
//  sysvpn-macos
//
//  Created by doragon on 28/10/2022.
//

import Kingfisher
import Network
import SwiftUI

struct SettingSearchViewComponent: View {
    var selectItem: SettingElementType
    @State private var isShowingPopover = false
    @State var valueSelect: CountryAvailables?
    var onChangeValue: @MainActor (_ value: CountryAvailables) -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(selectItem.settingName)
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 14, weight: .semibold))
                    .padding(.bottom, 2)
                if selectItem.settingDesc != nil {
                    Text(selectItem.settingDesc!)
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        .font(Font.system(size: 13, weight: .regular))
                }
            }
            Spacer()
            if let data = selectItem as? SelectSettingItem<CountryAvailables> {
                HStack(spacing: 10) {
                    if let image = valueSelect?.image {
                        image
                            .resizable()
                            .frame(width: 24, height: 24)
                            .cornerRadius(12)
                    } else {
                        Asset.Assets.icFlagEmpty.swiftUIImage
                            .resizable()
                            .frame(width: 24, height: 24)
                            .cornerRadius(12)
                    }
                    
                    Text(valueSelect?.name ?? L10n.Global.noset)
                        .foregroundColor(Color.white)
                        .font(Font.system(size: 13, weight: .regular))
                }
                .onTapGesture {
                    self.isShowingPopover = true
                }
                .popover(isPresented: $isShowingPopover, arrowEdge: .bottom, content: {
                    SearchPopoverView(listItem: data.settingData ?? [], itemSelect: $valueSelect, onChangeValue: { itemSelect in
                        self.isShowingPopover = false
                        onChangeValue(itemSelect)
                    }, settingType: selectItem)
                })
            }
        }
        .padding(.vertical, 15)
    }
}

struct SearchPopoverView: View {
    var listItem: [CountryAvailables]
    @Binding var itemSelect: CountryAvailables?
    var onChangeValue: @MainActor (_ value: CountryAvailables) -> Void
    var settingType: SettingElementType
    @State var textInput: String = ""
    
    var listFilter: [CountryAvailables] {
        if textInput.isEmpty {
            return listItem
        } else {
            return listItem.filter { item in
                return item.name?.localizedCaseInsensitiveContains(textInput) ?? false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            SearchInputView(textInput: $textInput, frameHeight: 46)
                .padding(15)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    if listFilter.isEmpty {
                        Text(L10n.Global.searchEmptyStr)
                            .font(Font.system(size: 14, weight: .semibold))
                            .padding(.leading, 16)
                    } else {
                        ForEach(listFilter) { item in
                            HStack(spacing: 10) {
                                Spacer().frame(width: 6)
                                if let image = item.image {
                                    image
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .cornerRadius(12)
                                } else {
                                    Asset.Assets.icFlagEmpty.swiftUIImage
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .cornerRadius(12)
                                }
                                Text(item.name ?? "")
                                    .foregroundColor(Color.white)
                                    .font(Font.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                itemSelect = item
                                onChangeValue(item)
                            }
                            .frame(height: 40)
                            .background(item.name == itemSelect?.name ? Asset.Colors.popoverBgSelected.swiftUIColor : Asset.Colors.popoverBgColor.swiftUIColor)
                        }
                    }
                    Spacer()
                }
            }
            .frame(width: 260, height: 400)
            .background(Asset.Colors.popoverBgColor.swiftUIColor)
        }
        .background(Asset.Colors.popoverBgColor.swiftUIColor)
    }
}
