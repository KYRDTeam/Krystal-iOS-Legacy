//
//  TxToggleInfoView.swift
//  DesignSystem
//
//  Created by Com1 on 23/11/2022.
//

import UIKit
import Utilities


public class TxToggleInfoView: BaseXibView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
    var isOn: Bool = false
    public var onSwitchValue: ((Bool) -> ())?

    @IBInspectable var valueAccessibilityID: String? {
      didSet {
        switchButton.accessibilityID = valueAccessibilityID
      }
    }
    
    public override func commonInit() {
        super.commonInit()
        switchButton.setOn(isOn, animated: false)
        switchButton.onTintColor = AppTheme.current.primaryColor
    }
    
    @IBAction func onSwitchButtonTapped(_ sender: Any) {
        isOn.toggle()
        onSwitchValue?(isOn)
    }
    
    public func setTitle(title: String) {
        titleLabel.text = title
    }
    
    public func setToggleValue(isOn: Bool) {
        self.isOn = isOn
        switchButton.setOn(isOn, animated: false)
    }
    
}
