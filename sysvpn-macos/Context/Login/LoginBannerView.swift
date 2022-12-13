//
//  LoginBannerView.swift
//  sysvpn-macos
//
//  Created by macbook on 05/11/2022.
//

import Foundation
import SwiftUI

struct LoginBannerView: View {
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle().fill(.radialGradient(colors: [Color(rgb: 0x2D6AB6), Color(rgb: 0x124B92)], center: .center, startRadius: .zero, endRadius: 500))
            
            Asset.Assets.logo.swiftUIImage
                .resizable()
                .frame(width: 80, height: 80)
                .position(x: 80, y: 72)
            
            VStack {
                Asset.Assets.introImage.swiftUIImage
                Text("Welcome to Doragon VPN")
                    .font(.system(size: 24, weight: .semibold))
            }
        }
    }
}

struct LoginBannerView_Previews: PreviewProvider {
    static var previews: some View {
        LoginBannerView()
            .frame(minWidth: 500, minHeight: 500)
    }
}
