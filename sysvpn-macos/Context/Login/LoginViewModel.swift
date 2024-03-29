//
//  LoginViewModel.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/09/2022.
//

import Foundation
import RxSwift
import SwiftUI
import SwiftyJSON

extension LoginView {
    @MainActor class LoginViewModel: ObservableObject {
        @Published var userName: String = ""
        @Published var password: String = ""
        @Published var isEditingEmail: Bool = false
        @Published var isEditingPassword: Bool = false
        @Published var isRemember: Bool = false
        @Published var isPresentedLoading = false
        @Published var isVerifiedInput = false
        @Environment(\.openURL) private var openURL
        @Published var showAlert = false
        @Published var errorMessage: String = ""

        init() {
            isRemember = AppSetting.shared.isRememberLogin
        }
        
        func onLoginSuccess() {
            AppSetting.shared.isRememberLogin = isRemember
            OpenWindows.MainView.open()
        }
        
        func onTouchSignin() {
            showLoading()
            _ = APIServiceManager.shared.onLogin(email: userName, password: password).subscribe { event in
                switch event {
                case let .success(authenModel):
                    AppDataManager.shared.userData = authenModel.user
                    AppDataManager.shared.accessToken = authenModel.tokens?.access?.token
                    self.onLoginSuccess()
                case let .failure(e):
                    self.hideLoading()
                    guard let error = e as? ResponseError else {
                        self.errorMessage = L10n.Login.tryAgain
                        self.showAlert = true
                        return
                    }
                    self.errorMessage = error.message
                    self.showAlert = true
                }
            }
        }
        
        func showLoading() {
            withAnimation {
                self.isPresentedLoading = true
            }
        }

        func hideLoading() {
            withAnimation {
                self.isPresentedLoading = false
            }
        }
        
        func onTouchForgotPassword() {
            print("Forgot button was tapped:   \(AppSetting.shared.deviceVersion)")
        }
        
        func onTouchCreateAccount() {
            print("Creat new button was tapped")
            if let url = URL(string: "https://www.facebook.com/doragon0") {
                openURL(url)
            }
        }
    
        func onTouchSocialLoginGoogle() {
            print("Google button was tapped")
        }
        
        func onTouchSocialLoginApple() {
            print("Apple button was tapped")
        }
        
        func verifyInputLogin() {
            isVerifiedInput = !userName.isEmpty && !password.isEmpty
        }
    }
}
