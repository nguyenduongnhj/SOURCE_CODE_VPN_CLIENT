//
//  XPCServiceUser.swift
//  TunnelKitHost
//
//  Created by macbook on 15/10/2022.
//  Copyright © 2022 Davide De Rosa. All rights reserved.
//

import Foundation

class XPCServiceUser {
    private let machServiceName: String
    private let log: (String) -> Void
    public var isConnected: Bool = false {
        didSet {
            if isConnected {
                isAvailable = false
            }
        }
    }

    public var isAvailable: Bool = false
    
    private var isCheckingConnection = false
    var failedCount: Int = 0
    private var currentConnection: NSXPCConnection? {
        willSet {
            if newValue == nil {
                currentConnection?.invalidate()
            }
        }
    }

    init(withExtension machServiceName: String, logger: @escaping (String) -> Void) {
        self.machServiceName = machServiceName
        log = logger
    }

    // MARK: - Private

    private var connection: NSXPCConnection {
        if let currentConnection = currentConnection {
            return currentConnection
        }
        
        return createConnection()
    }
    
    private func createConnection() -> NSXPCConnection {
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // The exported object is the delegate.
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { [weak self] in
            print("invalidationHandler")
            if (self?.failedCount ?? 0) > 5 {
                return
            }
            if self?.isCheckingConnection != false {
                return
            }
            self?.failedCount = (self?.failedCount ?? 0) + 1
            self?.isConnected = false
            DispatchQueue.main.async {
                self?.checkConnect()
            }
        }

        newConnection.interruptionHandler = { [weak self] in
            print("interruptionHandler")
            if self?.isCheckingConnection != false {
                return
            }
            self?.isCheckingConnection = true
            self?.isConnected = false
            self?.createConnection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.checkConnect()
            }
        }
        // The remote object is the provider's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        currentConnection = newConnection
        newConnection.resume()
        
        return newConnection
    }
}

extension XPCServiceUser {
    func getProviderProxy(retry: Bool = true, onError: (() -> Void)? = nil) -> ProviderCommunication? {
        guard let providerProxy = connection.remoteObjectProxyWithErrorHandler({ registerError in
            self.log("Failed to get remote object proxy \(self.machServiceName): \(String(describing: registerError))")
            self.currentConnection = nil
            onError?()
            _ = self.createConnection()
        }) as? ProviderCommunication else {
            log("Failed to create a remote object proxy for the provider: \(machServiceName)")
            return nil
        }
        return providerProxy
    }
    
    func checkConnect(completion: (() -> Void)? = nil) {
        isCheckingConnection = true
        getLogs { data in
            if data != nil {
                self.isConnected = true
                print("[IPC] check connected success")
                self.failedCount = 0
            }
            self.isCheckingConnection = false
          
            completion?()
        }
    }

    func getLogs(completionHandler: @escaping (Data?) -> Void) {
        let providerProxy = getProviderProxy(onError: {
            completionHandler(nil)
        })
        providerProxy?.getLogs(completionHandler)
    }
    
    func setProtocol(_ nameProtocol: String) {
        let providerProxy = getProviderProxy()
        providerProxy?.setProtocol(vpnProtocol: nameProtocol)
    }
    
    func getProtocol(completion: @escaping (String) -> Void) {
        let providerProxy = getProviderProxy()
        providerProxy?.getProtocol(completion)
    }
    
    func request(urlRequest: URLRequest, completion: @escaping (XPCHttpResponse) -> Void) {
        if let providerProxy = getProviderProxy(onError: {
            let response = XPCHttpResponse(statusCode: -1, data: nil, error: NSError(domain: MoyaIPCErrorDomain.unknownError, code: -1))
            completion(response)
        }) {
            var request: [String: NSObject] = [
                HttpFieldName.method.rawValue: (urlRequest.method?.rawValue ?? "GET") as NSObject,
                HttpFieldName.headers.rawValue: (urlRequest.allHTTPHeaderFields ?? [:]) as NSObject
            ]
            
            if let body = urlRequest.httpBody {
                request[HttpFieldName.body.rawValue] = body as NSObject
            }
            
            if let url = urlRequest.url?.absoluteString {
                request[HttpFieldName.url.rawValue] = url as NSObject
            }
            
            providerProxy.request(request: request, completionHandler: { data in
                var requestError: NSError?
                var requestStatusCode = 0
                if let statusCode = data[HttpFieldName.statusCode.rawValue] as? Int {
                    requestStatusCode = statusCode
                }
                
                if let error = data[HttpFieldName.error.rawValue] as? String {
                    requestError = NSError(domain: error, code: requestStatusCode)
                }
                
                let response = XPCHttpResponse(statusCode: requestStatusCode, data: data[HttpFieldName.data.rawValue] as? Data, error: requestError)
                completion(response)
            })
        } else {
            let response = XPCHttpResponse(statusCode: -1, data: nil, error: NSError(domain: MoyaIPCErrorDomain.unknownError, code: -1))
            completion(response)
        }
    }
}

extension XPCServiceUser: AppCommunication {}
