//
//  HomeListProfileView.swift
//  sysvpn-macos
//
//  Created by doragon on 29/11/2022.
//

import SwiftUI

struct HomeListProfileView: View {
    @StateObject var viewModel = HomeListProfileViewModel()
//    var listProfile: [HomeListProfileModel]
    var onTapCreate: (() -> Void)?
    var onTapRename: ((_ item: UserProfileTemp) -> Void)?
    var onTapChangeLocation: ((_ item: UserProfileTemp) -> Void)?
    var onClose: (() -> Void)?
    var onTapItem: ((_ item: UserProfileTemp) -> Void)?
    
    var listFilter: [HomeListProfileModel] {
        if viewModel.textInput.isEmpty {
            return viewModel.listProfile
        } else {
            return viewModel.listProfile.filter { item in
                return item.title.localizedCaseInsensitiveContains(viewModel.textInput)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            headerListProfile
            Spacer().frame(height: 24)
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(listFilter) { item in
                        Group {
                            switch item.type {
                            case .spacing:
                                Spacer().frame(height: 30)
                            case .body:
                                HomeItemProfile(
                                    title: item.title,
                                    isShowPopover: viewModel.indexSelect == item.id,
                                    onTapMore: {
                                        viewModel.indexSelect = item.id
                                    },
                                    onSetlocation: {
                                        if let data = item.profileDetail as? UserProfileTemp {
                                            onTapChangeLocation?(data)
                                        }
                                    },
                                    onPickToTop: {
                                        viewModel.pickToTop(item.id)
                                    },
                                    onRename: {
                                        if let data = item.profileDetail as? UserProfileTemp {
                                            onTapRename?(data)
                                        }
                                    },
                                    onDelete: {
                                        viewModel.deleteProfile(item.id)
                                        if viewModel.listProfile.isEmpty {
                                            onClose?()
                                        }
                                    }
                                )
                                .onTapGesture {
                                    if let data = item.profileDetail as? UserProfileTemp {
                                        onTapItem?(data)
                                    }
                                }
                            case .header:
                                VStack {
                                    Text(item.title)
                                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                                        .font(Font.system(size: 12, weight: .regular))
                                    Spacer().frame(height: 20)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    var headerListProfile: some View {
        HStack(spacing: 16) {
            SearchInputView(textInput: $viewModel.textInput)
                .padding(.top, 2)
            HStack(spacing: 8) {
                Asset.Assets.icAdd.swiftUIImage
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(L10n.Global.create)
                    .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                    .font(Font.system(size: 13, weight: .medium))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // add new
                onTapCreate?()
            }
        }
    }
}

struct HomeItemProfile: View {
    var sizeDot: CGFloat = 4.0
    var title: String
    @State var isShowPopover: Bool = false
    var onTapMore: (() -> Void)?
    var onSetlocation: @MainActor () -> Void
    var onPickToTop: @MainActor () -> Void
    var onRename: @MainActor () -> Void
    var onDelete: @MainActor () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Asset.Assets.icGame.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
            Text(title)
                .font(Font.system(size: 13, weight: .medium))
                .foregroundColor(Color.white)
            Spacer()
            HStack(alignment: .center, spacing: 2) {
                Spacer()
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(isShowPopover ? Asset.Colors.primaryColor.swiftUIColor : .white)
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(isShowPopover ? Asset.Colors.primaryColor.swiftUIColor : .white)
                Circle()
                    .frame(width: sizeDot, height: sizeDot)
                    .foregroundColor(isShowPopover ? Asset.Colors.primaryColor.swiftUIColor : .white)
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapMore?()
                isShowPopover = true
            }
            .popover(isPresented: $isShowPopover, arrowEdge: .trailing, content: {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        HStack(alignment: .center, spacing: 10) {
                            Asset.Assets.icPickLocationSm.swiftUIImage
                                .resizable()
                                .frame(width: 14, height: 14)
                            Text(L10n.Global.setLocation)
                                .font(Font.system(size: 13, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSetlocation()
                            isShowPopover = false
                        }
                        HStack(alignment: .center, spacing: 10) {
                            Asset.Assets.icArrowToTop.swiftUIImage
                                .resizable()
                                .frame(width: 14, height: 14)
                            Text(L10n.Global.pickToTop)
                                .font(Font.system(size: 13, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onPickToTop()
                            isShowPopover = false
                        }
                        HStack(alignment: .center, spacing: 10) {
                            Asset.Assets.icWrite.swiftUIImage
                                .resizable()
                                .frame(width: 14, height: 14)
                            Text(L10n.Global.rename)
                                .font(Font.system(size: 13, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onRename()
                            isShowPopover = false
                        }
                        HStack(alignment: .center, spacing: 10) {
                            Asset.Assets.icTrash.swiftUIImage
                                .resizable()
                                .frame(width: 14, height: 14)
                            Text(L10n.Global.deleteProfile)
                                .font(Font.system(size: 13, weight: .regular))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onDelete()
                            isShowPopover = false
                        }
                    }
                    .padding(.leading, 16)
                }
                .frame(width: 160, height: 180)
                .background(Asset.Colors.popoverBgColor.swiftUIColor)
            })
        }
        .frame(height: 44)
    }
}

enum HomeListProfileModelType {
    case header
    case body
    case spacing
}

struct HomeListProfileModel: Identifiable, Equatable {
    static func == (lhs: HomeListProfileModel, rhs: HomeListProfileModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = UUID()
    var type: HomeListProfileModelType
    var title: String = ""
    var imageUrl: String?
    var profileDetail: UserProfileProtocol?
}
 