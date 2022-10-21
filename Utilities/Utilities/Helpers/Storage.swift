//
//  Storage.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation

public class Storage {
    
    public static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func retrieve<T: Decodable>(_ fileName: String, as type: T.Type) -> T? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
        if !FileManager.default.fileExists(atPath: url.path) {
            print("[Load file][Error] \(fileName)")
            return nil
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                print("[Load file][Success] \(fileName)")
                return model
            } catch {
                print("[Load file][Error] \(fileName)")
                return nil
            }
        } else {
            print("[Load file][Error] \(fileName)")
            return nil
        }
    }
    
    public static func store<T: Encodable>(_ object: T, as fileName: String) {
        DispatchQueue.global(qos: .background).async {
            let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(object)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
                print("[Store file][Success] \(fileName)")
            } catch {
                print("[Store file][Error] \(error.localizedDescription)")
            }
        }
    }
    
    public static func isFileExistAtPath(_ fileName: String) -> Bool {
        let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public static func removeFileAtPath(_ fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: url)
            print("[Delete file][Success]")
        } catch {
            print("[Delete file][Error] \(error.localizedDescription)")
        }
    }
    
}
