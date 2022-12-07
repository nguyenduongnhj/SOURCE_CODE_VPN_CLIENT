//
//  ProfileTabbar.swift
//  sysvpn-macos
//
//  Created by macbook on 20/11/2022.
//

import Foundation
import SwiftUI

struct ProfileTabbarView: View {
    @Binding var index: CGFloat
    var onChangeTab: (() -> Void)?
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { proxy in
                Group {
                    Rectangle().fill(Color.white)
                        .frame(width: (proxy.size.width - 8) / 2)
                        .cornerRadius(15)
                        .offset(x: CGFloat(index) * (proxy.size.width - 8) / 2, y: 0)
                    
                    HStack {
                        Text(L10n.Global.manualStr)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(index == 0 ? Color.black : Asset.Colors.subTextColor.swiftUIColor)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if index == 0 {
                                    return
                                }
                                onChangeTab?()
                                withAnimation {
                                    index = 0
                                }
                            }
                        
                        Text(L10n.Global.profileStr)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(index == 1 ? Color.black : Asset.Colors.subTextColor.swiftUIColor)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if index == 1 {
                                    return
                                }
                                onChangeTab?()
                                withAnimation {
                                    index = 1
                                }
                            }
                    }
                    .frame(height: proxy.size.height - 8)
                }
                .padding(4)
            }
                
        }.background(Asset.Colors.secondary3.swiftUIColor)
            .frame(height: 36)
            .cornerRadius(18)
    }
}
 