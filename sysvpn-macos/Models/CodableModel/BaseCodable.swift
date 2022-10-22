//
//  BaseCodable.swift
//
//  Created by doragon on 07/10/2022
//  Copyright (c) . All rights reserved.
//

import Foundation

struct BaseCodable<T : Decodable> : Decodable {
  var message: String?
  var result: T?
  var success: Bool?
}

func saveFilePath() -> URL {
  let fm = FileManager.default
    let file = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SYSVPN")
  return file
}


extension Encodable {
    
    func saveUserDefault(keyUserDefault: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: keyUserDefault)
        }
    }
    
    func saveFile(fileName: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            print("[CacheConfig] save data to file \(fileName) success")
            let directory = saveFilePath();
            if !FileManager.default.exist(atUrl: directory) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let urlFile = directory.appendingPathComponent(fileName)
            try? encoded.write(to: urlFile)
        }
    }
}

extension Decodable {
    static func readUserDefault(keyUserDefault: String) -> Decodable?{
        let defaults = UserDefaults.standard
        if let dataSave = defaults.object(forKey: keyUserDefault) as? Data {
            let decoder = JSONDecoder()
            if let loadData = try? decoder.decode(self, from: dataSave) {
                return loadData
            }
        }
        return nil
    }
     
    static func readFile(fileName: String) -> Decodable? {
        var data: Data?
        let urlFile = saveFilePath().appendingPathComponent(fileName)
        print("[CacheConfig] ",urlFile)
        if FileManager.default.exist(atUrl: urlFile)  {
           print("[CacheConfig] load config from cache")
           data = try? Data(contentsOf: urlFile)
        }
        guard let strongData = data else {
          return nil
        }
        
        let decoder = JSONDecoder()
        if let loadData = try? decoder.decode(self, from: strongData) {
            return loadData
        }
        return nil
    }
}
 
 
