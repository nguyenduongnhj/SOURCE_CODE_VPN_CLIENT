//
//  HomeView.swift
//  sysvpn-macos
//
//  Created by doragon on 14/09/2022.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
   
    @EnvironmentObject var appState: GlobalAppStates
    @State var isShowCity = false
    @State var isShowCityAnim = false
    @State var mapSize: CGRect = .zero
    @State var localIsConnected = false
    @State var zoomValue: Double = 1
    @State var isShowMoreScrollTop = true
    
    let pub = NotificationCenter.default
        .publisher(for: .reloadServerStar)
    
    let transitionOpacity = AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .leading)
    ).combined(with: .opacity)
    
    let transitionSlideBootom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom),
        removal: .move(edge: .bottom)
    )
     
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                HomeLeftPanelView(selectedItem: $viewModel.selectedMenuItem, onTouchSetting: {
                    withAnimation {
                        viewModel.selectedMenuItem = .none
                        viewModel.isOpenSetting = true
                    }
                    
                }, onChangeTab: {
                    withAnimation {
                        viewModel.selectedMenuItem = .none
                    }
                }, onTapCreateProfile: {
                    withAnimation {
                        viewModel.isOpenCreateProfile = true
                    }
                }
                )
                .frame(width: 240)
                .contentShape(Rectangle())
                .zIndex(3)
                
                if viewModel.selectedMenuItem != .none {
                    leftMenuPannel.modifier(HomeListWraperView(
                        onClose: {
                            self.viewModel.selectedMenuItem = .none
                        }
                    )
                    )
                    .zIndex(2)
                }
            }.zIndex(3)
            
            if viewModel.selectedMenuItem != .none {
                Rectangle().fill(Color.black).opacity(0.5)
                    .edgesIgnoringSafeArea([.top])
                    .zIndex(2)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            withAnimation {
                                viewModel.selectedMenuItem = .none
                            }
                        }
                    }
            }
            
            ZStack {
                GeometryReader { proxy in
                    VpnMapView(
                        scale: $zoomValue.cgFloat(),
                        size: proxy.size,
                        disableScrollZoom: $viewModel.lookScrollZoom
                    )
                }
                .clipped()
                .contentShape(Rectangle())
                .edgesIgnoringSafeArea([.top])
                mapUILayerView
            }
            .padding(.leading, 240)
            
            popupDialog
            
        }.frame(minWidth: 1200, minHeight: 700)
            .onAppear {
                localIsConnected = appState.displayState == .connected
                viewModel.onViewAppear()
            }
            .onDisappear {
                print("Home onDisappear")
            }
            .onChange(of: appState.displayState) { newValue in
                withAnimation {
                    localIsConnected = newValue == .connected
                }
                DispatchQueue.main.async {
                    if appState.displayState == .connected || appState.displayState == .disconnected {
                        viewModel.getListCountry()
                    }
                }
            }
            .onChange(of: viewModel.selectedMenuItem) { _ in
                // viewModel.onChangeState()
                if viewModel.selectedMenuItem != .none && viewModel.isOpenSetting {
                    viewModel.isOpenSetting = false
                }
                
                if viewModel.selectedMenuItem != .none && viewModel.isShowPopupLogout {
                    viewModel.isShowPopupLogout = false
                }
            }
    }
}
