//
//  KNTransactionFilterTextCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/04/2022.
//

import UIKit

class KNTransactionFilterTextCell: UICollectionViewCell {
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var containerView: UIView!

  func configure(text: String, isSelected: Bool) {
    label.text = text
    label.textColor = isSelected ? .black : .white
    containerView.backgroundColor = isSelected ? UIColor.Kyber.selectedbuttonBackground : UIColor.Kyber.unselectedButtonBackground
  }
}
