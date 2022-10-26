//
//  Collection+.swift
//  Utilities
//
//  Created by Tung Nguyen on 26/10/2022.
//

import Foundation

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
