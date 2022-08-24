//
//  SettingExpertModeSwitchCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/08/2022.
//

import UIKit

class SettingExpertModeSwitchCellModel {

  var isOn: Bool = UserDefaults.standard.bool(forKey: Constants.expertModeSaveKey)
  var moreInforSelectHandle: () -> Void = {}
  var switchValueChangedHandle: (Bool) -> Void = { _ in }
  var tapTitleWithIndex: (Int) -> Void = { _ in }
  
  func resetData() {
    isOn = false
  }
  
}

class SettingExpertModeSwitchCell: UITableViewCell {
  var cellModel: SettingExpertModeSwitchCellModel!
  
  @IBOutlet weak var expertSwitch: UISwitch!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateUI() {
    self.expertSwitch.isOn = self.cellModel.isOn
  }

  @IBAction func infoButtonTapped(_ sender: UIButton) {
    self.cellModel.moreInforSelectHandle()
  }
  
  @IBAction func switchValueChanged(_ sender: UISwitch) {
    let selected = sender.isOn
    self.cellModel.isOn = selected
    self.cellModel.switchValueChangedHandle(selected)
  }
  
  @IBAction func titleLabelTapped(_ sender: UIButton) {
    cellModel.tapTitleWithIndex(sender.tag)
  }
  
}
