//
//  SelectChainCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class SelectChainCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var arrowIcon: UIImageView!
  
  var selectionBlock: (() -> Void)?
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  @IBAction func onSelectChainButtonTapped(_ sender: Any) {
    if let selectionBlock = selectionBlock {
      selectionBlock()
    }
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }
    
}
