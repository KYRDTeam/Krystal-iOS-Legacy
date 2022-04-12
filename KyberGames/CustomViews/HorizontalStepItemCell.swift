//
//  HorizontalStepItemCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class HorizontalStepItemCell: UICollectionViewCell {
  
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var stepView: UIButton!
  
  enum State {
    case checked
    case today(isChecked: Bool, reward: Int)
    case unchecked(reward: Int)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  func configure(state: State, index: Int) {
    switch state {
    case .checked:
      stepView.backgroundColor = .active
      stepView.borderColor = .activeBorder
      stepView.borderWidth = 1
      stepView.setTitleColor(.base, for: .normal)
      stepView.setTitle("✓", for: .normal)
      detailLabel.text = "Day \(index + 1)"
    case .today(let isChecked, let reward):
      stepView.backgroundColor = .active
      stepView.borderColor = .activeBorder
      stepView.borderWidth = 1
      stepView.setTitleColor(.base, for: .normal)
      stepView.setTitle(isChecked ? "✓" : "+\(reward)", for: .normal)
      detailLabel.text = "Today"
    case .unchecked(let reward):
      stepView.backgroundColor = .elevation3
      stepView.borderColor = .elevation5
      stepView.borderWidth = 1
      stepView.setTitleColor(.white, for: .normal)
      stepView.setTitle("+\(reward)", for: .normal)
      detailLabel.text = "Day \(index + 1)"
    }
  }
  
}
