//
//  TxInfoCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 08/11/2022.
//

import UIKit
import DesignSystem

class TxInfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var leftValueIcon: UIImageView!
    @IBOutlet weak var underlineView: DashedLineView!
    @IBOutlet weak var rightValueButton: UIButton!
    
    public var onTapRightButton: (() -> Void)?
    public var onTapTitle: (() -> Void)?
    public var onTapValue: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftValueIcon.isHidden = true
        
        iconImageView.isUserInteractionEnabled = true
        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rightIconWasTapped)))
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleWasTapped)))
        
        valueLabel.isUserInteractionEnabled = true
        valueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(valueWasTapped)))
    }
    
    @objc func rightIconWasTapped() {
        onTapRightButton?()
    }
    
    @objc func titleWasTapped() {
        onTapTitle?()
    }
    
    @objc func valueWasTapped() {
        onTapValue?()
    }
    
    public func configure(row: TxInfoRowData) {
        titleLabel.text = row.title
        underlineView.isHidden = !row.isTitleUnderlined
        valueLabel.text = row.value
        valueLabel.textColor = row.isHighlighted ? AppTheme.current.primaryColor : AppTheme.current.primaryTextColor
        valueLabel.font = row.isHighlighted ? .karlaMedium(ofSize: 14) : .karlaReguler(ofSize: 14)
        rightValueButton.isHidden = row.rightButtonTitle == nil
        rightValueButton.setTitle(row.rightButtonTitle, for: .normal)
        onTapRightButton = row.rightButtonClick
    }
    
    @IBAction func rightValueButtonTapped(_ sender: Any) {
        onTapRightButton?()
    }
    

}
