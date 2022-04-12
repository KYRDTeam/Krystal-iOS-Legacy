//
//  UIViewController+.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

extension UIViewController {
    
    static func instantiateFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: Bundle(for: T.self))
        }
        return instantiateFromNib(self)
    }
    
}
