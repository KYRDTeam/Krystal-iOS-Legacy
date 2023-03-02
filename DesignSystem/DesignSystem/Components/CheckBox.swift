//
//  CheckBox.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 02/03/2023.
//

import Foundation
import UIKit

@IBDesignable
open class CheckBox: UIButton {
    
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
                setTitle("✓", for: .normal)
                setTitleColor(AppTheme.current.mainButtonTextColor, for: .normal)
                backgroundColor = _selectedBackgroundColor
                rounded(color: _selectedBackgroundColor, width: 1, radius: 4)
            } else {
                setTitle(nil, for: .normal)
                backgroundColor = .clear
                rounded(color: _normalBorderColor, width: 1, radius: 4)
            }
        }
    }
    
    @IBInspectable open var normalBorderColor: UIColor = AppTheme.current.secondaryTextColor {
        didSet {
            _normalBorderColor = normalBorderColor
        }
    }
    
    @IBInspectable open var selectedBackgroundColor: UIColor = AppTheme.current.primaryColor {
        didSet {
            _selectedBackgroundColor = selectedBackgroundColor
        }
    }
    
    @IBInspectable open var normalBorderWidth: CGFloat = 1.0 {
        didSet {
            _normalBorderWidth = normalBorderWidth
        }
    }
    
    private var _normalBorderColor: UIColor = AppTheme.current.secondaryTextColor
    private var _selectedBackgroundColor: UIColor = AppTheme.current.primaryColor
    private var _normalBorderWidth: CGFloat = 1.0
}
