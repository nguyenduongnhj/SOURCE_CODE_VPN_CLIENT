// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Global {
    /// Account
    public static let account = L10n.tr("Global", "account", fallback: "Account")
    /// Account sercurity
    public static let accountSercurity = L10n.tr("Global", "accountSercurity", fallback: "Account sercurity")
    /// At least 8 characters including a number, uppercase, and lowercase letter.
    public static let accountSercurityDesc = L10n.tr("Global", "accountSercurityDesc", fallback: "At least 8 characters including a number, uppercase, and lowercase letter.")
    /// Scroll down to more
    public static let alertScrollToShowMore = L10n.tr("Global", "alertScrollToShowMore", fallback: "Scroll down to more")
    /// All countries
    public static let allCountriesLabel = L10n.tr("Global", "allCountriesLabel", fallback: "All countries")
    /// All Profiles
    public static let allProfile = L10n.tr("Global", "allProfile", fallback: "All Profiles")
    /// Appearence
    public static let appearence = L10n.tr("Global", "appearence", fallback: "Appearence")
    /// App language
    public static let appLanguage = L10n.tr("Global", "appLanguage", fallback: "App language")
    /// Auto connect
    public static let autoConnect = L10n.tr("Global", "autoConnect", fallback: "Auto connect")
    /// Lorem ipsum dolor sit amet, consectetur adipiscing elit
    public static let autoConnectDesc = L10n.tr("Global", "autoConnectDesc", fallback: "Lorem ipsum dolor sit amet, consectetur adipiscing elit")
    /// Auto-launch
    public static let autoLaunch = L10n.tr("Global", "autoLaunch", fallback: "Auto-launch")
    /// Start SysVPN automatically when system starts.
    public static let autoLaunchDesc = L10n.tr("Global", "autoLaunchDesc", fallback: "Start SysVPN automatically when system starts.")
    /// Cancel
    public static let cancel = L10n.tr("Global", "cancel", fallback: "Cancel")
    /// Change password
    public static let changePassword = L10n.tr("Global", "changePassword", fallback: "Change password")
    /// Password changed successfully
    public static let changePasswordSuccess = L10n.tr("Global", "changePasswordSuccess", fallback: "Password changed successfully")
    /// City Of %s
    public static func cityOf(_ p1: UnsafePointer<CChar>) -> String {
      return L10n.tr("Global", "cityOf", p1, fallback: "City Of %s")
    }
    /// Confirm new password
    public static let confirmPassword = L10n.tr("Global", "confirmPassword", fallback: "Confirm new password")
    /// Confirm sign out
    public static let confirmSignOut = L10n.tr("Global", "confirmSignOut", fallback: "Confirm sign out")
    /// Connected
    public static let connected = L10n.tr("Global", "connected", fallback: "Connected")
    /// %d cities available
    public static func countryCitiesSubtitle(_ p1: Int) -> String {
      return L10n.tr("Global", "countryCitiesSubtitle", p1, fallback: "%d cities available")
    }
    /// Country cannot be empty
    public static let countryEmpty = L10n.tr("Global", "countryEmpty", fallback: "Country cannot be empty")
    /// Single location
    public static let countrySingleSubtitle = L10n.tr("Global", "countrySingleSubtitle", fallback: "Single location")
    /// Create
    public static let create = L10n.tr("Global", "create", fallback: "Create")
    /// Create new
    public static let createNew = L10n.tr("Global", "createNew", fallback: "Create new")
    /// Create a new profile
    public static let createNewProfile = L10n.tr("Global", "createNewProfile", fallback: "Create a new profile")
    /// Current IP Address
    public static let currentIpStr = L10n.tr("Global", "currentIpStr", fallback: "Current IP Address")
    /// CURRENT LOAD
    public static let currentLoadLabel = L10n.tr("Global", "currentLoadLabel", fallback: "CURRENT LOAD")
    /// Current password
    public static let currentPassword = L10n.tr("Global", "currentPassword", fallback: "Current password")
    /// Current sesstion time
    public static let currentSessionStr = L10n.tr("Global", "currentSessionStr", fallback: "Current sesstion time")
    /// CyberSec
    public static let cyberSec = L10n.tr("Global", "cyberSec", fallback: "CyberSec")
    /// Protects you from cyber threats by blocking malicious website.
    public static let cyberSecDesc = L10n.tr("Global", "cyberSecDesc", fallback: "Protects you from cyber threats by blocking malicious website.")
    /// Dark mode
    public static let darkMode = L10n.tr("Global", "darkMode", fallback: "Dark mode")
    /// %d free days
    public static func daysFree(_ p1: Int) -> String {
      return L10n.tr("Global", "daysFree", p1, fallback: "%d free days")
    }
    /// %d days left
    public static func daysLeft(_ p1: Int) -> String {
      return L10n.tr("Global", "daysLeft", p1, fallback: "%d days left")
    }
    /// Delete profile
    public static let deleteProfile = L10n.tr("Global", "deleteProfile", fallback: "Delete profile")
    /// Down speed
    public static let downSpeed = L10n.tr("Global", "downSpeed", fallback: "Down speed")
    /// Down Volume:
    public static let downVolumeLabel = L10n.tr("Global", "downVolumeLabel", fallback: "Down Volume:")
    /// Email account
    public static let emailAccount = L10n.tr("Global", "emailAccount", fallback: "Email account")
    /// Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
    public static let emptyProfileDesc = L10n.tr("Global", "emptyProfileDesc", fallback: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor")
    /// Follow system
    public static let followSystem = L10n.tr("Global", "followSystem", fallback: "Follow system")
    /// Font Size
    public static let fontSize = L10n.tr("Global", "fontSize", fallback: "Font Size")
    /// Lorem ipsum dolor sit amet, consectetur adipiscing elit
    public static let fontSizeDesc = L10n.tr("Global", "fontSizeDesc", fallback: "Lorem ipsum dolor sit amet, consectetur adipiscing elit")
    /// General
    public static let general = L10n.tr("Global", "general", fallback: "General")
    /// Global.strings
    ///   sysvpn-macos
    /// 
    ///   Created by Nguyen Dinh Thach on 30/08/2022.
    public static let hello = L10n.tr("Global", "hello", fallback: "Hello")
    /// Help Center
    public static let helpCenter = L10n.tr("Global", "helpCenter", fallback: "Help Center")
    /// IP:
    public static let ipLabel = L10n.tr("Global", "ipLabel", fallback: "IP:")
    /// Kill switch
    public static let killSwitch = L10n.tr("Global", "killSwitch", fallback: "Kill switch")
    /// Blocks unprotected traffic if VPN connection drops.
    public static let killSwitchDesc = L10n.tr("Global", "killSwitchDesc", fallback: "Blocks unprotected traffic if VPN connection drops.")
    /// Location:
    public static let labelLocation = L10n.tr("Global", "labelLocation", fallback: "Location:")
    /// VPN IP:
    public static let labelVPNIP = L10n.tr("Global", "labelVPNIP", fallback: "VPN IP:")
    /// Light mode
    public static let lightMode = L10n.tr("Global", "lightMode", fallback: "Light mode")
    /// Location:
    public static let locationLabel = L10n.tr("Global", "locationLabel", fallback: "Location:")
    /// Location Map
    public static let locationMap = L10n.tr("Global", "locationMap", fallback: "Location Map")
    /// Longest connection
    public static let longestConnection = L10n.tr("Global", "longestConnection", fallback: "Longest connection")
    /// available
    public static let manualCDesc = L10n.tr("Global", "manualCDesc", fallback: "available")
    /// Locations
    public static let manualConnection = L10n.tr("Global", "manualConnection", fallback: "Locations")
    /// Manual
    public static let manualStr = L10n.tr("Global", "manualStr", fallback: "Manual")
    /// MultiHop
    public static let multiHop = L10n.tr("Global", "multiHop", fallback: "MultiHop")
    /// available
    public static let multiHopDesc = L10n.tr("Global", "multiHopDesc", fallback: "available")
    /// MultiHop
    public static let multihopLabel = L10n.tr("Global", "multihopLabel", fallback: "MultiHop")
    /// New password
    public static let newPassword = L10n.tr("Global", "newPassword", fallback: "New password")
    /// Newsletters
    public static let newsletters = L10n.tr("Global", "newsletters", fallback: "Newsletters")
    /// Lorem ipsum dolor sit amet, consectetur adipiscing elit
    public static let newslettersDesc = L10n.tr("Global", "newslettersDesc", fallback: "Lorem ipsum dolor sit amet, consectetur adipiscing elit")
    /// No set
    public static let noset = L10n.tr("Global", "noset", fallback: "No set")
    /// Password not match
    public static let passNotMatch = L10n.tr("Global", "passNotMatch", fallback: "Password not match")
    /// Pick to top
    public static let pickToTop = L10n.tr("Global", "pickToTop", fallback: "Pick to top")
    /// +Extended
    public static let plusExtended = L10n.tr("Global", "plusExtended", fallback: "+Extended")
    /// Profile name cannot be empty
    public static let profileEmpty = L10n.tr("Global", "profileEmpty", fallback: "Profile name cannot be empty")
    /// Profile name
    public static let profileName = L10n.tr("Global", "profileName", fallback: "Profile name")
    /// Profiles
    public static let profileStr = L10n.tr("Global", "profileStr", fallback: "Profiles")
    /// Protocol
    public static let `protocol` = L10n.tr("Global", "protocol", fallback: "Protocol")
    /// Protocol in use
    public static let protocolUse = L10n.tr("Global", "protocolUse", fallback: "Protocol in use")
    /// Quick
    /// Connect
    public static let quickConnect = L10n.tr("Global", "quickConnect", fallback: "Quick\nConnect")
    /// Lorem ipsum dolor sit amet, consectetur adipiscing elit
    public static let quickConnectDesc = L10n.tr("Global", "quickConnectDesc", fallback: "Lorem ipsum dolor sit amet, consectetur adipiscing elit")
    /// Quick connect
    public static let quickConnectSetting = L10n.tr("Global", "quickConnectSetting", fallback: "Quick connect")
    /// Recent locations
    public static let recentLocationsLabel = L10n.tr("Global", "recentLocationsLabel", fallback: "Recent locations")
    /// Recommended
    public static let recommendedLabel = L10n.tr("Global", "recommendedLabel", fallback: "Recommended")
    /// Rename
    public static let rename = L10n.tr("Global", "rename", fallback: "Rename")
    /// Rename profile
    public static let renameProfile = L10n.tr("Global", "renameProfile", fallback: "Rename profile")
    /// No country found
    public static let searchEmptyStr = L10n.tr("Global", "searchEmptyStr", fallback: "No country found")
    /// Search
    public static let searchStr = L10n.tr("Global", "searchStr", fallback: "Search")
    /// Select
    public static let select = L10n.tr("Global", "select", fallback: "Select")
    /// Select location
    public static let selectLocation = L10n.tr("Global", "selectLocation", fallback: "Select location")
    /// Session:
    public static let sessionLabel = L10n.tr("Global", "sessionLabel", fallback: "Session:")
    /// Session Traffics
    public static let sessionTraffics = L10n.tr("Global", "sessionTraffics", fallback: "Session Traffics")
    /// Set location
    public static let setLocation = L10n.tr("Global", "setLocation", fallback: "Set location")
    /// Settings
    public static let setting = L10n.tr("Global", "setting", fallback: "Settings")
    /// You will be returned to the login screen
    public static let signOutDesc = L10n.tr("Global", "signOutDesc", fallback: "You will be returned to the login screen")
    /// Start minimized
    public static let startMinimized = L10n.tr("Global", "startMinimized", fallback: "Start minimized")
    /// SysVPN starts in the background and remains out of your way.
    public static let startMinimizedDesc = L10n.tr("Global", "startMinimizedDesc", fallback: "SysVPN starts in the background and remains out of your way.")
    /// Static IP
    public static let staticIP = L10n.tr("Global", "staticIP", fallback: "Static IP")
    /// Personal Static IP address
    public static let staticIPDesc = L10n.tr("Global", "staticIPDesc", fallback: "Personal Static IP address")
    /// Static ip
    public static let staticIpLabel = L10n.tr("Global", "staticIpLabel", fallback: "Static ip")
    /// Statistics
    public static let statistics = L10n.tr("Global", "statistics", fallback: "Statistics")
    /// Subscription details
    public static let subscriptionDetails = L10n.tr("Global", "subscriptionDetails", fallback: "Subscription details")
    /// Support Center
    public static let supportCenter = L10n.tr("Global", "supportCenter", fallback: "Support Center")
    /// System notifications
    public static let systemNoti = L10n.tr("Global", "systemNoti", fallback: "System notifications")
    /// I want to get notifications when connecting/disconnecting from SysVPN.
    public static let systemNotiDesc = L10n.tr("Global", "systemNotiDesc", fallback: "I want to get notifications when connecting/disconnecting from SysVPN.")
    /// Sysvpn Configuration
    public static let sysvpnConfiguration = L10n.tr("Global", "sysvpnConfiguration", fallback: "Sysvpn Configuration")
    /// Theme mode
    public static let themeMode = L10n.tr("Global", "themeMode", fallback: "Theme mode")
    /// Sign Out
    public static let titleLogout = L10n.tr("Global", "titleLogout", fallback: "Sign Out")
    /// An error occurred. Please try again later
    public static let unknowError = L10n.tr("Global", "unknowError", fallback: "An error occurred. Please try again later")
    /// Connect to VPN to online sercurity
    public static let unprotectedAlertMessage = L10n.tr("Global", "unprotectedAlertMessage", fallback: "Connect to VPN to online sercurity")
    /// Your IP: %s Unprotected
    public static func unprotectedAlertTitle(_ p1: UnsafePointer<CChar>) -> String {
      return L10n.tr("Global", "unprotectedAlertTitle", p1, fallback: "Your IP: %s Unprotected")
    }
    /// At least 8 characters including a number and lowercase letter
    public static let unsatisfactoryPassword = L10n.tr("Global", "unsatisfactoryPassword", fallback: "At least 8 characters including a number and lowercase letter")
    /// Up speed
    public static let upSpeed = L10n.tr("Global", "upSpeed", fallback: "Up speed")
    /// Up Volume:
    public static let upVolumeLabel = L10n.tr("Global", "upVolumeLabel", fallback: "Up Volume:")
    /// VPN Connected
    public static let vpnConnected = L10n.tr("Global", "vpnConnected", fallback: "VPN Connected")
    /// VPN not connected
    public static let vpnNotConnected = L10n.tr("Global", "vpnNotConnected", fallback: "VPN not connected")
    /// VPN Settings
    public static let vpnSetting = L10n.tr("Global", "vpnSetting", fallback: "VPN Settings")
    /// VPN Status
    public static let vpnStatus = L10n.tr("Global", "vpnStatus", fallback: "VPN Status")
    /// Weekly time protected
    public static let weeklyTimeStr = L10n.tr("Global", "weeklyTimeStr", fallback: "Weekly time protected")
    /// What is multihop?
    public static let whatIsMultihop = L10n.tr("Global", "whatIsMultihop", fallback: "What is multihop?")
  }
  public enum Login {
    /// All Country
    public static let allCountry = L10n.tr("Login", "allCountry", fallback: "All Country")
    /// SYSVPN
    public static let appName = L10n.tr("Login", "appName", fallback: "SYSVPN")
    /// Create New
    public static let createNew = L10n.tr("Login", "createNew", fallback: "Create New")
    /// Disconnect
    public static let disconnect = L10n.tr("Login", "disconnect", fallback: "Disconnect")
    /// Don’t have an account?
    public static let dontHaveAnAccount = L10n.tr("Login", "dontHaveAnAccount", fallback: "Don’t have an account?")
    /// Forgot password
    public static let forgotPassword = L10n.tr("Login", "forgotPassword", fallback: "Forgot password")
    /// Password
    public static let password = L10n.tr("Login", "password", fallback: "Password")
    /// Protected
    public static let protected = L10n.tr("Login", "protected", fallback: "Protected")
    /// Quick Connect
    public static let quickConnect = L10n.tr("Login", "quickConnect", fallback: "Quick Connect")
    /// Recent
    public static let recent = L10n.tr("Login", "recent", fallback: "Recent")
    /// Remember login
    public static let rememberLogin = L10n.tr("Login", "rememberLogin", fallback: "Remember login")
    /// Sign in
    public static let signIn = L10n.tr("Login", "signIn", fallback: "Sign in")
    /// Sign In with Apple ID
    public static let signInWithApple = L10n.tr("Login", "signInWithApple", fallback: "Sign In with Apple ID")
    /// Sign In with Google
    public static let signInWithGoogle = L10n.tr("Login", "signInWithGoogle", fallback: "Sign In with Google")
    /// Login.strings
    ///   sysvpn-macos
    /// 
    ///   Created by Nguyen Dinh Thach on 31/08/2022.
    public static let sologan = L10n.tr("Login", "sologan", fallback: "Start protecting yourself with SysVPN")
    /// Light is Faster, but We are Safer.
    public static let sologanProcessing = L10n.tr("Login", "sologanProcessing", fallback: "Light is Faster, but We are Safer.")
    /// Suggest
    public static let suggest = L10n.tr("Login", "suggest", fallback: "Suggest")
    /// Connect to VPN to online sercurity
    public static let titleNotConnect = L10n.tr("Login", "titleNotConnect", fallback: "Connect to VPN to online sercurity")
    /// Open
    public static let titleOpen = L10n.tr("Login", "titleOpen", fallback: "Open")
    /// Quit
    public static let titleQuit = L10n.tr("Login", "titleQuit", fallback: "Quit")
    /// Please try again!
    public static let tryAgain = L10n.tr("Login", "tryAgain", fallback: "Please try again!")
    /// Unprotected
    public static let unprotected = L10n.tr("Login", "unprotected", fallback: "Unprotected")
    /// Welcome Back
    public static let welcomeBack = L10n.tr("Login", "welcomeBack", fallback: "Welcome Back")
    /// Your email
    public static let yourEmail = L10n.tr("Login", "yourEmail", fallback: "Your email")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
