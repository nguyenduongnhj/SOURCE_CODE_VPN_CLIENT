//
//  BaseServiceManager.swift
//  sysvpn-macos
//
//  Created by Nguyen Dinh Thach on 30/08/2022.
//

import Moya
import RxMoya
import RxSwift
import SwiftyJSON

class BaseServiceManager<API: TargetType> {
    private let provider = MoyaProvider<API>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .formatRequestAscURL))])
    
    init() {
        provider.session.sessionConfiguration.timeoutIntervalForRequest = 10
        provider.session.sessionConfiguration.timeoutIntervalForResource = 10
    }
    
    func request(_ api: API) -> Single<Response> {
        return provider.rx.request(api)
            .flatMap {
                if $0.statusCode == 401 {
                    throw TokenError.tokenExpired
                } else {
                    return Single.just($0)
                }
            }
            .retry { (error: Observable<TokenError>) in
                // TODO: Handle refresh token
                error
//                error.flatMap { error -> Single<APIResponse<RegisterResultModel>> in
//
//                }
            }
            .handleResponse()
            .filterSuccessfulStatusCodes()
            .retry(2)
    }
    
    func cancelTask() {
        provider.session.session.finishTasksAndInvalidate()
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    func handleResponse() -> Single<Element> {
        return flatMap { response in
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
            
            if !(result?.success ?? false) {
                let genericError = ResponseError(statusCode: response.statusCode,
                                                 message: result?.message ?? "")
                return Single.error(genericError)
            }
            
            guard let strongResult = result?.result else {
                let genericError = ResponseError(statusCode: response.statusCode,
                                                 message: "parse data error")
                return Single.error(genericError)
            }
       
            return Single.just(strongResult)
        }
    }
}

struct ResponseError: Decodable, Error {
    var statusCode: Int?
    let message: String
}

enum TokenError: Swift.Error {
    case tokenExpired
}

enum APICallerResult<T> {
    case success(T?)
    case failure(Error)
}
 