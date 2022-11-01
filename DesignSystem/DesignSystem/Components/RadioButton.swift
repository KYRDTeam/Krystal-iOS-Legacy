//
//  RadioButton.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import UIKit

@IBDesignable
open class RadioButton: UIButton {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        isChecked = false
        setTitle(nil, for: .normal)
    }
    
    public var isChecked: Bool = false {
        didSet {
            if isChecked {
                rounded(color: _selectedBorderColor,
                        width: _selectedBorderWidth,
                        radius: frame.width / 2)
            } else {
                rounded(color: _normalBorderColor,
                        width: _normalBorderWidth,
                        radius: frame.width / 2)
            }
        }
    }
    
    @IBInspectable open var normalBorderColor: UIColor = AppTheme.current.secondaryTextColor {
        didSet {
            _normalBorderColor = normalBorderColor
        }
    }
    
    @IBInspectable open var selectedBorderColor: UIColor = AppTheme.current.primaryColor {
        didSet {
            _selectedBorderColor = selectedBorderColor
        }
    }
    
    @IBInspectable open var selectedBorderWidth: CGFloat = 4.0 {
        didSet {
            _selectedBorderWidth = selectedBorderWidth
        }
    }
    
    @IBInspectable open var normalBorderWidth: CGFloat = 1.0 {
        didSet {
            _normalBorderWidth = normalBorderWidth
        }
    }
    
    private var _normalBorderColor: UIColor = AppTheme.current.secondaryTextColor
    private var _selectedBorderColor: UIColor = AppTheme.current.primaryColor
    private var _selectedBorderWidth: CGFloat = 4.0
    private var _normalBorderWidth: CGFloat = 1.0
}
