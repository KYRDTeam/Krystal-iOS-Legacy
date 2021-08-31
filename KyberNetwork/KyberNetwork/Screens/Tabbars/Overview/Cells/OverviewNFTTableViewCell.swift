//
//  OverviewNFTTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 18/08/2021.
//

import UIKit

struct OverviewNFTCellViewModel {
  let item1: NFTItem?
  let item2: NFTItem?
  let category1: NFTSection?
  let category2: NFTSection?
  
}

class OverviewNFTTableViewCell: UITableViewCell {
  static let kCellID: String = "OverviewNFTTableViewCell"
  static let kCellHeight: CGFloat = 240
  
  @IBOutlet weak var icon1: UIImageView!
  @IBOutlet weak var tokenName1: UILabel!
  @IBOutlet weak var tokenId1: UILabel!
  @IBOutlet weak var container1: UIView!
  
  @IBOutlet weak var icon2: UIImageView!
  @IBOutlet weak var tokenName2: UILabel!
  @IBOutlet weak var tokenId2: UILabel!
  @IBOutlet weak var container2: UIView!
  
  var viewModel: OverviewNFTCellViewModel?
  var completeHandle: ((NFTItem, NFTSection) -> Void)?
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    container1.rounded(radius: 16)
    container2.rounded(radius: 16)
    icon1.rounded(radius: 10)
    icon2.rounded(radius: 10)
  }
  
  func updateCell(_ viewModel: OverviewNFTCellViewModel) {
    self.container1.isHidden = viewModel.item1 == nil
    self.container2.isHidden = viewModel.item2 == nil
    
    if let notNil1 = viewModel.item1 {
      self.icon1.setImage(with: notNil1.externalData.image, placeholder: UIImage(named: "placeholder_nft_item")!, size: nil, applyNoir: false)
      self.tokenName1.text = notNil1.externalData.name
      self.tokenId1.text = "#" + notNil1.tokenID
    }
    
    if let notNil2 = viewModel.item2 {
      self.icon2.setImage(with: notNil2.externalData.image, placeholder: UIImage(named: "placeholder_nft_item")!, size: nil, applyNoir: false)
      self.tokenName2.text = notNil2.externalData.name
      self.tokenId2.text = "#" + notNil2.tokenID
    }
    
    self.viewModel = viewModel
  }
  
  @IBAction func item1Tapped(_ sender: UIButton) {
    guard let notNil = self.viewModel, let block = self.completeHandle else {
      return
    }
    if sender.tag == 0 {
      if let unwrap = notNil.item1, let unwrapCategory = notNil.category1 {
        block(unwrap, unwrapCategory)
      }
    } else {
      if let unwrap = notNil.item2, let unwrapCategory = notNil.category2 {
        block(unwrap, unwrapCategory)
      }
    }
  }
  
}
