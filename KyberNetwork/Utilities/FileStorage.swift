//
//  FileStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 07/12/2022.
//

import Foundation
import SwiftUI

@propertyWrapper
struct FileStorage<T: Codable> {
    let fileName: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            return Storage.retrieve(fileName, as: T.self) ?? defaultValue
        }
        
        set {
            Storage.store(newValue, as: fileName)
        }
    }
}
