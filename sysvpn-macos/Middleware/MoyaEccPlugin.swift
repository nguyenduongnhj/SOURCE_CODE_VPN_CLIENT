//
//  MoyaEccPlugin.swift
//  sysvpn-macos
//
//  Created by macbook on 02/01/2023.
//

import Foundation


import Moya

struct MoyaECCPlugin: PluginType {
    
    var publicKEy: String {
        return Constant.SERVER.PublicKey
    }
    
    let ecc = ECCOpenSSL()
    
    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        
        guard let target = target as? ECTargetType, target.needEncrypt else {
            return result
        }
        
        switch result {
            case .failure:
            return result
            case .success(let response):
            
            guard let result = try? JSONDecoder().decode(ECPack.self, from: response.data) else {
                return result
            }
            let outData = ecc.decryptData(pack: result).data.data(using: .utf8) ?? response.data
            
            return .success(Response(statusCode: response.statusCode, data: outData))
             
        }
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
       
        guard let target = target as? ECTargetType, target.needEncrypt else {
            return request
        }
        
        var newRequest = request
        newRequest.setValue("application/json", forHTTPHeaderField: "content-type" )
        
        if (request.method == .get || request.method ==  .delete ) {
            newRequest.method = .post
            newRequest.httpBody = try? ECPack(params: ecc.getPublicKey(), data: "").toJSON()
           
            return newRequest
        } else {
            if let data = request.httpBody {
                let json = try? ecc.encryptData(serverPubkey: publicKEy, data: String(data: data, encoding: .utf8) ?? "").toJSON()
                newRequest.httpBody = json
            }
            return newRequest
        }
    }
}

 

extension Encodable {
    func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        let data = try encoder.encode(self)
        return data
    }
}

protocol ECTargetType: TargetType {
    var needEncrypt: Bool { get }
}
