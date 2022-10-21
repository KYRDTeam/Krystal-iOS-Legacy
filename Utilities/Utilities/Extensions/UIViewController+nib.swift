//
//  UIViewController+nib.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

public extension UIViewController {
    
    static func instantiateFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: Bundle(for: T.self))
        }
        return instantiateFromNib(self)
    }
    
}
