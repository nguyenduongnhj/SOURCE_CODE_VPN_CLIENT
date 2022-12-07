//
//  HomeViewProto.swift
//  sysvpn-macos
//
//  Created by macbook on 26/11/2022.
//

import Foundation
import SwiftUI

extension HomeView {
    var tooltipScrollDown: some View {
        VStack {
            Spacer()
            HStack {
                Text(L10n.Global.alertScrollToShowMore)
                    .padding(10)
            }
            .background(Color.black)
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.isShowMoreScrollTop = false
            }
        }
    }
    
    var leftMenuPannel: some View {
        ZStack {
            if viewModel.selectedMenuItem != .none {
                if viewModel.selectedMenuItem == .manualConnection {
                    HomeListCountryNodeView(
                        selectedItem: viewModel.selectedMenuItem,
                        countries: viewModel.listCountry,
                        isShowCity: isShowCity,
                        countrySelected: viewModel.countrySelected,
                        onTouchItem: { item in
                            viewModel.connect(to: item)
                        },
                        onDetailCountry: { item in
                            viewModel.countrySelected = item
                            viewModel.onChangeCountry(item: item)
                            isShowCity = true
                        }
                    )
                    .transition(transitionOpacity)
                    .overlay {
                        if isShowMoreScrollTop {
                            tooltipScrollDown
                        }
                    }
                    
                    HomeDetailCityNodeView(
                        selectedItem: viewModel.selectedMenuItem,
                        listCity: viewModel.listCity,
                        isShowCity: isShowCity,
                        countryItem: viewModel.countrySelected,
                        onTouchItem: { item in
                            self.viewModel.connect(to: item)
                        },
                        onBack: {
                            self.isShowCity = false
                        }
                    )
                    .transition(transitionOpacity)
                    .offset(x: isShowCityAnim ? 0 : 330, y: 0)
                    .opacity(isShowCityAnim ? 1 : 0)
                    
                } else if viewModel.selectedMenuItem == .staticIp {
                    HomeListCountryNodeView(
                        selectedItem: viewModel.selectedMenuItem,
                        countries: viewModel.listStaticServer,
                        isShowCity: isShowCity,
                        countrySelected: viewModel.countrySelected,
                        onTouchItem: { item in
                            self.viewModel.connect(to: item)
                        }
                    )
                    .transition(transitionOpacity)
                    .onReceive(pub) { _ in
                        if viewModel.selectedMenuItem == .staticIp {
                            viewModel.getListStaticServer(firstLoadData: false)
                        }
                    }
                } else if viewModel.selectedMenuItem == .multiHop {
                    HomeListCountryNodeView(
                        selectedItem: viewModel.selectedMenuItem,
                        countries: viewModel.listMultiHop,
                        isShowCity: isShowCity,
                        countrySelected: viewModel.countrySelected,
                        onTouchItem: { item in
                            self.viewModel.connect(to: item)
                            withAnimation {
                                viewModel.selectedMenuItem = .none
                            }
                        }, onTouchQuestion: {
                            viewModel.isShowPopupQuestion = true
                        }
                    )
                } else if viewModel.selectedMenuItem == .profile {
                    HomeListProfileView(onTapCreate: {
                        viewModel.isEditLocation = false
                        withAnimation {
                            viewModel.isOpenCreateProfile = true
                        }
                    }, onTapRename: { item in
                        viewModel.itemProfileEdit = item
                        withAnimation {
                            viewModel.isShowRenameProfile = true
                        }
                    }, onTapChangeLocation: { item in
                        viewModel.itemProfileEdit = item
                        viewModel.isEditLocation = true
                        withAnimation {
                            viewModel.isOpenCreateProfile = true
                        }
                    }, onClose: {
                        withAnimation {
                            viewModel.selectedMenuItem = .none
                        }
                    }) { item in
                        guard let id = item.serverId else {
                            return
                        }
                        self.viewModel.connect(to: AppDataManager.shared.getNodeByCountryId(countryId: id))
                        withAnimation {
                            viewModel.selectedMenuItem = .none
                        }
                    }
                }
            }
        }
        .clipped()
        .onChange(of: isShowCity) { value in
            withAnimation {
                isShowCityAnim = value
            }
        }
    }
    
    var mapUILayerView: some View {
        ZStack {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [
                                Asset.Colors.mainBackgroundColor.swiftUIColor,
                                Asset.Colors.mainLinearEndColor.swiftUIColor
                            ], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom)
                        ).frame(height: 100)
                    Text(L10n.Global.locationMap)
                        .font(.system(size: 18, weight: .thin))
                }
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(colors: [
                            Asset.Colors.mainLinearEndColor.swiftUIColor,
                            Asset.Colors.backgroundColor.swiftUIColor
                        ], startPoint: UnitPoint.top, endPoint: UnitPoint.bottom)
                    ).frame(height: 200)
            }
            .allowsHitTesting(false)
            VStack {
                HStack {
                    Spacer()
                    HomeZoomSliderView(value: $zoomValue, step: 0.1, sliderRange: 1...2)
                        .frame(width: 112, height: 24, alignment: .center)
                    Spacer().frame(width: 16)
                }
                .frame(height: 100)
                Spacer()
                if localIsConnected {
                    HomeTrafficMonitorView()
                        .padding(.horizontal, 50)
                        .padding(.bottom, 30)
                        .transition(transitionSlideBootom)
                } else {
                    HomeAlertConnectionView()
                        .transition(transitionSlideBootom)
                }
            }
        }
        .edgesIgnoringSafeArea([.top])
    }
    
    var popupDialog: some View {
        Group {
            if viewModel.isOpenSetting {
                ZStack {
                    Rectangle().fill(Color.black).opacity(0.5)
                        .edgesIgnoringSafeArea([.top])
                        .onTapGesture {
                            withAnimation {
                                viewModel.isOpenSetting = false
                            }
                        }
                    SettingView(onClose: {
                                    withAnimation {
                                        viewModel.isOpenSetting = false
                                    }
                                },
                                onTapLogout: {
                                    withAnimation {
                                        viewModel.selectedMenuItem = .none
                                        viewModel.isOpenSetting = false
                                        viewModel.isShowPopupLogout = true
                                    }
                                })
                }.zIndex(4)
            } else if viewModel.isShowPopupLogout {
                ZStack {
                    Rectangle().fill(Color.black).opacity(0.5)
                        .edgesIgnoringSafeArea([.top])
                        .onTapGesture {
                            withAnimation {
                                viewModel.isShowPopupLogout = false
                            }
                        }
                    PopupConfirmSignOutView(
                        onCancel: {
                            withAnimation {
                                viewModel.isShowPopupLogout = false
                                viewModel.isOpenSetting = true
                            }
                        }, onLogout: {
                            viewModel.onSignOut()
                            viewModel.isShowPopupLogout = false
                        }
                    )
                }.zIndex(4)
            } else if viewModel.isShowPopupQuestion {
                ZStack {
                    Rectangle().fill(Color.black).opacity(0.5)
                        .edgesIgnoringSafeArea([.top])
                        .onTapGesture {
                            withAnimation {
                                viewModel.isShowPopupQuestion = false
                            }
                        }
                    PopupQuestionMutilHop(
                        onCancel: {
                            withAnimation {
                                viewModel.isShowPopupQuestion = false
                            }
                        }
                    )
                }.zIndex(4)
            } else if viewModel.isOpenCreateProfile {
                ZStack {
                    Rectangle().fill(Color.black).opacity(0.5)
                        .edgesIgnoringSafeArea([.top])
                        .onTapGesture {
                            withAnimation {
                                viewModel.isOpenCreateProfile = false
                            }
                        }
                    ProfileSelectLocationView(onCancel: {
                        withAnimation {
                            viewModel.isOpenCreateProfile = false
                        }
                    }, isEdit: viewModel.isEditLocation, itemEdit: viewModel.itemProfileEdit, serverId: viewModel.itemProfileEdit?.serverId ?? 0)
                }.zIndex(4)
            } else if viewModel.isShowRenameProfile {
                ZStack {
                    Rectangle().fill(Color.black).opacity(0.5)
                        .edgesIgnoringSafeArea([.top])
                        .onTapGesture {
                            withAnimation {
                                viewModel.isShowRenameProfile = false
                            }
                        }
                    RenameProfileComponent(itemEdit: viewModel.itemProfileEdit, profileInput: viewModel.itemProfileEdit?.profileName ?? "", onCancel: {
                        withAnimation {
                            viewModel.isShowRenameProfile = false
                        }
                    })
                }.zIndex(4)
            }
        }
    }
}
