//
//  Once.swift
//  Utilities
//
//  Created by Tung Nguyen on 27/12/2022.
//

import Foundation

public class Once {
    
    var already: Bool = false
    
    public init() {}
    
    public func run(block: () -> Void) {
        guard !already else { return }
        
        block()
        already = true
    }
    
}
