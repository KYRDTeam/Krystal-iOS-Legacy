//
//  SettingSegmentedCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit

class SettingSegmentedCellModel {
  var valueChangeHandler: (Int) -> Void = { _ in
    
  }
}

class SettingSegmentedCell: UITableViewCell {
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  static let cellID: String = "SettingSegmentedCell"
  
  var cellModel: SettingSegmentedCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!, NSAttributedString.Key.font: UIFont.Kyber.regular(with: 12)], for: .normal)
    segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!, NSAttributedString.Key.font: UIFont.Kyber.regular(with: 12)], for: .selected)
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    cellModel.valueChangeHandler(sender.selectedSegmentIndex)
  }
  
}
