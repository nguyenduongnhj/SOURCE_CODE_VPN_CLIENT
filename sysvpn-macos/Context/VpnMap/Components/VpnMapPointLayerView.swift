//
//  VpnMapPointLayerView.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 28/09/2022.
//

import Foundation
import SwiftUI
import SwiftUITooltip

struct VpnMapPointLayerView: View {
    var connectedNodeInfo: INodeInfo?
    var connectPoints: [ConnectPoint]
    var nodeList: [NodePoint]
    var scaleVector: CGFloat = 1
    var onTouchPoint: ((NodePoint) -> Void)?
    var onHoverNode: ((NodePoint, Bool) -> Void)?
    var isShowCity: Bool = false
    let lineGradient = Gradient(colors: [
        Asset.Colors.secondary.swiftUIColor,
        Asset.Colors.primaryColor.swiftUIColor
    ])
    
    func scalePoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * scaleVector, y: point.y * scaleVector)
    }
    
    var normalState: VpnMapPontState {
        if GlobalAppStates.shared.displayState == .connected || GlobalAppStates.shared.displayState == .connecting {
            return .disabled
        }
        return .normal
    }
    
    @State var cgPoint: CGPoint = .zero
    
    var nodeItems: some View {
        Group {
            ForEach(0..<nodeList.count, id: \.self) { index in
                
                let parentPosition = scalePoint(nodeList[index].point)
                let node = isShowCity ? (nodeList[index].children?.first ?? nodeList[index]) : nodeList[index]
                let nodePosition = isShowCity ? scalePoint(node.point) : parentPosition
                
                VpnMapPointView(state: normalState,
                                locationIndex: node.info.localtionIndex,
                                onHoverNode: { hover in
                                    onHoverNode?(node, hover)
                                }
                )
                .position(x: nodePosition.x, y: nodePosition.y)
                .onTapGesture {
                    onTouchPoint?(node)
                }
               
                if let children = nodeList[index].children, children.count > 1 {
                    ForEach(0..<children.count, id: \.self) { index2 in
                        let childPos = isShowCity ? scalePoint(children[index2].point) : parentPosition
                        VpnMapPointView(state: normalState,
                                        locationIndex: children[index2].info.localtionIndex,
                                        onHoverNode: { hover in
                                            onHoverNode?(children[index2], hover)
                                        }
                        )
                        .position(x: childPos.x, y: childPos.y)
                        .opacity(isShowCity ? 1 : 0)
                        
                        .onTapGesture {
                            onTouchPoint?(children[index2])
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            nodeItems
            
            if normalState == .disabled, let connectedNodeInfo = connectedNodeInfo {
                // multiple hop connected node point
                if let multipleHop = connectedNodeInfo as? MultiHopResult {
                    if let entryNode = multipleHop.entry?.city?.toNodePoint(), let nodePos = computNodePointPos(node: entryNode), let exitNode = multipleHop.exit?.city?.toNodePoint(), let nodePos2 = computNodePointPos(node: exitNode) {
                        let connectPoint = ConnectPoint(point1: nodePos, point2: nodePos2)
                        
                        Spacer().modifier(SingalLineAnimatedModifier(point2: cgPoint, point1: connectPoint.point1, maxPoint: connectPoint.point2))
                            .onAppear {
                                cgPoint = connectPoint.point1
                                withAnimation(Animation.easeInOut(duration: 1)) {
                                    cgPoint = connectPoint.point2
                                }
                            }.allowsHitTesting(false)
                      
                        VpnMapPointView(state: .activeDisabled,
                                        locationIndex: 1,
                                        onHoverNode: { hover in
                                            onHoverNode?(entryNode, hover)
                                        }
                        ).position(x: nodePos.x, y: nodePos.y)
                            .onTapGesture {
                                onTouchPoint?(entryNode)
                            }.animation(.none, value: UUID())
                        
                        VpnMapPointView(state: .activated,
                                        locationIndex: 2,
                                        onHoverNode: { hover in
                                            onHoverNode?(exitNode, hover)
                                        }
                        ).position(x: nodePos2.x, y: nodePos2.y)
                            .onTapGesture {
                                onTouchPoint?(exitNode)
                            }.animation(.none, value: UUID())
                    }
                }
                // single connected node point
                else if let node = connectedNodeInfo.toNodePoint(), let nodePos = computNodePointPos(node: node) {
                    VpnMapPointView(state: .activated,
                                    locationIndex: node.info.localtionIndex,
                                    onHoverNode: { hover in
                                        onHoverNode?(node, hover)
                                    }
                    ).position(x: nodePos.x, y: nodePos.y)
                        .onTapGesture {
                            onTouchPoint?(node)
                        }
                }
            }
        }
    }
    
    func computNodePointPos(node: NodePoint) -> CGPoint {
        var point: CGPoint = scalePoint(node.point)
        if !isShowCity {
            if let l2Point = node.l2Point {
                point = scalePoint(l2Point)
            }
        }
        return point
    }
}
 
struct SingalLineAnimatedModifier: AnimatableModifier {
    var point2: CGPoint = .zero
    var point1: CGPoint = .zero
    var maxPoint: CGPoint = .zero
    
    let lineGradient = Gradient(colors: [
        Asset.Colors.secondary.swiftUIColor,
        Asset.Colors.primaryColor.swiftUIColor
    ])
    
    func path(in rect: CGRect) -> Path {
        let percent = CGPointDistance(from: point2, to: point1) / CGPointDistance(from: maxPoint, to: point1)
        return ConnectPoint.generateSpecialCurve(from: point1, to: maxPoint, bendFactor: -0.2, thickness: 1).trimmedPath(from: 0, to: percent)
    }
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(point2.x, point2.y)
        }
        set {
            point2.x = newValue.first
            point2.y = newValue.second
        }
    }
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }

    func body(content: Content) -> some View {
        Canvas { context, _ in
            let path = path(in: CGRect.zero)
            context.stroke(path, with: .linearGradient(lineGradient, startPoint: point1, endPoint: maxPoint), lineWidth: 2.2)
        }
        .allowsHitTesting(false)
    }
}
