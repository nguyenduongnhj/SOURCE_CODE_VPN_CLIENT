//
//  TestEcc.swift
//  sysvpn-macos
//
//  Created by doragon on 15/12/2022.
//

import Foundation
import CommonCrypto
let BEGIN_PKEY = "-----BEGIN PUBLIC KEY-----\n"
let END_PKEY = "\n-----END PUBLIC KEY-----"
struct ECPack : Codable {
    var params: String
    var data: String
    
    static var empty: ECPack {
        return ECPack(params: "", data: "")
    }
    
    var publicKey: String {
        return BEGIN_PKEY + params.trimmingCharacters(in: .whitespacesAndNewlines) + END_PKEY
    }
}
 
 
class ECCOpenSSL {
   static let shared = ECCOpenSSL()
    var ivString = "1234567881011121"
    var lastECKEY: OpaquePointer? = nil
    
    deinit {
        if let eckey = lastECKEY {
            EC_KEY_free(eckey)
        }
    }
    
    init() {
        initKey()
    }
    
    func encryptData(serverPubkey: String, data: String, myKey: OpaquePointer? = nil) -> ECPack {
        
        // generator pair key 32 bytes
        let myECKey = myKey ?? lastECKEY
        let keyBuffer = serverPubkey.toPointer()
        let keyLen = serverPubkey.count
        let seckeyLen = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        seckeyLen.pointee = 32
        guard let seckeyBuffer = get_secret_key(myECKey, keyBuffer, Int32(keyLen), seckeyLen) else {
            return ECPack.empty
        }
        
        //conver to key string
        let arrayData: [UInt8] = UnsafeMutableRawPointer(seckeyBuffer).toArray(to: UInt8.self, capacity: seckeyLen.pointee)
       
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256)
        let len = get_pubkey_string( myECKey , outBuffer)
        let strPublicKey = String(String(cString: outBuffer).prefix(len))
         
        free(outBuffer)
        free(seckeyBuffer)
        free(seckeyLen)
        
        
        return ECPack(params: strPublicKey, data:  data.aesEncrypt(key: Data(arrayData), iv: ivString) ?? "")
    }
    
    
    func decryptData(pack: ECPack, myKey: OpaquePointer? = nil)  -> ECPack {
        let myECKey = myKey ?? lastECKEY
        let keyBuffer = pack.publicKey.toPointer()
        let keyLen = pack.publicKey.count
        let seckeyLen = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        seckeyLen.pointee = 32
        
       
        guard let seckeyBuffer = get_secret_key(myECKey, keyBuffer, Int32(keyLen), seckeyLen) else {
            return ECPack.empty
        }
         
        
        let arrayData: [UInt8] = UnsafeMutableRawPointer(seckeyBuffer).toArray(to: UInt8.self, capacity: seckeyLen.pointee)
       
        
        free(seckeyLen)
        free(seckeyBuffer)
        
        
        return ECPack(params: pack.params, data: pack.data.aesDecrypt(key:  Data(arrayData), iv: ivString) ?? "")
        
    }
    
    func getPublicKey(myKey: OpaquePointer? = nil)  -> String {
        let myECKey = myKey ?? lastECKEY
        
       
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256)
        let len = get_pubkey_string( myECKey , outBuffer)
        let strPublicKey = String(cString: outBuffer)
         
        free(outBuffer)
        return String(strPublicKey.prefix(len)).replacingOccurrences(of: BEGIN_PKEY, with: "").replacingOccurrences(of: END_PKEY, with: "")
    }
    
    func initKey() {
        lastECKEY = create_key()
    }
    
    func ECDH() {
        let key = create_key()
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256)
        let len = get_pubkey_string( key , outBuffer)
        let strPublicKey = String(String(cString: outBuffer).prefix(len))
        
        lastECKEY = create_key()
        
       let packet = encryptData(serverPubkey: strPublicKey, data: "test")
       let packet2 = decryptData(pack: packet, myKey: key)
       /* free(outBuffer)
        print(strPublicKey.count)*/
       
        get_privateKey_string(lastECKEY, outBuffer)
        let privateKey = String(cString: outBuffer)
        print(strPublicKey)
        print(privateKey)
        
        print(packet)
       
    }
     
}


extension String {

  func toPointer() -> UnsafeMutablePointer<CChar>? {
    guard let data = self.data(using: String.Encoding.utf8) else { return nil }

    let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: data.count)
    let stream = OutputStream(toBuffer: buffer, capacity: data.count)

    stream.open()
    data.withUnsafeBytes({ (p: UnsafePointer<CChar>) -> Void in
      stream.write(p, maxLength: data.count)
    })

    stream.close()

    return buffer
  }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension UnsafeMutableRawPointer {
    func toArray<T>(to type: T.Type, capacity count: Int) -> [T]{
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}


extension String {

    func aesEncrypt(key: Data?, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key,
            let data = self.data(using: String.Encoding.utf8),
            let cryptData    = NSMutableData(length: Int((data.count)) + kCCBlockSizeAES128) {


            let keyLength              = size_t(kCCKeySizeAES256)
            let operation: CCOperation = UInt32(kCCEncrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES)
            let options:   CCOptions   = UInt32(options)



            var numBytesEncrypted :size_t = 0

            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyLength,
                                      iv,
                                      (data as NSData).bytes, data.count,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)

            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let base64cryptString = cryptData.base64EncodedString(options: .lineLength64Characters)
                return base64cryptString


            }
            else {
                return nil
            }
        }
        return nil
    }

    func aesDecrypt(key: Data?, iv:String, options:Int = kCCOptionPKCS7Padding) -> String? {
        if let keyData = key,
            let data = NSData(base64Encoded: self, options: .ignoreUnknownCharacters),
            let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {

            let keyLength              = size_t(kCCKeySizeAES256)
            let operation: CCOperation = UInt32(kCCDecrypt)
            let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES)
            let options:   CCOptions   = UInt32(options)

            var numBytesEncrypted :size_t = 0

            let cryptStatus = CCCrypt(operation,
                                      algoritm,
                                      options,
                                      (keyData as NSData).bytes, keyLength,
                                      iv,
                                      data.bytes, data.length,
                                      cryptData.mutableBytes, cryptData.length,
                                      &numBytesEncrypted)

            if UInt32(cryptStatus) == UInt32(kCCSuccess) {
                cryptData.length = Int(numBytesEncrypted)
                let unencryptedMessage = String(data: cryptData as Data, encoding:String.Encoding.utf8)
                return unencryptedMessage
            }
            else {
                return nil
            }
        }
        return nil
    }


}
