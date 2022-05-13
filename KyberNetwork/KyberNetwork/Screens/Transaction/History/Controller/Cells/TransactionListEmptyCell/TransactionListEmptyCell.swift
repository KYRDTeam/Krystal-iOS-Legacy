//
//  TransactionListEmptyCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import UIKit

class TransactionListEmptyCell: UICollectionViewCell {
  
  var onTapSwap: (() -> ())?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  @IBAction func onTapSwapNow(_ sender: Any) {
    onTapSwap?()
  }
  
}
