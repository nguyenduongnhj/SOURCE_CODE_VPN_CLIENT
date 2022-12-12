//
//  LoginView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/09/2022.
//

import Foundation
import PopupView
import SwiftUI

private enum Field: Int, Hashable {
    case username, password
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusState: Field?
    
    private let contentHorizontalMargin: EdgeInsets = .init(top: 0, leading: 60, bottom: 0, trailing: 60)
    private let socialIconSize: CGFloat = 20
    private let inputSpacing: CGFloat = 16
    private let paddingTop: CGFloat = 48
    
    var formInput: some View {
        VStack {
            Spacer().frame(height: paddingTop)
            TextField(L10n.Login.yourEmail, text: $viewModel.userName)
                .disableAutocorrection(true)
                .textFieldStyle(LoginInputTextFieldStyle(focused: $viewModel.isEditingEmail))
                .focused($focusState, equals: .username)
                
                .textContentType(nil)
            
            Spacer().frame(height: inputSpacing)
            SecureField(L10n.Login.password, text: $viewModel.password)
                .textFieldStyle(LoginInputTextFieldStyle(focused: $viewModel.isEditingPassword))
                .focused($focusState, equals: .password)
                .textContentType(nil)
                .focusable()
            Spacer().frame(height: 34)
        }
    }
    
    var socialLogin: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.onTouchSocialLoginGoogle()
            } label: {
                Asset.Assets.icGoogle.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: socialIconSize, height: socialIconSize)
                Text(L10n.Login.signInWithGoogle)
            }.buttonStyle(LoginButtonNoBackgroundStyle())
            Spacer()
            Divider().frame(height: 24)
            Spacer()
            Button {
                viewModel.onTouchSocialLoginApple()
            } label: {
                Asset.Assets.icApple.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: socialIconSize, height: socialIconSize)
                Text(L10n.Login.signInWithApple)
            }.buttonStyle(LoginButtonNoBackgroundStyle())
        }
    }
    
    /* var formHeader: some View {
         VStack {
             Asset.Assets.logo.swiftUIImage
                 .padding(.top, paddingTop)
             Text(L10n.Login.sologan)
                 .lineLimit(nil)
                 .font(Font.system(size: 16))
                 .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                 .font(.body)
                 .padding(.top, 14)
         }
     } */
    
    var formHeader: some View {
        VStack(alignment: .leading) {
            Text(L10n.Login.welcomeBack)
                .font(Font.system(size: 24))
                .padding(.bottom, 6)
            
            Text(L10n.Login.sologan)
                .lineLimit(nil)
                .font(Font.system(size: 14))
                .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                .font(.body)
        }
    }
    
    var createAccountArea: some View {
        VStack {
            Text(L10n.Login.dontHaveAnAccount).foregroundColor(Asset.Colors.subTextColor.swiftUIColor).padding(.bottom, 4)
            Button {
                viewModel.onTouchCreateAccount()
            } label: {
                Text(L10n.Login.createNew)
            }.buttonStyle(LoginButtonNoBackgroundStyle())
        }
    }
    
    var formFooter: some View {
        HStack(alignment: .center) {
            /* Button {
                 viewModel.isRemember = !viewModel.isRemember
             } label: {
                 if viewModel.isRemember { Asset.Assets.icCheckChecked.swiftUIImage
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(width: socialIconSize, height: socialIconSize)
                 } else {
                     Asset.Assets.icCheckNormal.swiftUIImage
                         .resizable()
                         .aspectRatio(contentMode: .fit)
                         .frame(width: socialIconSize, height: socialIconSize)
                 }
                 Text(L10n.Login.rememberLogin)
             }.buttonStyle(LoginButtonNoBackgroundStyle()) */
            Spacer()
            Button {
                viewModel.onTouchForgotPassword()
            } label: {
                Text(L10n.Login.forgotPassword)
            }.buttonStyle(LoginButtonNoBackgroundStyle())
        }.padding(.bottom, 40)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            LoginBannerView()
                .frame(maxWidth: CGFloat.infinity)
            bodyLogin
                .frame(width: 460)
        }
        .ignoresSafeArea()
        .frame(minWidth: 1200, minHeight: 700)
    }
    
    var bodyLogin: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: paddingTop)
                formHeader
                    .padding(contentHorizontalMargin)
                VStack(alignment: .center) {
                    formInput
                    formFooter
                    Button {
                        viewModel.onTouchSignin()
                    } label: {
                        Text(L10n.Login.signIn)
                    }.buttonStyle(LoginButtonCTAStyle())
                        .environment(\.isEnabled, viewModel.isVerifiedInput)
                    Spacer().frame(height: 32)
                    socialLogin
                    Spacer().frame(height: 40)
                    createAccountArea
                    Spacer()
                }
                .padding(contentHorizontalMargin)
            }
            .background(Asset.Colors.backgroundColor.swiftUIColor)
            .foregroundColor(Color.white)
            .font(Font.system(size: 14))
            
            LoginLoadingView(isShowing: $viewModel.isPresentedLoading)
        }
        .popup(isPresented: $viewModel.showAlert,
               type: .floater(verticalPadding: 0),
               position: .bottom,
               animation: .easeInOut,
               autohideIn: 10,
               closeOnTap: false,
               closeOnTapOutside: true) {
            AppAlertView(type: .error, message: viewModel.errorMessage)
        }
        .onChange(of: focusState) { newValue in
            viewModel.isEditingPassword = newValue == .password
            viewModel.verifyInputLogin()
        }.onChange(of: focusState) { newValue in
            viewModel.isEditingEmail = newValue == .username
        }.onChange(of: viewModel.userName) { _ in
            viewModel.verifyInputLogin()
        }.onChange(of: viewModel.password) { _ in
            viewModel.verifyInputLogin()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification), perform: { _ in
            NSApp.mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
        })
        .onAppear {
            viewModel.onViewAppear()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .frame(minWidth: 1200, minHeight: 700)
    }
}
