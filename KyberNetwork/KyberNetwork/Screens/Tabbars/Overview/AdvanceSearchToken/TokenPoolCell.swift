//
//  TokenPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 20/06/2022.
//

import UIKit

class TokenPoolCell: UITableViewCell {

  @IBOutlet weak var token0Icon: UIImageView!
  @IBOutlet weak var token1Icon: UIImageView!
  @IBOutlet weak var pairNameLabel: UILabel!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
    
  func updateUI(poolDetail: TokenPoolDetail) {
    if let url = URL(string: poolDetail.token0.logo) {
      token0Icon.setImage(with: url, placeholder: nil)
    }
    if let url = URL(string: poolDetail.token1.logo) {
      token1Icon.setImage(with: url, placeholder: nil)
    }
    
    self.pairNameLabel.text = "\(poolDetail.token0.symbol)/\(poolDetail.token1.symbol)"
    self.fullNameLabel.text = poolDetail.token0.name
    self.valueLabel.text = "$\(poolDetail.token0.usdValue)"
    self.chainIcon.image = ChainType.make(chainID: poolDetail.chainId)?.chainIcon()
    self.addressLabel.text = "\(poolDetail.address.prefix(7))...\(poolDetail.address.suffix(4))"
    self.totalValueLabel.text = "$\(poolDetail.tvl)"
  }
}
