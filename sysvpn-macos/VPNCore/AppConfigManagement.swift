//
//  AppConfigManagement.swift
//  TunnelKitDemo-macOS
//
//  Created by macbook on 09/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation

protocol PropertiesManagerProtocol: AnyObject {
    static var hasConnectedNotification: Notification.Name { get }
    static var userIpNotification: Notification.Name { get }
    static var earlyAccessNotification: Notification.Name { get }
    static var vpnProtocolNotification: Notification.Name { get }
    static var excludeLocalNetworksNotification: Notification.Name { get }
    static var killSwitchNotification: Notification.Name { get }
    
    var onAlternativeRoutingChange: ((Bool) -> Void)? { get set }
    
    func getAutoConnect(for username: String) -> (enabled: Bool, profileId: String?)
    func setAutoConnect(for username: String, enabled: Bool, profileId: String?)
    
    var hasConnected: Bool { get set }
    var lastOpenVpnConnection: ConnectionConfiguration? { get set }
    var lastWireguardConnection: ConnectionConfiguration? { get set }
    
    var excludeLocalNetworks: Bool { get }
    var killSwitch: Bool { get }
    var intentionallyDisconnected: Bool { get set }
}

class PropertiesManager: PropertiesManagerProtocol {
    static let shared = PropertiesManager()
    internal enum Keys: String, CaseIterable {
        case autoConnect = "AutoConnect"
        case autoConnectProfile = "AutoConnect_"
        case connectOnDemand = "ConnectOnDemand"
        case lastIkeConnection = "LastIkeConnection"
        case lastOpenVpnConnection = "LastOpenVPNConnection"
        case lastWireguardConnection = "LastWireguardConnection"
        case lastPreparingServer = "LastPreparingServer"
        case lastConnectedTimeStamp = "LastConnectedTimeStamp"
        case lastConnectionRequest = "LastConnectionRequest"
        case lastUserAccountPlan = "LastUserAccountPlan"
        case quickConnectProfile = "QuickConnect_"
        case secureCoreToggle = "SecureCoreToggle"
        case intentionallyDisconnected = "IntentionallyDisconnected"
        case userLocation = "UserLocation"
        case userDataDisclaimerAgreed = "UserDataDisclaimerAgreed"
        case lastBugReportEmail = "LastBugReportEmail"

        // Subscriptions
        case servicePlans
        case currentSubscription
        case defaultPlanDetails
        case isIAPUpgradePlanAvailable // Old name is left for backwards compatibility
        
        // Trial
        case trialWelcomed = "TrialWelcomed"
        case warnedTrialExpiring = "WarnedTrialExpiring"
        case warnedTrialExpired = "WarnedTrialExpired"
        
        // OpenVPN
        case openVpnConfig = "OpenVpnConfig"
        case vpnProtocol = "VpnProtocol"
        
        case apiEndpoint = "ApiEndpoint"
        
        // Migration
        case lastAppVersion = "LastAppVersion"
        
        // AppState
        case lastTimeForeground = "LastTimeForeground"

        // Discourage Secure Core
        case discourageSecureCore = "DiscourageSecureCore"

        // Did Show New Brand Modal
        case newBrandModalShown = "NewBrandModalShown"

        // Kill Switch
        case killSwitch = "Firewall"
        case excludeLocalNetworks
        case cyberSec
        
        // Features
        case featureFlags = "FeatureFlags"
        case maintenanceServerRefreshIntereval = "MaintenanceServerRefreshIntereval"
        case vpnAcceleratorEnabled = "VpnAcceleratorEnabled"
        
        case humanValidationFailed
        case alternativeRouting
        case smartProtocol
        case streamingServices
        case streamingResourcesUrl

        case wireguardConfig = "WireguardConfig"
        case smartProtocolConfig = "SmartProtocolConfig"
        case ratingSettings = "RatingSettings"
    }
    
    static let hasConnectedNotification = Notification.Name("HasConnectedChanged")
    static let userIpNotification = Notification.Name("UserIp")
    static let featureFlagsNotification = Notification.Name("FeatureFlags")
    static let earlyAccessNotification: Notification.Name = .init("EarlyAccessChanged")
    static let vpnProtocolNotification: Notification.Name = .init("VPNProtocolChanged")
    static let killSwitchNotification: Notification.Name = .init("KillSwitchChanged")
    static let excludeLocalNetworksNotification: Notification.Name = .init("ExcludeLocalNetworksChanged")
    var onAlternativeRoutingChange: ((Bool) -> Void)?
    
    var storage: UserDefaults = .standard
    
    var lastOpenVpnConnection: ConnectionConfiguration? {
        get {
            return ConnectionConfiguration.readUserDefault(keyUserDefault: Keys.lastOpenVpnConnection.rawValue)
        }
        set {
            newValue.saveUserDefault(keyUserDefault: Keys.lastOpenVpnConnection.rawValue)
        }
    }
    
    var lastWireguardConnection: ConnectionConfiguration? {
        get {
            return ConnectionConfiguration.readUserDefault(keyUserDefault: Keys.lastWireguardConnection.rawValue)
        }
        set {
            newValue.saveUserDefault(keyUserDefault: Keys.lastWireguardConnection.rawValue)
        }
    }
    
    public func getAutoConnect(for username: String) -> (enabled: Bool, profileId: String?) {
        let autoConnectEnabled = storage.bool(forKey: Keys.autoConnect.rawValue)
        let profileId = storage.string(forKey: Keys.autoConnectProfile.rawValue + username)
        return (autoConnectEnabled, profileId)
    }

    public func setAutoConnect(for username: String, enabled: Bool, profileId: String?) {
        storage.setValue(enabled, forKey: Keys.autoConnect.rawValue)
        if let profileId = profileId {
            storage.setValue(profileId, forKey: Keys.autoConnectProfile.rawValue + username)
        }
    }
    
    public var hasConnected: Bool {
        get {
            return storage.bool(forKey: Keys.connectOnDemand.rawValue)
        }
        set {
            storage.setValue(newValue, forKey: Keys.connectOnDemand.rawValue)
            postNotificationOnUIThread(type(of: self).hasConnectedNotification, object: newValue)
        }
    }
    
    var excludeLocalNetworks: Bool {
        get {
            return storage.bool(forKey: Keys.excludeLocalNetworks.rawValue)
        }
        set {
            storage.setValue(newValue, forKey: Keys.excludeLocalNetworks.rawValue)
            postNotificationOnUIThread(type(of: self).excludeLocalNetworksNotification, object: newValue)
        }
    }
    
    var killSwitch: Bool {
        get {
            return storage.bool(forKey: Keys.killSwitch.rawValue)
        }
        set {
            storage.setValue(newValue, forKey: Keys.killSwitch.rawValue)
            postNotificationOnUIThread(type(of: self).killSwitchNotification, object: newValue)
        }
    }
    
    var cybersec: Bool {
        get {
            return storage.bool(forKey: Keys.cyberSec.rawValue)
        }
        set {
            storage.setValue(newValue, forKey: Keys.cyberSec.rawValue)
        }
    }
    
    var vpnProtocol: VpnProtocol? {
        get {
             
            return VpnProtocol.readUserDefault(keyUserDefault: Keys.vpnProtocol.rawValue)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: Keys.vpnProtocol.rawValue)
            } else {
                newValue.saveUserDefault(keyUserDefault: Keys.vpnProtocol.rawValue)
            }
           
        }
    }
    
    func postNotificationOnUIThread(_ name: NSNotification.Name, object: Any?, userInfo: [AnyHashable: Any]? = nil) {
        executeOnUIThread {
            NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
        }
    }
    
    public var lastTimeForeground: Date? {
        get {
            guard let timeSince1970 = storage.value(forKey: Keys.lastTimeForeground.rawValue) as? Double else { return nil }
            return Date(timeIntervalSince1970: timeSince1970)
        }
        set {
            storage.setValue(newValue?.timeIntervalSince1970, forKey: Keys.lastTimeForeground.rawValue)
        }
    }
    
    public var intentionallyDisconnected: Bool {
        get {
            return storage.bool(forKey: Keys.intentionallyDisconnected.rawValue)
        }
        set {
            storage.setValue(newValue, forKey: Keys.intentionallyDisconnected.rawValue)
        }
    }
    
    var systemNotification: Bool {
        get {
            return storage.bool(forKey: "SystemNotification")
        }
        set {
            storage.setValue(newValue, forKey: "SystemNotification")
        }
    }
    
    var startMinimized: Bool {
        get {
            return storage.bool(forKey: "StartMinimized")
        }
        set {
            storage.setValue(newValue, forKey: "StartMinimized")
        }
    }
    
    var autoLaunch: Bool {
        get {
            return storage.bool(forKey: "AutoLaunch")
        }
        set {
            storage.setValue(newValue, forKey: "AutoLaunch")
        }
    }
    
    var countryQuickConnect: Int? {
        get {
            let value = storage.integer(forKey: "CountryQuickConnect")
            return value == 0 ? nil : value
        }
        set {
            storage.setValue(newValue, forKey: "CountryQuickConnect")
        }
    }
    
    var isFirstSetup: Bool {
        get {
            return storage.bool(forKey: "isFirstSetup")
        }
        set {
            storage.setValue(newValue, forKey: "isFirstSetup")
        }
    }
    
    var lastConnectedDeepId: String? {
        get {
            return storage.string(forKey: "lastConnectedDeepId")
        }
        set {
            storage.setValue(newValue, forKey: "lastConnectedDeepId")
        }
    }
}
