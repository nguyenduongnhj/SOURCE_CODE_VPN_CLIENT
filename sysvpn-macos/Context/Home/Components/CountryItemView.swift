//
//  CountryItemView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 02/10/2022.
//

import Foundation
import Kingfisher
import SwiftUI
struct CountryItemView: View {
    var countryName: String
    var imageUrl: String?
    var totalCity: Int
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if imageUrl != nil {
                KFImage(URL(string: imageUrl!))
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            } else {
                Asset.Assets.icFlagEmpty.swiftUIImage
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            }
            VStack(alignment: .leading) {
                Text(countryName)
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 13, weight: .semibold))
                Text(totalCity > 1 ? L10n.Global.countryCitiesSubtitle(totalCity) : L10n.Global.countrySingleSubtitle)
                    .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                    .font(Font.system(size: 12, weight: .regular))
            }
            
            if totalCity > 1 {
                Spacer()
                Asset.Assets.icArrowRight.swiftUIImage
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.bottom, 8)
        .contentShape(Rectangle())
    }
}

struct CityItemView: View {
    var countryName: String
    var cityName: String
    var imageUrl: String?
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if imageUrl != nil {
                KFImage(URL(string: imageUrl!))
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            } else {
                Asset.Assets.icFlagEmpty.swiftUIImage
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            }
            VStack(alignment: .leading) {
                Text(cityName)
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 13, weight: .semibold))
                Text(L10n.Global.cityOf(countryName))
                    .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                    .font(Font.system(size: 12, weight: .regular))
            }
        }.padding(.bottom, 8)
    }
}

struct MultiHopItemView: View {
    var countryNameStart: String
    var countryNameEnd: String
    var imageUrlStart: String?
    var imageUrlEnd: String?
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ZStack {
                Group {
                    if imageUrlStart != nil {
                        KFImage(URL(string: imageUrlStart!))
                            .resizable()
                    } else {
                        Asset.Assets.icFlagEmpty.swiftUIImage
                            .resizable()
                    }
                }
                .frame(width: 20, height: 20)
                .cornerRadius(10)
                .offset(.init(width: -10, height: 0))
                .opacity(0.5)
                Group {
                    if imageUrlEnd != nil {
                        KFImage(URL(string: imageUrlEnd!))
                            .resizable()
                            .frame(width: 26, height: 26)
                            .cornerRadius(13)
                    } else {
                        Asset.Assets.icFlagEmpty.swiftUIImage
                            .resizable()
                            .frame(width: 26, height: 26)
                            .cornerRadius(13)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24).stroke(style: .init(lineWidth: 2))
                        .foregroundColor(Asset.Colors.mainBackgroundColor.swiftUIColor)
                }.transformEffect(.init(translationX: 5, y: 0))
                
            }.frame(width: 40, height: 26, alignment: .center)
            Spacer().frame(width: 6)
            Text(countryNameStart)
                .foregroundColor(Asset.Colors.subTextColor.swiftUIColor
                )
                .font(Font.system(size: 13, weight: .regular))
            Asset.Assets.icArrowRight.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
            Text(countryNameEnd)
                .foregroundColor(Color.white)
                .font(Font.system(size: 13, weight: .semibold))
            Spacer()
        }.padding(.bottom, 8)
            .contentShape(Rectangle())
    }
}

struct StaticItemView: View {
    var countryName: String
    var cityName: String
    var imageUrl: String?
    var serverNumber: Int
    var percent: Int = 1
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if imageUrl != nil {
                KFImage(URL(string: imageUrl!))
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            } else {
                Asset.Assets.icFlagEmpty.swiftUIImage
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
            }
            Spacer().frame(width: 12)
            Asset.Assets.icStaticServer.swiftUIImage
                .resizable()
                .frame(width: 16, height: 16)
            Spacer().frame(width: 12)
            VStack(alignment: .leading) {
                Text(countryName)
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 13, weight: .semibold))
                Text("\(cityName) #\(serverNumber)")
                    .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                    .font(Font.system(size: 12, weight: .regular))
            }
            Spacer()
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .background(Color(rgb: 0x2E303D))
                    .frame(width: 40, height: 6)
                    .cornerRadius(3)
                Rectangle()
                    .foregroundColor(.clear)
                    .background(LinearGradient(gradient: Gradient(colors: [Color(rgb: 0x0CBC92), Color(rgb: 0xCEA71B), Color(rgb: 0xBF1616)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: 40, height: 6)
                    .clipShape(CustomProcessShape(percent: percent))
            }
        }.padding(.bottom, 10)
            .contentShape(Rectangle())
    }
}

struct CustomProcessShape: Shape {
    var percent: Int = 1
    func path(in rect: CGRect) -> Path {
        let width = CGFloat(percent) / 10 * rect.width
        var path = Path()
        path.addRoundedRect(in: CGRect(origin: .zero, size: CGSize(width: width, height: rect.height)), cornerSize: CGSize(width: rect.height / 2, height: rect.height / 2))
        return path
    }
}
