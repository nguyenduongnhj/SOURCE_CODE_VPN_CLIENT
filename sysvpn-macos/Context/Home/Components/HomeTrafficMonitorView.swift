//
//  HomeTraficMonitorView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/10/2022.
//

import Foundation
import SwiftUI

struct HomeTrafficMonitorView: View {
    @State var bitRateState = Bitrate(download: 0, upload: 0)
    @State var usageInfo = SingleDataUsageInfo(received: 0, sent: 0)
    @EnvironmentObject var networkState: NetworkAppStates
    @EnvironmentObject var appState: GlobalAppStates
    var body: some View {
        HStack(alignment: .bottom) {
            HomeTrafficInfoView(bitRate: bitRateState, usageInfo: usageInfo, startTime: appState.sessionStartTime)
            Spacer()
            HomeTrafficChartView(bitRate: bitRateState)
                .frame(maxWidth: .infinity)
        }.onChange(of: networkState.bitRate) { newValue in
            bitRateState = newValue
            usageInfo = SystemDataUsage.lastestVpnUsageInfo
        }
    }
}

struct HomeTrafficInfoView: View {
    var bitRate: Bitrate
    var usageInfo: SingleDataUsageInfo
    var startTime: Double?
    
    @State var sessionDisplay: String = "--:--:--"
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(L10n.Global.sessionTraffics)
                .font(Font.system(size: 16, weight: .semibold))
                .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
            Spacer().frame(height: 15)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Global.sessionLabel)
                    Text(L10n.Global.downVolumeLabel)
                    Text(L10n.Global.upVolumeLabel)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(sessionDisplay)
                    Text(usageInfo.displayString(for: usageInfo.received))
                    Text(usageInfo.displayString(for: usageInfo.sent))
                }
            }.frame(maxWidth: 200)
             
        }.onChange(of: bitRate, perform: { _ in
            sessionDisplay = getTime(now: Date().timeIntervalSince1970)
        })
        .font(Font.system(size: 13, weight: .regular))
        .foregroundColor(Color.white)
    }
    
    func getTime(now: Double) -> String {
        guard let startTime = startTime else {
            return "--:--:--"
        }
         
        let diff = now - startTime
        if diff < 0 {
            return "00:00:00"
        }
       
        let hour = floor(diff / 60 / 60)
        let min = floor((diff - hour * 60 * 60) / 60)
        let second = floor(diff - (hour * 60 * 60 + min * 60))
         
        return .init(format: "%02d:%02d:%02d", Int(hour), Int(min), Int(second))
    }
}

struct HomeTrafficChartView: View {
    var bitRate: Bitrate
    @State var lineDownSpeed: [Double] = [0]
    @State var lineUpSpeed: [Double] = [0]
    var body: some View {
        VStack {
            HStack {
                HStack(spacing: 2) {
                    Asset.Assets.icArrowDown.swiftUIImage.renderingMode(.template)
                        .foregroundColor(Asset.Colors.primaryColor.swiftUIColor)
                    Text("\(L10n.Global.downSpeed) \(Bitrate.rateString(for: bitRate.download))")
                }
                Spacer().frame(width: 16)
                HStack(spacing: 2) {
                    Asset.Assets.icArrowUp.swiftUIImage.renderingMode(.template)
                    Text("\(L10n.Global.upSpeed) \(Bitrate.rateString(for: bitRate.upload))")
                }
                Spacer()
            }
            Spacer().frame(height: 24)
            TrafficLineChartView()
        }.onChange(of: bitRate) { _ in
            withAnimation {
                lineDownSpeed.append(Double(bitRate.download))
                lineUpSpeed.append(Double(bitRate.upload))
                if lineDownSpeed.count > 20 {
                    lineDownSpeed.removeFirst()
                }
                if lineUpSpeed.count > 20 {
                    lineUpSpeed.removeFirst()
                }
            }
        }
    }
}
 