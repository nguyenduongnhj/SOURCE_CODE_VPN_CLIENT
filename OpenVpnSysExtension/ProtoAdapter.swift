//
//  ProtoAdapter.swift
//  sysvpn-macos
//
//  Created by macbook on 28/11/2022.
//
import Foundation
import NetworkExtension
import SwiftyBeaver

open class ProtoAdapter {
    open func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {}
    
    open func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {}
    
    open func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {}
}
