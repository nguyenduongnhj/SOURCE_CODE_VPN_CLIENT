//
//  HomeMenuButtonView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 30/09/2022.
//

import Foundation
import SwiftUI

struct HomeMenuButtonView : View {
    var iconSize: CGFloat = 32
    var titleSpacing: CGFloat = 24
    var active: Bool = true
    var icon: Image? = Asset.Assets.icLocation.swiftUIImage
    var title: String = "Button Title"
    var content: String = "Button description"
    var padding: EdgeInsets = EdgeInsets(top: 18, leading: 30, bottom: 18, trailing: 30)
    var activeColor: Color = Asset.Colors.primaryColor.swiftUIColor
    var normalColor: Color = Color.white
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                icon?.resizable()
                    .foregroundColor( active ? activeColor : normalColor)
                    .frame(width: iconSize, height: iconSize)
                Spacer().frame(width: titleSpacing)
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor( active ? activeColor : normalColor)
                        .font(Font.system(size: 16, weight: .bold))
                    Spacer().frame(height: 4)
                    Text(content)
                        .font(Font.system(size: 14, weight: .regular))
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                }
            }.padding(padding)
                .background {
                    if (active) {
                        HStack(spacing: 0){
                            Rectangle().foregroundColor( Asset.Colors.primaryColor.swiftUIColor).frame(width:4)
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [
                                        Asset.Colors.mainLinearStartColor.swiftUIColor,
                                        Asset.Colors.mainLinearEndColor.swiftUIColor
                                    ], startPoint: UnitPoint.leading, endPoint: UnitPoint(x: 0.3, y: 0.5))
                                )
                        }.contentShape(Rectangle())
                            .transition(AnyTransition.asymmetric(
                                insertion: .move(edge: .leading),
                                removal: .move(edge: .leading)
                            ))
                    } else {
                        Rectangle().foregroundColor( Asset.Colors.backgroundColor.swiftUIColor)
                    }
                }
        }
    }
}

struct HomeMenuButtonView_Previews: PreviewProvider {
    static var previews: some View {
        HomeMenuButtonView()
    }
}
