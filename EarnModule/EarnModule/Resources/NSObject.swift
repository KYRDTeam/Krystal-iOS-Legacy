//
//  NSObject.swift
//  EarnModule
//
//  Created by Com1 on 25/10/2022.
//

import Foundation

extension NSObject {
    var className: String {
        return String(describing: type(of: self)).components(separatedBy: ".").last!
    }

    class var className: String {
        return String(describing: self).components(separatedBy: ".").last!
    }
}
