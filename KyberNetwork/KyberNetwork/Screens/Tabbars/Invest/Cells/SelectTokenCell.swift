//
//  SelectTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 18/05/2022.
//

import UIKit

class SelectTokenCell: UITableViewCell {
  @IBOutlet weak var selectTokenButton: UIButton!
  var selectTokenBlock: (() -> Void)?
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
    
  @IBAction func selectTokenButtonTapped(_ sender: Any) {
    if let selectTokenBlock = selectTokenBlock {
      selectTokenBlock()
    }
  }
}
