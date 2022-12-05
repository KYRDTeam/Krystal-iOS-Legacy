//
//  SettingSegmentedCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit
import DesignSystem

class SettingSegmentedCellModel {
  var selectedIndex = 0
  var valueChangeHandler: (Int) -> Void = { _ in
    
  }
  
  func resetData() {
    selectedIndex = 0
  }
}

class SettingSegmentedCell: UITableViewCell {
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  var cellModel: SettingSegmentedCellModel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
      segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!, NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 12)], for: .normal)
    segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!, NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 12)], for: .selected)
  }
  
  func updateUI() {
    segmentedControl.selectedSegmentIndex = cellModel.selectedIndex
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    cellModel.selectedIndex = sender.selectedSegmentIndex
    cellModel.valueChangeHandler(sender.selectedSegmentIndex)
  }
  
}
