//
//  UITextField+.swift
//  Utilities
//
//  Created by Tung Nguyen on 13/10/2022.
//

import UIKit

public extension UITextField {
    
    func setPlaceholder(text: String, color: UIColor) {
        self.attributedPlaceholder = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: color])
    }
    
    func setupCustomDeleteIcon() {
        if let clearButton = self.value(forKeyPath: "_clearButton") as? UIButton {
            clearButton.setImage(UIImage(named: "delete_textfield_icon"), for: .normal)
        }
    }
    
}
