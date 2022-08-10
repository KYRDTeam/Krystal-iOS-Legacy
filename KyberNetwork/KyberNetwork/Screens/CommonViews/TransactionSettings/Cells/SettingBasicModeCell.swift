//
//  SettingBasicModeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit

class SettingBasicModeCellModel {
  var selectedIndex = 2
  var actionHandler: (Int) -> Void = { _ in }
}


class SettingBasicModeCell: UITableViewCell {
  
  static let cellID: String = "SettingBasicModeCell"
  
  @IBOutlet weak var fastContainerView: UIView!
  @IBOutlet weak var standardContainerView: UIView!
  @IBOutlet weak var slowContainerView: UIView!
  @IBOutlet var optionViews: [UIView]!
  
  var cellModel: SettingBasicModeCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
  }
  
  @IBAction func optionButtonTapped(_ sender: UIButton) {
    let tag = sender.tag
    
    self.optionViews.forEach { item in
      let selected = item.tag == tag
      self.updateOptionViewsUI(aView: item, selected: selected)
    }
    
  }
  
  
  
  func updateOptionViewsUI(aView: UIView, selected: Bool) {
    aView.rounded(color: selected ? UIColor.Kyber.buttonBg : UIColor.Kyber.normalText, width: 1, radius: 14)
    if let priceView = aView.viewWithTag(9) as? UILabel {
      priceView.textColor = selected ? UIColor.Kyber.buttonBg : UIColor.Kyber.whiteText
    }
  }
}
