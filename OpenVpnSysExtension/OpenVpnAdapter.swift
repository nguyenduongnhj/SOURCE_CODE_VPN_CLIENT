//
//  OpenVpnAdapter.swift
//  sysvpn-macosOpenVPNTunnelExtension
//
//  Created by macbook on 23/10/2022.
//
 
import __TunnelKitUtils
import CoreWLAN
import CTunnelKitCore
import NetworkExtension
import os.log
import SwiftyBeaver
import TunnelKitAppExtension
import TunnelKitCore
import TunnelKitManager
import TunnelKitOpenVPNAppExtension
import TunnelKitOpenVPNCore
import TunnelKitOpenVPNManager
import TunnelKitOpenVPNProtocol
private let log = SwiftyBeaver.self
 
open class OpenVPNTunnelAdapter: ProtoAdapter {
    private weak var packetTunnelProvider: NEPacketTunnelProvider?

    // MARK: Tweaks
    
    /// An optional string describing host app version on tunnel start.
    public var appVersion: String?

    /// The log separator between sessions.
    public var logSeparator = "--- EOF ---"
    
    /// The maximum size of the log.
    public var maxLogSize = 20000
    
    /// The log level when `OpenVPNTunnelProvider.Configuration.shouldDebug` is enabled.
    public var debugLogLevel: SwiftyBeaver.Level = .debug
    
    /// The number of milliseconds after which a DNS resolution fails.
    public var dnsTimeout = 3000
    
    /// The number of milliseconds after which the tunnel gives up on a connection attempt.
    public var socketTimeout = 5000
    
    /// The number of milliseconds after which the tunnel is shut down forcibly.
    public var shutdownTimeout = 2000
    
    /// The number of milliseconds after which a reconnection attempt is issued.
    public var reconnectionDelay = 1000
    
    /// The number of link failures after which the tunnel is expected to die.
    public var maxLinkFailures = 3

    /// The number of milliseconds between data count updates. Set to 0 to disable updates (default).
    public var dataCountInterval = 0
    
    /// A list of public DNS servers to use as fallback when none are provided (defaults to CloudFlare).
    public var fallbackDNSServers = [
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
    ]
    
    // MARK: Constants
    
    private let tunnelQueue = DispatchQueue(label: OpenVPNTunnelProvider.description(), qos: .utility)
    
    private let prngSeedLength = 64
    
    private var cachesURL: URL {
        let appGroup = cfg.appGroup
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("No access to app group: \(appGroup)")
        }
        return containerURL.appendingPathComponent("Library/Caches/")
    }

    // MARK: Tunnel configuration

    var cfg: OpenVPN.ProviderConfiguration!
    
    var strategy: ConnectionStrategy!
    
    // MARK: Internal state

    private var session: OpenVPNSession?
    
    private var socket: GenericSocket?

    private var pendingStartHandler: ((Error?) -> Void)?
    
    private var pendingStopHandler: (() -> Void)?
    
    private var isCountingData = false
    
    private var shouldReconnect = false
    
    init(packetTunnelProvider: NEPacketTunnelProvider?) {
        self.packetTunnelProvider = packetTunnelProvider
    }
 
    override open func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        // required configuration
        do {
            guard let tunnelProtocol = packetTunnelProvider?.protocolConfiguration as? NETunnelProviderProtocol else {
                throw OpenVPNProviderConfigurationError.parameter(name: "protocolConfiguration")
            }
            guard let _ = tunnelProtocol.serverAddress else {
                throw OpenVPNProviderConfigurationError.parameter(name: "protocolConfiguration.serverAddress")
            }
            guard let providerConfiguration = tunnelProtocol.providerConfiguration else {
                throw OpenVPNProviderConfigurationError.parameter(name: "protocolConfiguration.providerConfiguration")
            }
            cfg = try fromDictionary(OpenVPN.ProviderConfiguration.self, providerConfiguration)
        } catch let e {
            var message: String?
            if let te = e as? OpenVPNProviderConfigurationError {
                switch te {
                case let .parameter(name):
                    message = "Tunnel configuration incomplete: \(name)"
                    
                default:
                    break
                }
            }
            NSLog(message ?? "Unexpected error in tunnel configuration: \(e)")
            completionHandler(e)
            return
        }

        // prepare for logging (append)
        configureLogging()

        // logging only ACTIVE from now on
        log.info("")
        log.info(logSeparator)
        log.info("")

        // override library configuration
        CoreConfiguration.masksPrivateData = cfg.masksPrivateData
        if let versionIdentifier = cfg.versionIdentifier {
            CoreConfiguration.versionIdentifier = versionIdentifier
        }

        // optional credentials
        let credentials: OpenVPN.Credentials?
        if let username = packetTunnelProvider?.protocolConfiguration.username, let passwordReference = packetTunnelProvider?.protocolConfiguration.passwordReference {
            guard let password = try? Keychain.password(forReference: passwordReference) else {
                completionHandler(OpenVPNProviderConfigurationError.credentials(details: "Keychain.password(forReference:)"))
                return
            }
            credentials = OpenVPN.Credentials(username, password)
        } else {
            credentials = nil
        }

        log.info("Starting tunnel...")
        cfg._appexSetLastError(nil)
        
        guard OpenVPN.prepareRandomNumberGenerator(seedLength: prngSeedLength) else {
            completionHandler(OpenVPNProviderConfigurationError.prngInitialization)
            return
        }

        if let appVersion = appVersion {
            log.info("App version: \(appVersion)")
        }
        cfg.print()

        // prepare to pick endpoints
        strategy = ConnectionStrategy(configuration: cfg.configuration)

        let session: OpenVPNSession
        do {
            session = try OpenVPNSession(queue: tunnelQueue, configuration: cfg.configuration, cachesURL: cachesURL)
            refreshDataCount()
        } catch let e {
            completionHandler(e)
            return
        }
        session.credentials = credentials
        session.delegate = self
        self.session = session

        logCurrentSSID()

        pendingStartHandler = completionHandler
        tunnelQueue.sync {
            self.connectTunnel()
        }
    }
    
    override open func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        pendingStartHandler = nil
        log.info("Stopping tunnel...")
        cfg._appexSetLastError(nil)

        guard let session = session else {
            flushLog()
            completionHandler()
            forceExitOnMac()
            return
        }

        pendingStopHandler = completionHandler
        tunnelQueue.schedule(after: .milliseconds(shutdownTimeout)) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            guard let pendingHandler = weakSelf.pendingStopHandler else {
                return
            }
            log.warning("Tunnel not responding after \(weakSelf.shutdownTimeout) milliseconds, forcing stop")
            weakSelf.flushLog()
            pendingHandler()
            self?.forceExitOnMac()
        }
        tunnelQueue.sync {
            session.shutdown(error: nil)
        }
    }
     
    // MARK: Connection (tunnel queue)
    
    private func connectTunnel(upgradedSocket: GenericSocket? = nil) {
        log.info("Creating link session")
        
        // reuse upgraded socket
        if let upgradedSocket = upgradedSocket, !upgradedSocket.isShutdown {
            log.debug("Socket follows a path upgrade")
            connectTunnel(via: upgradedSocket)
            return
        }
        
        strategy.createSocket(from: packetTunnelProvider!, timeout: dnsTimeout, queue: tunnelQueue) {
            switch $0 {
            case let .success(socket):
                self.connectTunnel(via: socket)
                
            case let .failure(error):
                if case .dnsFailure = error {
                    self.tunnelQueue.async {
                        self.strategy.tryNextEndpoint()
                        self.connectTunnel()
                    }
                    return
                }
                self.disposeTunnel(error: error)
            }
        }
    }
    
    private func connectTunnel(via socket: GenericSocket) {
        log.info("Will connect to \(socket)")
        cfg._appexSetLastError(nil)

        log.debug("Socket type is \(type(of: socket))")
        self.socket = socket
        self.socket?.delegate = self
        self.socket?.observe(queue: tunnelQueue, activeTimeout: socketTimeout)
    }
    
    private func finishTunnelDisconnection(error: Error?) {
        if let session = session, !(shouldReconnect && session.canRebindLink()) {
            session.cleanup()
        }
        
        socket?.delegate = nil
        socket?.unobserve()
        socket = nil
        
        if let error = error {
            log.error("Tunnel did stop (error: \(error))")
            setErrorStatus(with: error)
        } else {
            log.info("Tunnel did stop on request")
        }
    }
    
    private func disposeTunnel(error: Error?) {
        flushLog()

        // failed to start
        if pendingStartHandler != nil {
            //
            // CAUTION
            //
            // passing nil to this callback will result in an extremely undesired situation,
            // because NetworkExtension would interpret it as "successfully connected to VPN"
            //
            // if we end up here disposing the tunnel with a pending start handled, we are
            // 100% sure that something wrong happened while starting the tunnel. in such
            // case, here we then must also make sure that an error object is ALWAYS
            // provided, so we do this with optional fallback to .socketActivity
            //
            // socketActivity makes sense, given that any other error would normally come
            // from OpenVPN.stopError. other paths to disposeTunnel() are only coming
            // from stopTunnel(), in which case we don't need to feed an error parameter to
            // the stop completion handler
            //
            pendingStartHandler?(error ?? OpenVPNProviderError.socketActivity)
            pendingStartHandler = nil
        }
        // stopped intentionally
        else if pendingStopHandler != nil {
            pendingStopHandler?()
            pendingStopHandler = nil
            forceExitOnMac()
        }
        // stopped externally, unrecoverable
        else {
            packetTunnelProvider?.cancelTunnelWithError(error)
            forceExitOnMac()
        }
    }
    
    // MARK: Data counter (tunnel queue)

    private func refreshDataCount() {
        guard dataCountInterval > 0 else {
            return
        }
        tunnelQueue.schedule(after: .milliseconds(dataCountInterval)) { [weak self] in
            self?.refreshDataCount()
        }
        guard isCountingData, let session = session, let dataCount = session.dataCount() else {
            cfg._appexSetDataCount(nil)
            return
        }
        cfg._appexSetDataCount(dataCount)
    }
}

extension OpenVPNTunnelAdapter: GenericSocketDelegate {
    // MARK: GenericSocketDelegate (tunnel queue)
    
    public func socketDidTimeout(_ socket: GenericSocket) {
        log.debug("Socket timed out waiting for activity, cancelling...")
       
        shouldReconnect = true
        socket.shutdown()

        // fallback: TCP connection timeout suggests falling back
        if let _ = socket as? NETCPSocket {
            guard tryNextEndpoint() else {
                // disposeTunnel
                return
            }
        }
    }
    
    public func socketDidBecomeActive(_ socket: GenericSocket) {
        guard let session = session, let producer = socket as? LinkProducer else {
            return
        }
        if session.canRebindLink() {
            session.rebindLink(producer.link(xorMask: cfg.configuration.xorMask))
            packetTunnelProvider?.reasserting = false
        } else {
            session.setLink(producer.link(xorMask: cfg.configuration.xorMask))
        }
    }
    
    public func socket(_ socket: GenericSocket, didShutdownWithFailure failure: Bool) {
        guard let session = session else {
            return
        }
        
        var shutdownError: Error?
        let didTimeoutNegotiation: Bool
        var upgradedSocket: GenericSocket?

        // look for error causing shutdown
        shutdownError = session.stopError
        if failure && (shutdownError == nil) {
            shutdownError = OpenVPNProviderError.linkError
        }
        didTimeoutNegotiation = (shutdownError as? OpenVPNError == .negotiationTimeout)
        
        // only try upgrade on network errors
        if shutdownError as? OpenVPNError == nil {
            upgradedSocket = socket.upgraded()
        }

        // clean up
        finishTunnelDisconnection(error: shutdownError)

        // fallback: UDP is connection-less, treat negotiation timeout as socket timeout
        if didTimeoutNegotiation {
            guard tryNextEndpoint() else {
                // disposeTunnel
                return
            }
        }

        // reconnect?
        if shouldReconnect {
            log.debug("Disconnection is recoverable, tunnel will reconnect in \(reconnectionDelay) milliseconds...")
            tunnelQueue.schedule(after: .milliseconds(reconnectionDelay)) {
                // give up if shouldReconnect cleared in the meantime
                guard self.shouldReconnect else {
                    log.warning("Reconnection flag was cleared in the meantime")
                    return
                }

                log.debug("Tunnel is about to reconnect...")
                self.packetTunnelProvider?.reasserting = true
                self.connectTunnel(upgradedSocket: upgradedSocket)
            }
            return
        }
        
        // shut down
        disposeTunnel(error: shutdownError)
    }
    
    public func socketHasBetterPath(_: GenericSocket) {
        log.debug("Stopping tunnel due to a new better path")
        logCurrentSSID()
        session?.reconnect(error: OpenVPNProviderError.networkChanged)
    }
}

extension OpenVPNTunnelAdapter: OpenVPNSessionDelegate {
    // MARK: OpenVPNSessionDelegate (tunnel queue)
    
    public func sessionDidStart(_ session: OpenVPNSession, remoteAddress: String, options: OpenVPN.Configuration) {
        log.info("Session did start")
        
        log.info("Returned ifconfig parameters:")
        log.info("\tRemote: \(remoteAddress.maskedDescription)")
        log.info("\tIPv4: \(options.ipv4?.description ?? "not configured")")
        log.info("\tIPv6: \(options.ipv6?.description ?? "not configured")")
        if let routingPolicies = options.routingPolicies {
            log.info("\tGateway: \(routingPolicies.map { $0.rawValue })")
        } else {
            log.info("\tGateway: not configured")
        }
        if let dnsServers = options.dnsServers, !dnsServers.isEmpty {
            log.info("\tDNS: \(dnsServers.map { $0.maskedDescription })")
        } else {
            log.info("\tDNS: not configured")
        }
        if let searchDomains = options.searchDomains, !searchDomains.isEmpty {
            log.info("\tSearch domains: \(searchDomains.maskedDescription)")
        } else {
            log.info("\tSearch domains: not configured")
        }

        if options.httpProxy != nil || options.httpsProxy != nil || options.proxyAutoConfigurationURL != nil {
            log.info("\tProxy:")
            if let proxy = options.httpProxy {
                log.info("\t\tHTTP: \(proxy.maskedDescription)")
            }
            if let proxy = options.httpsProxy {
                log.info("\t\tHTTPS: \(proxy.maskedDescription)")
            }
            if let pacURL = options.proxyAutoConfigurationURL {
                log.info("\t\tPAC: \(pacURL)")
            }
            if let bypass = options.proxyBypassDomains {
                log.info("\t\tBypass domains: \(bypass.maskedDescription)")
            }
        }

        cfg._appexSetServerConfiguration(session.serverConfiguration() as? OpenVPN.Configuration)

        bringNetworkUp(remoteAddress: remoteAddress, localOptions: session.configuration, options: options) { error in

            // FIXME: XPC queue
            
            self.packetTunnelProvider?.reasserting = false
            
            if let error = error {
                log.error("Failed to configure tunnel: \(error)")
                self.pendingStartHandler?(error)
                self.pendingStartHandler = nil
                return
            }
            
            log.info("Tunnel interface is now UP")
            
            session.setTunnel(tunnel: NETunnelInterface(impl: self.packetTunnelProvider!.packetFlow))

            self.pendingStartHandler?(nil)
            self.pendingStartHandler = nil
        }

        isCountingData = true
        refreshDataCount()
    }
    
    public func sessionDidStop(_: OpenVPNSession, withError error: Error?, shouldReconnect: Bool) {
        cfg._appexSetServerConfiguration(nil)

        if let error = error {
            log.error("Session did stop with error: \(error)")
        } else {
            log.info("Session did stop")
        }
        
        isCountingData = false
        refreshDataCount()

        self.shouldReconnect = shouldReconnect
        socket?.shutdown()
    }
    
    private func bringNetworkUp(remoteAddress: String, localOptions: OpenVPN.Configuration, options: OpenVPN.Configuration, completionHandler: @escaping (Error?) -> Void) {
        let routingPolicies = localOptions.routingPolicies ?? options.routingPolicies
        let isIPv4Gateway = routingPolicies?.contains(.IPv4) ?? false
        let isIPv6Gateway = routingPolicies?.contains(.IPv6) ?? false
        let isGateway = isIPv4Gateway || isIPv6Gateway

        var ipv4Settings: NEIPv4Settings?
        if let ipv4 = options.ipv4 {
            var routes: [NEIPv4Route] = []

            // route all traffic to VPN?
            if isIPv4Gateway {
                let defaultRoute = NEIPv4Route.default()
                defaultRoute.gatewayAddress = ipv4.defaultGateway
                routes.append(defaultRoute)
//                for network in ["0.0.0.0", "128.0.0.0"] {
//                    let route = NEIPv4Route(destinationAddress: network, subnetMask: "128.0.0.0")
//                    route.gatewayAddress = ipv4.defaultGateway
//                    routes.append(route)
//                }
                log.info("Routing.IPv4: Setting default gateway to \(ipv4.defaultGateway.maskedDescription)")
            }
            
            for r in ipv4.routes {
                let ipv4Route = NEIPv4Route(destinationAddress: r.destination, subnetMask: r.mask)
                ipv4Route.gatewayAddress = r.gateway
                routes.append(ipv4Route)
                log.info("Routing.IPv4: Adding route \(r.destination.maskedDescription)/\(r.mask) -> \(r.gateway)")
            }
            
            ipv4Settings = NEIPv4Settings(addresses: [ipv4.address], subnetMasks: [ipv4.addressMask])
            ipv4Settings?.includedRoutes = routes
            ipv4Settings?.excludedRoutes = []
        }

        var ipv6Settings: NEIPv6Settings?
        if let ipv6 = options.ipv6 {
            var routes: [NEIPv6Route] = []

            // route all traffic to VPN?
            if isIPv6Gateway {
                let defaultRoute = NEIPv6Route.default()
                defaultRoute.gatewayAddress = ipv6.defaultGateway
                routes.append(defaultRoute)
//                for network in ["2000::", "3000::"] {
//                    let route = NEIPv6Route(destinationAddress: network, networkPrefixLength: 4)
//                    route.gatewayAddress = ipv6.defaultGateway
//                    routes.append(route)
//                }
                log.info("Routing.IPv6: Setting default gateway to \(ipv6.defaultGateway.maskedDescription)")
            }

            for r in ipv6.routes {
                let ipv6Route = NEIPv6Route(destinationAddress: r.destination, networkPrefixLength: r.prefixLength as NSNumber)
                ipv6Route.gatewayAddress = r.gateway
                routes.append(ipv6Route)
                log.info("Routing.IPv6: Adding route \(r.destination.maskedDescription)/\(r.prefixLength) -> \(r.gateway)")
            }

            ipv6Settings = NEIPv6Settings(addresses: [ipv6.address], networkPrefixLengths: [ipv6.addressPrefixLength as NSNumber])
            ipv6Settings?.includedRoutes = routes
            ipv6Settings?.excludedRoutes = []
        }

        // shut down if default gateway is not attainable
        var hasGateway = false
        if isIPv4Gateway && (ipv4Settings != nil) {
            hasGateway = true
        }
        if isIPv6Gateway && (ipv6Settings != nil) {
            hasGateway = true
        }
        guard !isGateway || hasGateway else {
            session?.shutdown(error: OpenVPNProviderError.gatewayUnattainable)
            return
        }
        
        var dnsSettings: NEDNSSettings?
        if localOptions.isDNSEnabled ?? true {
            var dnsServers: [String] = []
            if #available(iOS 14, macOS 11, *) {
                switch localOptions.dnsProtocol {
                case .https:
                    dnsServers = localOptions.dnsServers ?? []
                    guard let serverURL = localOptions.dnsHTTPSURL else {
                        break
                    }
                    let specific = NEDNSOverHTTPSSettings(servers: dnsServers)
                    specific.serverURL = serverURL
                    dnsSettings = specific
                    log.info("DNS over HTTPS: Using servers \(dnsServers.maskedDescription)")
                    log.info("\tHTTPS URL: \(serverURL.maskedDescription)")

                case .tls:
                    dnsServers = localOptions.dnsServers ?? []
                    guard let serverName = localOptions.dnsTLSServerName else {
                        break
                    }
                    let specific = NEDNSOverTLSSettings(servers: dnsServers)
                    specific.serverName = serverName
                    dnsSettings = specific
                    log.info("DNS over TLS: Using servers \(dnsServers.maskedDescription)")
                    log.info("\tTLS server name: \(serverName.maskedDescription)")

                default:
                    break
                }
            }

            // fall back
            if dnsSettings == nil {
                dnsServers = []
                if let servers = localOptions.dnsServers,
                   !servers.isEmpty {
                    dnsServers = servers
                } else if let servers = options.dnsServers {
                    dnsServers = servers
                }
                if !dnsServers.isEmpty {
                    log.info("DNS: Using servers \(dnsServers.maskedDescription)")
                    dnsSettings = NEDNSSettings(servers: dnsServers)
                } else {
                    //                log.warning("DNS: No servers provided, using fall-back servers: \(fallbackDNSServers.maskedDescription)")
                    //                dnsSettings = NEDNSSettings(servers: fallbackDNSServers)
                    log.warning("DNS: No settings provided, using current network settings")
                }
            }

            // "hack" for split DNS (i.e. use VPN only for DNS)
            if !isGateway {
                dnsSettings?.matchDomains = [""]
            }
            
            if let searchDomains = localOptions.searchDomains ?? options.searchDomains {
                log.info("DNS: Using search domains \(searchDomains.maskedDescription)")
                dnsSettings?.domainName = searchDomains.first
                dnsSettings?.searchDomains = searchDomains
                if !isGateway {
                    dnsSettings?.matchDomains = dnsSettings?.searchDomains
                }
            }
            
            // add direct routes to DNS servers
            if !isGateway {
                for server in dnsServers {
                    if server.contains(":") {
                        ipv6Settings?.includedRoutes?.insert(NEIPv6Route(destinationAddress: server, networkPrefixLength: 128), at: 0)
                    } else {
                        ipv4Settings?.includedRoutes?.insert(NEIPv4Route(destinationAddress: server, subnetMask: "255.255.255.255"), at: 0)
                    }
                }
            }
        }
        
        var proxySettings: NEProxySettings?
        if localOptions.isProxyEnabled ?? true {
            if let httpsProxy = cfg.configuration.httpsProxy ?? options.httpsProxy {
                proxySettings = NEProxySettings()
                proxySettings?.httpsServer = httpsProxy.neProxy()
                proxySettings?.httpsEnabled = true
                log.info("Routing: Setting HTTPS proxy \(httpsProxy.address.maskedDescription):\(httpsProxy.port)")
            }
            if let httpProxy = localOptions.httpProxy ?? options.httpProxy {
                if proxySettings == nil {
                    proxySettings = NEProxySettings()
                }
                proxySettings?.httpServer = httpProxy.neProxy()
                proxySettings?.httpEnabled = true
                log.info("Routing: Setting HTTP proxy \(httpProxy.address.maskedDescription):\(httpProxy.port)")
            }
            if let pacURL = localOptions.proxyAutoConfigurationURL ?? options.proxyAutoConfigurationURL {
                if proxySettings == nil {
                    proxySettings = NEProxySettings()
                }
                proxySettings?.proxyAutoConfigurationURL = pacURL
                proxySettings?.autoProxyConfigurationEnabled = true
                log.info("Routing: Setting PAC \(pacURL.maskedDescription)")
            }

            // only set if there is a proxy (proxySettings set to non-nil above)
            if let bypass = localOptions.proxyBypassDomains ?? options.proxyBypassDomains {
                proxySettings?.exceptionList = bypass
                log.info("Routing: Setting proxy by-pass list: \(bypass.maskedDescription)")
            }
        }

        // block LAN if desired
        if routingPolicies?.contains(.blockLocal) ?? false {
            let table = RoutingTable()
            if isIPv4Gateway,
               let gateway = table.defaultGateway4()?.gateway(),
               let route = table.broadestRoute4(matchingDestination: gateway) {
                route.partitioned()?.forEach {
                    let destination = $0.network()
                    guard let netmask = $0.networkMask() else {
                        return
                    }
                    
                    log.info("Block local: Suppressing IPv4 route \(destination)/\($0.prefix())")
                    
                    let included = NEIPv4Route(destinationAddress: destination, subnetMask: netmask)
                    included.gatewayAddress = options.ipv4?.defaultGateway
                    ipv4Settings?.includedRoutes?.append(included)
                }
            }
            if isIPv6Gateway,
               let gateway = table.defaultGateway6()?.gateway(),
               let route = table.broadestRoute6(matchingDestination: gateway) {
                route.partitioned()?.forEach {
                    let destination = $0.network()
                    let prefix = $0.prefix()
                    
                    log.info("Block local: Suppressing IPv6 route \(destination)/\($0.prefix())")

                    let included = NEIPv6Route(destinationAddress: destination, networkPrefixLength: prefix as NSNumber)
                    included.gatewayAddress = options.ipv6?.defaultGateway
                    ipv6Settings?.includedRoutes?.append(included)
                }
            }
        }
        
        let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: remoteAddress)
        newSettings.ipv4Settings = ipv4Settings
        newSettings.ipv6Settings = ipv6Settings
        newSettings.dnsSettings = dnsSettings
        newSettings.proxySettings = proxySettings
        if let mtu = localOptions.mtu, mtu > 0 {
            newSettings.mtu = NSNumber(value: mtu)
        }

        packetTunnelProvider?.setTunnelNetworkSettings(newSettings, completionHandler: completionHandler)
    }
}

extension OpenVPNTunnelAdapter {
    private func tryNextEndpoint() -> Bool {
        guard strategy.tryNextEndpoint() else {
            disposeTunnel(error: OpenVPNProviderError.exhaustedEndpoints)
            return false
        }
        return true
    }
    
    // MARK: Logging
    
    private func configureLogging() {
        let logLevel: SwiftyBeaver.Level = (cfg.shouldDebug ? debugLogLevel : .info)
        let logFormat = cfg.debugLogFormat ?? "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L $N.$F:$l - $M"
        
        if cfg.shouldDebug {
            let console = ConsoleDestination()
            console.useNSLog = true
            console.minLevel = logLevel
            console.format = logFormat
            log.addDestination(console)
        }

        let file = FileDestination(logFileURL: cfg._appexDebugLogURL)
        file.minLevel = logLevel
        file.format = logFormat
        file.logFileMaxSize = maxLogSize
        log.addDestination(file)

        // store path for clients
        cfg._appexSetDebugLogPath()
    }
    
    private func flushLog() {
        log.debug("Flushing log...")

        // XXX: should enforce SwiftyBeaver flush?
//        if let url = cfg.urlForDebugLog {
//            memoryLog.flush(to: url)
//        }
    }

    private func logCurrentSSID() {
        InterfaceObserver.fetchCurrentSSID {
            if let ssid = $0 {
                log.debug("Current SSID: '\(ssid.maskedDescription)'")
            } else {
                log.debug("Current SSID: none (disconnected from WiFi)")
            }
        }
    }

//    private func anyPointer(_ object: Any?) -> UnsafeMutableRawPointer {
//        let anyObject = object as AnyObject
//        return Unmanaged<AnyObject>.passUnretained(anyObject).toOpaque()
//    }

    // MARK: Errors
    
    private func setErrorStatus(with error: Error) {
        cfg._appexSetLastError(unifiedError(from: error))
    }
    
    private func unifiedError(from error: Error) -> OpenVPNProviderError {
        if let te = error.openVPNErrorCode() {
            switch te {
            case .cryptoRandomGenerator, .cryptoAlgorithm:
                return .encryptionInitialization
                
            case .cryptoEncryption, .cryptoHMAC:
                return .encryptionData
                
            case .tlscaRead, .tlscaUse, .tlscaPeerVerification,
                 .tlsClientCertificateRead, .tlsClientCertificateUse,
                 .tlsClientKeyRead, .tlsClientKeyUse:
                return .tlsInitialization
                
            case .tlsServerCertificate, .tlsServerEKU, .tlsServerHost:
                return .tlsServerVerification
                
            case .tlsHandshake:
                return .tlsHandshake
                
            case .dataPathOverflow, .dataPathPeerIdMismatch:
                return .unexpectedReply
                
            case .dataPathCompression:
                return .serverCompression
                
            default:
                break
            }
        } else if let se = error as? OpenVPNError {
            switch se {
            case .negotiationTimeout, .pingTimeout, .staleSession:
                return .timeout
                
            case .badCredentials:
                return .authentication
                
            case .serverCompression:
                return .serverCompression
                
            case .failedLinkWrite:
                return .linkError
                
            case .noRouting:
                return .routing
                
            case .serverShutdown:
                return .serverShutdown

            default:
                return .unexpectedReply
            }
        }
        return error as? OpenVPNProviderError ?? .linkError
    }
}

private extension Proxy {
    func neProxy() -> NEProxyServer {
        return NEProxyServer(address: address, port: Int(port))
    }
}

private extension OpenVPNTunnelAdapter {
    func forceExitOnMac() {
        #if os(macOS)
            exit(0)
        #endif
    }
}
