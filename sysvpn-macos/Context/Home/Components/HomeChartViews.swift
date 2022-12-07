//
//  HomeChartViews.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 02/10/2022.
//

import Foundation
import SwiftUI

struct LineShape: Shape {
    var yValues: [Double]
    var lastPoint: CGPoint
    var scaleFactor: Double
    var prevScale: Double
    
    // var startX: CGFloat = 0
        
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(lastPoint.x, lastPoint.y)
        }

        set {
            lastPoint.x = newValue.first
            lastPoint.y = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let xIncrement: CGFloat = rect.width / 17
 
        var path = Path()
        if yValues.count < 2 {
            return path
        }
        // let startX =
        
        /* path.move(to: CGPoint(x: startX - xValue,
                               y: rect.height - (yValues[0] * scaleFactor)))
         for i in 1..<yValues.count - 1 {
             xValue += xIncrement
             let pt = CGPoint(x: startX + xValue ,
                              y: rect.height - (yValues[i] * scaleFactor))
             path.addLine(to: pt)
         }
        
         path.addLine(to: CGPoint(
             x: rect.maxX, y:   rect.height - (lastPoint.y * scaleFactor) ))*/
        let scale = prevScale + (scaleFactor - prevScale) * lastPoint.x
        path.move(to: CGPoint(x: rect.maxX, y: rect.height - (lastPoint.y * scale)))
        
        for i in 1..<yValues.count - 1 {
            let value = yValues[yValues.count - i - 1]
            
            let pt = CGPoint(x: rect.maxX - CGFloat(i - 1) * xIncrement - xIncrement * lastPoint.x,
                             y: rect.height - (value * scale))
            path.addLine(to: pt)
        }
        
        return path
    }
}

struct ChartLineBackground: Shape {
    func path(in rect: CGRect) -> Path {
        let spacing: CGFloat = rect.height / 3
        var path = Path()
          
        for i in 0..<4 {
            let floatI = CGFloat(i)
            path.move(to: CGPoint(x: 0,
                                  y: rect.height - floatI * spacing))
                          
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - floatI * spacing))
        }
            
        return path
    }
}
 
struct TrafficLineChartView: View {
    @EnvironmentObject var networkState: NetworkAppStates
    @State var list1: [Double] = []
    @State var list2: [Double] = []
    @State var x: CGFloat = 0
    var height: CGFloat = 54
    @State var maxValue: Double = 0 {
        willSet {
            lastMaxValue = maxValue
        }
    }

    @State var lastMaxValue: Double = 0
    var body: some View {
        ZStack {
            ZStack {
                ChartLineBackground().stroke(Color.white.opacity(0.05), lineWidth: 1.0)
                LineShape(yValues: list1, lastPoint: CGPoint(x: x, y: list1.last ?? 0), scaleFactor: height / max(2, maxValue), prevScale: height / max(2, lastMaxValue)).stroke(Color(rgb: 0x464859), lineWidth: 1.0)
                LineShape(yValues: list2, lastPoint: CGPoint(x: x, y: list2.last ?? 0), scaleFactor: height / max(2, maxValue), prevScale: height / max(2, lastMaxValue)).stroke(Asset.Colors.primaryColor.swiftUIColor, lineWidth: 1.0)
                
            }.frame(height: height)
                .padding(.top, 5)
                .padding(.bottom, 5)
                .clipped()
                .drawingGroup()
          
            HStack(alignment: .top) {
                Spacer()
                Text(Bitrate.rateString(for: UInt32(maxValue)))
                    .foregroundColor(Asset.Colors.subTextColor.swiftUIColor)
                    .transformEffect(.init(translationX: 0, y: -42))
                    .animation(nil, value: UUID())
            }.frame(height: height)
                .onChange(of: networkState.bitRate) { _ in
                    x = 0
                    withAnimation(.linear(duration: 1)) {
                        list1.append(Double(networkState.bitRate.upload))
                        list2.append(Double(networkState.bitRate.download))
                        maxValue = max(list1.max() ?? 1, list2.max() ?? 1)
                        x = 1
                        if list1.count > 20 {
                            list1.removeFirst()
                        }
                        if list2.count > 20 {
                            list2.removeFirst()
                        }
                    }
                }
        }
    }
}
 