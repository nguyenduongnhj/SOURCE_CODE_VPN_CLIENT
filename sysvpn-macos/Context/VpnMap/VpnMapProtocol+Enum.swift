//
//  VpnMapViewProtocol.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 29/09/2022.
//

import Foundation
import Kingfisher
import SwiftUI
import SwiftUITooltip

protocol INodeInfo {
    var state: VpnMapPontState { get }
    var localtionIndex: Int? { get }
    var locationName: String { get }
    var image: KFImage? { get }
    var locationDescription: String? { get }
    var locationSubname: String? { get }
    var cacheNode: NodePoint? { get set }
    var level1Id: String { get }
    var imageUrl: String? { get }
    var deepId: String { get }
}

extension INodeInfo {
    var deepId: String {
        return "\(locationSubname ?? "")-\(locationName)"
    }
    
    static func == (lhs: INodeInfo, rhs: INodeInfo) -> Bool {
        // return lhs.locationSubname == rhs.locationSubname && rhs.locationName == lhs.locationName
        return lhs.deepId == rhs.deepId
    }
    
    static func equal(lhs: INodeInfo, rhs: INodeInfo) -> Bool {
        // return lhs.locationSubname == rhs.locationSubname && rhs.locationName == lhs.locationName
        return lhs.deepId == rhs.deepId
    }
}

struct NodePoint: Equatable {
    var point: CGPoint
    var l2Point: CGPoint?
    var info: INodeInfo
    var locationDescription: String?
    var children: [NodePoint]?
    init(point: CGPoint, info: INodeInfo, locationDescription: String? = nil, l2Point: CGPoint? = nil, children: [NodePoint]? = nil) {
        self.point = point
        self.l2Point = l2Point
        self.info = info
        self.locationDescription = locationDescription
        self.children = children
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.info.deepId == rhs.info.deepId
    }
}

struct ConnectPoint: Equatable {
    var point1: CGPoint
    var point2: CGPoint
    
    func buildPath(scale: CGFloat) -> Path {
        let point1 = CGPoint(x: self.point1.x * scale, y: self.point1.y * scale)
        let point2 = CGPoint(x: self.point2.x * scale, y: self.point2.y * scale)
         
        return ConnectPoint.generateSpecialCurve(from: point1, to: point2, bendFactor: -0.2, thickness: 1)
    }
    
    static func generateSpecialCurve(from: CGPoint, to: CGPoint, bendFactor: CGFloat, thickness: CGFloat) -> Path {
        let center = CGPoint(x: (from.x + to.x) * 0.5, y: (from.y + to.y) * 0.5)
        let normal = CGPoint(x: -(from.y - to.y), y: from.x - to.x)
        let normalNormalized: CGPoint = {
            let normalSize = sqrt(normal.x * normal.x + normal.y * normal.y)
            guard normalSize > 0.0 else { return .zero }
            return CGPoint(x: normal.x / normalSize, y: normal.y / normalSize)
        }()

        var path = Path()

        path.move(to: from)

        let midControlPoint = CGPoint(x: center.x + normal.x * bendFactor, y: center.y + normal.y * bendFactor)
        let closeControlPoint = CGPoint(x: midControlPoint.x + normalNormalized.x * thickness * 0.5, y: midControlPoint.y + normalNormalized.y * thickness * 0.5)
        let farControlPoint = CGPoint(x: midControlPoint.x - normalNormalized.x * thickness * 0.5, y: midControlPoint.y - normalNormalized.y * thickness * 0.5)
        path.addQuadCurve(to: to, control: closeControlPoint)
        path.addQuadCurve(to: from, control: farControlPoint)
        return path
    }
    
    static func generateSpecialCurveEx(from: CGPoint, current: CGPoint, to: CGPoint, bendFactor: CGFloat, thickness: CGFloat) -> Path {
        let center = CGPoint(x: (from.x + to.x) * 0.5, y: (from.y + to.y) * 0.5)
        let normal = CGPoint(x: -(from.y - to.y), y: from.x - to.x)
        let normalNormalized: CGPoint = {
            let normalSize = sqrt(normal.x * normal.x + normal.y * normal.y)
            guard normalSize > 0.0 else { return .zero }
            return CGPoint(x: normal.x / normalSize, y: normal.y / normalSize)
        }()

        var path = Path()

        path.move(to: from)

        let midControlPoint = CGPoint(x: center.x + normal.x * bendFactor, y: center.y + normal.y * bendFactor)
        let closeControlPoint = CGPoint(x: midControlPoint.x + normalNormalized.x * thickness * 0.5, y: midControlPoint.y + normalNormalized.y * thickness * 0.5)
        let farControlPoint = CGPoint(x: midControlPoint.x - normalNormalized.x * thickness * 0.5, y: midControlPoint.y - normalNormalized.y * thickness * 0.5)
        path.addQuadCurve(to: current, control: closeControlPoint)
        path.addQuadCurve(to: from, control: farControlPoint)
        return path
    }
}

class NodeInfoTest: INodeInfo {
    var deepId: String = ""
    
    var imageUrl: String?
    
    var level1Id: String = ""
    
    static func == (lhs: NodeInfoTest, rhs: NodeInfoTest) -> Bool {
        return false
    }

    var cacheNode: NodePoint?
    var locationDescription: String?
    
    var locationSubname: String?
    
    var image: KFImage? {
        return nil
    }
    
    var localtionIndex: Int?
    var state: VpnMapPontState = .disabled
    var locationName: String = "TEST NODE"
    
    init(state: VpnMapPontState, localtionIndex: Int? = nil) {
        self.state = state
        self.localtionIndex = localtionIndex
    }
}

enum VpnMapPontState {
    case normal
    case disabled
    case activated
    case activeDisabled
    
    var icon: Image {
        switch self {
        case .normal:
            return Asset.Assets.icNode.swiftUIImage
        case .activated:
            return Asset.Assets.icNodeActive.swiftUIImage
        case .disabled:
            return Asset.Assets.icNodeDisabled.swiftUIImage
        case .activeDisabled:
            return Asset.Assets.icNodeActiveDisabled.swiftUIImage
        }
    }
}

public struct AppTooltipConfig: TooltipConfig {
    static var shared = DefaultTooltipConfig()

    public var side: TooltipSide = .bottom
    public var margin: CGFloat = 8
    public var zIndex: Double = 10000
    
    public var width: CGFloat?
    public var height: CGFloat?

    public var borderRadius: CGFloat = 8
    public var borderWidth: CGFloat = 2
    public var borderColor: Color = .primary
    public var backgroundColor: Color = .white

    public var contentPaddingLeft: CGFloat = 12
    public var contentPaddingRight: CGFloat = 12
    public var contentPaddingTop: CGFloat = 8
    public var contentPaddingBottom: CGFloat = 8

    public var contentPaddingEdgeInsets: EdgeInsets {
        EdgeInsets(
            top: contentPaddingTop,
            leading: contentPaddingLeft,
            bottom: contentPaddingBottom,
            trailing: contentPaddingRight
        )
    }

    public var showArrow: Bool = true
    public var arrowWidth: CGFloat = 12
    public var arrowHeight: CGFloat = 6
    
    public var enableAnimation: Bool = true
    public var animationOffset: CGFloat = 10
    public var animationTime: Double = 1.5
    public var animation: Animation? = .easeInOut

    public var transition: AnyTransition = .opacity

    public init() {}

    public init(side: TooltipSide) {
        self.side = side
    }
}

struct RecentModel {
    var logDate: Date
    var node: INodeInfo
}
