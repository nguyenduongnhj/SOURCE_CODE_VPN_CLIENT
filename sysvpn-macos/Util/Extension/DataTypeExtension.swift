//
//  DataTypeExtension.swift
//  sysvpn-macos
//
//  Created by NuocLoc on 01/10/2022.
//

import Foundation
import SwiftUI

extension Binding where Value == Double {
    public func cgFloat() -> Binding<CGFloat> {
        return Binding<CGFloat>(get:{ CGFloat(self.wrappedValue) },
            set: { self.wrappedValue = Double($0)})
    }
}
