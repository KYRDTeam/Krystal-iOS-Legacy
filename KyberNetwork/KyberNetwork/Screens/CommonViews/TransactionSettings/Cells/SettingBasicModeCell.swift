//
//  SettingBasicModeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit
import BigInt

class SettingBasicModeCellModel {
  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  var gasLimit: BigInt = .zero
  var selectedIndex = 2
  var actionHandler: (Int) -> Void = { _ in }
  
  func resetData() {
    fast = KNGasCoordinator.shared.fastKNGas
    medium = KNGasCoordinator.shared.standardKNGas
    slow = KNGasCoordinator.shared.lowKNGas
    selectedIndex = 2
  }
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
  
  func updateUI() {
    self.optionViews.forEach { item in
      let selected = self.cellModel.selectedIndex == item.tag
      self.updateOptionViewsUI(aView: item, selected: selected)
    }
  }
  
  @IBAction func optionButtonTapped(_ sender: UIButton) {
    let tag = sender.tag
    self.cellModel.selectedIndex = tag
    self.updateUI()
    cellModel.actionHandler(tag)
  }
  
  func updateOptionViewsUI(aView: UIView, selected: Bool) {
    aView.rounded(color: selected ? UIColor.Kyber.buttonBg : UIColor.Kyber.normalText, width: 1, radius: 14)
    if let priceView = aView.viewWithTag(9) as? UILabel {
      priceView.textColor = selected ? UIColor.Kyber.buttonBg : UIColor.Kyber.whiteText
      switch aView.tag {
      case 3:
        priceView.text = cellModel.fast.formatFeeString(gasLimit: cellModel.gasLimit, type: 3)
      case 2:
        priceView.text = cellModel.medium.formatFeeString(gasLimit: cellModel.gasLimit, type: 2)
      case 1:
        priceView.text = cellModel.slow.formatFeeString(gasLimit: cellModel.gasLimit, type: 1)
      default:
        break
      }
    }
    if let gweiValue = aView.viewWithTag(10) as? UILabel {
      switch aView.tag {
      case 3:
        gweiValue.text = cellModel.fast.displayGWEI()
      case 2:
        gweiValue.text = cellModel.medium.displayGWEI()
      case 1:
        gweiValue.text = cellModel.slow.displayGWEI()
      default:
        break
      }
    }
  }
}
