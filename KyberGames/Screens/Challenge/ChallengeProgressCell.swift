//
//  ChallengeProgressCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class ChallengeProgressCell: UICollectionViewCell {
  
  @IBOutlet weak var stepButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var progressLabel: UILabel!
  @IBOutlet weak var progressContainerView: UIView!
  @IBOutlet weak var progressWidth: NSLayoutConstraint!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
}
