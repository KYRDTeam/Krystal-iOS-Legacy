//
//  MiniAppDetailCell.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit

class MiniAppDetailCell: UITableViewCell {
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var voteArrow: UIImageView!
  @IBOutlet weak var voteCountLabel: UILabel!
  @IBOutlet weak var voteContainer: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    voteContainer.isHidden = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(onTapVote))
    voteContainer.addGestureRecognizer(tap)
  }
  
  @objc func onTapVote() {
    guard let vote = Int(voteCountLabel.text ?? "") else {
      return
    }
    voteCountLabel.text = "\(vote) + 1"
    voteCountLabel.textColor = UIColor.Kyber.primaryGreenColor
    voteContainer.backgroundColor = UIColor.Kyber.primaryGreenColor.withAlphaComponent(0.1)
    voteArrow.image = UIImage(named: "change_up")
  }
  
  func configure(voteCount: Int, needShowVote: Bool = false) {
    voteCountLabel.text = "\(voteCount)"
    voteContainer.isHidden = !needShowVote
  }
  
}
