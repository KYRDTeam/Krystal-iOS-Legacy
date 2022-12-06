//
//  NSObject+.swift
//  Utilities
//
//  Created by Com1 on 01/12/2022.
//

import Foundation

public extension NSObject {
    var className: String {
        return String(describing: type(of: self)).components(separatedBy: ".").last!
    }

    class var className: String {
        return String(describing: self).components(separatedBy: ".").last!
    }
}
