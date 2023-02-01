//
//  ChainSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class ChainSyncOperation: AsyncOperation {
    
    override func main() {
        execute { chains in
            self.finish()
        }
    }
    
    func execute(completion: @escaping ([Chain]) -> ()) {
        fatalError("Subclasses must implement this function")
    }
    
}
