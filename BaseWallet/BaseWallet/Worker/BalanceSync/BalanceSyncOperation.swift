//
//  BalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class BalanceSyncOperation: AsyncOperation {
    
    public override func main() {
        execute {
            self.finish()
        }
    }
    
    func execute(completion: @escaping () -> ()) {
        fatalError("Subclasses must implement this function")
    }
    
}
