//
//  TabbarItemView.swift
//  sysvpn-macos
//
//  Created by doragon on 26/10/2022.
//

import Kingfisher
import SwiftUI

struct TabbarItemView: View {
    var model: TabbarListItemModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let image = model.image {
                image
            } else {
                Asset.Assets.icFlagEmpty.swiftUIImage
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(16)
            }
            
            VStack(alignment: .leading) {
                model.fullDisplayLocationName
                    .foregroundColor(
                        model.isConnecting ?
                            Asset.Colors.primaryColor.swiftUIColor : Color.white)
                    .font(Font.system(size: 14, weight: .semibold))
                Spacer().frame(height: 4)
                if model.isConnecting {
                    Text("Connected")
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        .font(Font.system(size: 13, weight: .regular))
                } else if model.isShowDate {
                    Text(model.timeAgoSinceDate())
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        .font(Font.system(size: 13, weight: .regular))
                } else {
                    Text(model.totalCity >= 1 ? "\(model.totalCity) cities available" : "Single location")
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                        .font(Font.system(size: 13, weight: .regular))
                }
            }
        }.padding(.bottom, 10)
            .contentShape(Rectangle())
    }
}

extension TabbarListItemModel {
    var fullDisplayLocationName: some View {
        Group {
            if let model = self.raw as? CountryAvailables {
                Text(model.locationName)
            } else if let model = self.raw as? CountryCity {
                HStack {
                    Asset.Assets.icPickLocationSm.swiftUIImage
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text("\(model.name ?? ""),")
                        .font(Font.system(size: 14, weight: .regular))
                    Text("\(model.country?.name ?? "")")
                }
            } else if let model = self.raw as? CountryStaticServers {
                HStack {
                    Asset.Assets.icStaticServer.swiftUIImage
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text(model.locationName)
                }
            } else if let model = self.raw as? MultiHopResult {
                HStack {
                    Text(model.entry?.country?.name ?? "")
                        .foregroundColor(Asset.Colors.subTextColor.swiftUIColor
                        )
                        .font(Font.system(size: 14, weight: .regular))
                    Asset.Assets.icArrowRight.swiftUIImage
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(model.exit?.country?.name ?? "")
                        .font(Font.system(size: 14, weight: .semibold))
                    Spacer()
                }
            } else {
                Text(self.title)
            }
        }
    }
    
    func timeAgoSinceDate(numericDates: Bool = false) -> String {
        let date = lastUse
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = Date()
        let earliest = now < date ? now : date
        let latest = (earliest == now) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        
        if components.year! >= 2 {
            return "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if components.month! >= 2 {
            return "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            return "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if components.day! >= 2 {
            return "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if components.hour! >= 2 {
            return "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if components.minute! >= 2 {
            return "\(components.minute!) minutes ago"
        } else if components.minute! >= 1 {
            if numericDates {
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if components.second! >= 3 {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
    }
}
