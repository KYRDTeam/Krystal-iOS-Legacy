//
//  TokenSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

class TokenSyncOperation: AsyncOperation {
    
    public override func main() {
        execute {
            self.finish()
        }
    }
    
    func execute(completion: @escaping () -> ()) {
        fatalError("Subclasses must implement this function")
    }
    
    
}
