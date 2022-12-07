//
//  BaseServiceManager.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 30/08/2022.
//

import Foundation
import Moya
import RxMoya
import RxSwift
import SwiftyJSON

class BaseServiceManager<API: TargetType> {
//    private let provider = MoyaProvider<API>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .formatRequestAscURL))])
    private let provider = MoyaProvider<API>()
    init() {
        provider.session.sessionConfiguration.timeoutIntervalForRequest = 10
        provider.session.sessionConfiguration.timeoutIntervalForResource = 10
    }
    
    func request(_ api: API) -> Single<Response> {
        print("[URL]: \(api.baseURL)\(api.path)")
        return provider.rx.request(api)
            .flatMap {
                if $0.statusCode == 401 {
                    if AppDataManager.shared.isLogin {
                        throw TokenError.tokenExpired
                    } else {
                        throw TokenError.notSignin
                    }
                    
                } else {
                    return Single.just($0)
                }
            }
            .retry { (error: Observable<TokenError>) in
                error.flatMap { error -> Single<Bool> in
                    if error == TokenError.tokenExpired {
                        return self.refreshToken()
                    } else {
                        throw error
                    }
                }
            }
            .handleResponse()
            .filterSuccessfulStatusCodes()
    }
    
    func requestIPC(_ api: API) -> Single<Response> {
        if !(IPCFactory.makeIPCRequestService().isConnected) {
            return request(api)
        }
        
        return provider.rx.requestIPC(api)
            .flatMap {
                if $0.statusCode == 401 {
                    if AppDataManager.shared.isLogin {
                        throw TokenError.tokenExpired
                    } else {
                        throw TokenError.notSignin
                    }
                } else {
                    return Single.just($0)
                }
            }
            .retry { (error: Observable<TokenError>) in
                error.flatMap { error -> Single<Bool> in
                    if error == TokenError.tokenExpired {
                        return self.refreshToken()
                    } else {
                        throw error
                    }
                }
            }
            .handleResponse()
            .filterSuccessfulStatusCodes()
    }
    
    func cancelTask() {
        provider.session.session.finishTasksAndInvalidate()
    }
    
    func refreshToken() -> Single<Bool> {
        if !AppDataManager.shared.isLogin {
            let genericError = ResponseError(statusCode: 0,
                                             message: "not signin")
            return Single.error(genericError)
        }
        return provider.rx.requestIPC(APIService.refreshToken as! API)
            .handleResponse()
            .filterSuccessfulStatusCodes()
            .handleApiResponseCodable(type: AuthResult.self)
            .flatMap { token in
                if !AppDataManager.shared.isLogin {
                    throw TokenError.notSignin
                }
                AppDataManager.shared.refreshToken = token.tokens?.refresh
                AppDataManager.shared.accessToken = token.tokens?.access
                return Single.just(true)
            }
            .do(onError: { error in
                print("[TOKEN] refresh error \(error)")
                DispatchQueue.main.async {
                    AppDataManager.shared.logOut(openWindow: true, manual: false)
                }
            })
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    func handleResponse() -> Single<Element> {
        return flatMap { response in
            print("[URL] status \(response.statusCode)")
            print("[URL]: \(response.request?.url?.path)")
            if (200...299) ~= response.statusCode {
                return Single.just(response)
            }
            
            if var error = try? response.map(ResponseError.self) {
                error.statusCode = response.statusCode
                 
                return Single.error(error)
            }
            
            // Its an error and can't decode error details from server, push generic message
            let genericError = ResponseError(statusCode: response.statusCode,
                                             message: "empty message")
            
            return Single.error(genericError)
        }
    }
    
    func handleApiResponse<T: BaseModel>(type: T.Type) -> Single<T> {
        return flatMap { response in
            let data = try? JSON(data: response.data)
             
            let result = BaseResponseModel<T>(json: data)
            print("[RESPONSE]: \(data ?? "")")
            
            if !(result?.success ?? false) {
                let genericError = ResponseError(statusCode: response.statusCode,
                                                 message: result?.message ?? "")
                print("[RESULT ERROR]: \(genericError)")
                return Single.error(genericError)
            }
            
            guard let strongResult = result?.result else {
                let genericError = ResponseError(statusCode: response.statusCode,
                                                 message: "parse data error")
                print("[PARSE ERROR]: \(genericError)")
                return Single.error(genericError)
            }
            return Single.just(strongResult)
        }
    }
    
    func handleApiResponseCodable<T: Decodable>(type: T.Type) -> Single<T> {
        return flatMap { response in
            do {
                print("[RESPONSE]: \(String(data: response.data, encoding: .utf8) ?? "")")
                let result = try JSONDecoder().decode(BaseCodable<T>.self, from: response.data)
                if !result.success {
                    let genericError = ResponseError(statusCode: response.statusCode,
                                                     message: result.message, error: result.errors.first ?? "")
                    print("[RESULT ERROR]: \(genericError)")
                    return Single.error(genericError)
                }
                
                guard let strongResult = result.result else {
                    let genericError = ResponseError(statusCode: response.statusCode,
                                                     message: "parse data error")
                    print("[PARSE ERROR]: \(genericError)")
                    return Single.error(genericError)
                }
                
                return Single.just(strongResult)
            } catch let e {
                let genericError = ResponseError(statusCode: response.statusCode,
                                                 message: e.localizedDescription)
             
                print("[CACTH ERROR]: \(genericError)")
                return Single.error(genericError)
            }
        }
    }
    
    func handleEmptyResponse() -> Single<Bool> {
        return flatMap { response in
            print("[RESPONSE]: \(String(data: response.data, encoding: .utf8) ?? "")")
            let data = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any]
            if !((data?["success"] as? Bool) ?? false) {
                return Single.just(false)
            }
            return Single.just(true)
        }
    }
}

struct ResponseError: Decodable, Error {
    var statusCode: Int?
    let message: String
    var error: String = ""
    var description: String {
        return message
    }
}

enum TokenError: Swift.Error {
    case tokenExpired
    case notSignin
}

enum APICallerResult<T> {
    case success(T?)
    case failure(Error)
}
 
