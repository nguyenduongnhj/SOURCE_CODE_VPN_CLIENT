//
//  PinZoomView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 03/09/2022.
//

import Combine
import Foundation
import SwiftUI
class ZoomStoreValue {
    var lastValue: Double = 0
    var intCountSampleValue = 0
}

struct ZoomModifier: ViewModifier {
    private var contentSize: CGSize
    @Binding var screenSize: CGSize
    private var min: CGFloat = 1.0
    private var max: CGFloat = 2
    private var numberImage: CGFloat = 3
    @Binding var disableZoom: Bool
    @State var lastScaleValue: CGFloat = 1
    @State var isAppear: Bool = false
    @Binding var currentScale: CGFloat
    @State var isDrag = false
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @Binding var cameraPosition: CGPoint?
    @State var subs = Set<AnyCancellable>()
    var storeValue = ZoomStoreValue()
    
    var overlayLayer: VpnMapOverlayLayer
    
    init(contentSize: CGSize, screenSize: Binding<CGSize>, numberImage: Int = 3, currentScale: Binding<CGFloat>, cameraPosition: Binding<CGPoint?>, overlayLayer: VpnMapOverlayLayer, disableZoom: Binding<Bool>) {
        self.contentSize = contentSize
        self.numberImage = CGFloat(numberImage)
        self.overlayLayer = overlayLayer
        _disableZoom = disableZoom
        _screenSize = screenSize
        _currentScale = currentScale
        _cameraPosition = cameraPosition
        lastScaleValue = currentScale.wrappedValue
        
        // self.screenSize = screenSize.wrappedValue
        // self.cameraPosition = cameraPosition.wrappedValue
    }
    
    func calcOffset(newOffset: CGSize, skipCheckPosition: Bool = false) {
        let newContentWidth = contentSize.width * currentScale * numberImage
        let newContentHeight = contentSize.height * currentScale
        
        if offset.height > 0 {
            offset.height = 0
        }
        if numberImage > 1 {
            if !skipCheckPosition {
                if abs(offset.width) > newContentWidth * 2 / numberImage || abs(offset.width) < newContentWidth / numberImage {
                    offset.width = offset.width.remainder(dividingBy: newContentWidth / numberImage) - newContentWidth / numberImage
                }
            }
        } else {
            if offset.width > 0 {
                offset.width = 0
            }
            if screenSize.width >= newContentWidth {
                offset.width = (screenSize.width - newContentWidth) / 2
            } else {
                if abs(offset.width) + screenSize.width > newContentWidth {
                    offset.width = (newContentWidth - screenSize.width) * -1
                }
            }
        }
      
        if offset.height * -1 > newContentHeight - contentSize.height {
            offset.height = (newContentHeight - contentSize.height) * -1
        }
    }
    
    func onScaleCalcOffset(value: CGFloat) {
        let currentWidth = contentSize.width * numberImage * lastScaleValue
        let currentHeight = contentSize.height * lastScaleValue
        
        let nextWith = contentSize.width * value * numberImage
        let nextHeight = contentSize.height * value
        let dist = (offset.width * -1 + screenSize.width / 2) - currentWidth / 2
        let percent = dist / (contentSize.width / 2) / lastScaleValue
        
        offset.width += (currentWidth - nextWith) / (2 - percent)
        offset.height += (currentHeight - nextHeight) / (2 - percent)
        calcOffset(newOffset: offset, skipCheckPosition: lastScaleValue > 0.9)
        lastScaleValue = value
    }
     
    func body(content: Content) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ScrollViewReader { _ in
                HStack {
                    content
                        .frame(width: contentSize.width * currentScale * numberImage, height: contentSize.height * currentScale, alignment: .center)
                        .modifier(PinchToZoom(minScale: min, maxScale: max, scale: $currentScale))
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                 
                            .onChanged { val in
                                if isDrag == false {
                                    lastOffset = offset
                                }
                                isDrag = true
                                offset.width = lastOffset.width + val.translation.width
                                offset.height = lastOffset.height + val.translation.height
                                calcOffset(newOffset: offset)
                            }
                            .onEnded { _ in
                                isDrag = false
                            }
                        )
                        .modifier(overlayLayer)
                        .onChange(of: currentScale) { newValue in
                            onScaleCalcOffset(value: newValue)
                        }
                        .onChange(of: screenSize, perform: { _ in
                            if isAppear {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        calcOffset(newOffset: offset, skipCheckPosition: true)
                                    }
                                }
                            } else {
                                isAppear = true
                            }
                           
                        })
                        .onChange(of: cameraPosition) { newValue in
                            guard let value = newValue else {
                                return
                            }
                            withAnimation {
                                offset.width = screenSize.width / 2 - value.x * currentScale
                                offset.height = screenSize.height / 2 - value.y * currentScale
                                calcOffset(newOffset: offset)
                            }
                        }
                }
            }
                
        }.content.offset(offset)
            .onAppear {
                offset.width = contentSize.width * -1 * floor(numberImage / 2)
                trackScrollWheel()
            }
    }
    
    func updateDetail(detail: Double) {
        if detail == 0 {
            return
        }
         
        let value = currentScale + detail / 100
        currentScale = Swift.min(Swift.max(value, self.min), self.max)
    }
    
    func checkEventScroll(event: NSEvent?) {
        if disableZoom {
            return
        }
        
        guard let event = event else {
            return
        }
        
        if WindowMgr.shared.nsWindow != event.window {
            return
        }
        
        if event.phase.rawValue == 0 {
            if storeValue.lastValue == event.timestamp {
                storeValue.intCountSampleValue += 1
            } else {
                storeValue.intCountSampleValue = 0
            }
           
            storeValue.lastValue = event.timestamp
           
            if storeValue.intCountSampleValue > 10 {
                return
            }
           
        } else {
            storeValue.intCountSampleValue = 0
        }
    
        updateDetail(detail: Double(event.scrollingDeltaY))
    }
    
    func trackScrollWheel() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(20),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .sink { event in
                
                self.checkEventScroll(event: event)
            }
            .store(in: &subs)
    }
}

struct PinchToZoom: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    // var mouseLocation: NSPoint { NSEvent.mouseLocation }
    
    @Binding var scale: CGFloat
    @State var anchor: UnitPoint = .center
    @State var isPinching: Bool = false
    @GestureState var magnifyBy = 1.0
    @State var lastScaleValue: CGFloat = 1.0
    
    var magnification: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, _ in
                gestureState = currentState
            }.onChanged { val in
                let delta = val / lastScaleValue
                self.lastScaleValue = val
                var newScale = scale * delta
                if newScale > maxScale {
                    newScale = maxScale
                } else if newScale < minScale {
                    newScale = minScale
                }
                scale = newScale
                isPinching = true
            }.onEnded { _ in
                isPinching = false
                lastScaleValue = 1.0
            }
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .gesture(magnification)
    }
}
 