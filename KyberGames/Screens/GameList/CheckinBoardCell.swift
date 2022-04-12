//
//  CheckinBoardCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class CheckinBoardCell: UICollectionViewCell {
  @IBOutlet weak var stepProgressView: StepProgressView!
  @IBOutlet weak var separator: UIView!
  @IBOutlet weak var checkBox: UIButton!
  
  let totalSteps = 7
  let connectionLineHeight: CGFloat = 4
  var currentStep = 2
  var isTodayCheck = false
  
  var notificationTap: ((Bool) -> ())?
  var checkinTap: (() -> ())?
  
  var isNotifyOn: Bool = true {
    didSet {
      self.updateNotifyUI()
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupSubviews()
    setupStepView()
    updateNotifyUI()
  }
  
  func setupSubviews() {
    separator.clipsToBounds = true
    separator.createDashedLine(
      startPoint: .zero, endPoint: .init(x: frame.width - 80, y: 0),
      color: .elevation3, strokeLength: 4, gapLength: 4, width: 1)
  }
  
  func setupStepView() {
    stepProgressView.delegate = self
    stepProgressView.dataSource = self
    
    stepProgressView.registerCellNib(HorizontalStepItemCell.self)
    stepProgressView.reload()
  }
  
  func updateNotifyUI() {
    checkBox.backgroundColor = isNotifyOn ? .active : .elevation3
    checkBox.borderColor = isNotifyOn ? .activeBorder : .elevation5
    checkBox.setTitle(isNotifyOn ? "✓" : "", for: .normal)
    checkBox.setTitleColor(.elevation3, for: .normal)
  }
  
  @IBAction func checkBoxWasTapped(_ sender: Any) {
    notificationTap?(isNotifyOn)
  }

  @IBAction func checkinWasTapped(_ sender: Any) {
    checkinTap?()
  }
  
}

extension CheckinBoardCell: StepProgressViewDataSource, StepProgressViewDelegate {
  
  func stepProgressView(_ stepProgressView: StepProgressView, cellForItemAt index: Int) -> UICollectionViewCell {
    let cell = stepProgressView.dequeueReusableCell(HorizontalStepItemCell.self, for: index)!
    if index < currentStep {
      cell.configure(state: .checked, index: index)
    } else if index == currentStep {
      cell.configure(state: .today(isChecked: isTodayCheck, reward: 1), index: index)
    } else {
      cell.configure(state: .unchecked(reward: 1), index: index)
    }
    return cell
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, sizeForItemAt index: Int) -> CGSize {
    return .init(width: 36, height: 64)
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, frameForConnectionLineAfter index: Int) -> CGRect {
    if index == totalSteps - 1 {
      return .zero
    }
    let center1 = stepProgressView.center(ofItemAt: index)
    let center2 = stepProgressView.center(ofItemAt: index + 1)
    return .init(x: center1.x, y: 16 - connectionLineHeight / 2,
                 width: center2.x - center1.x, height: connectionLineHeight)
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, colorForConnectionLineAfter index: Int) -> UIColor {
    if index < currentStep {
      return .activeConnection
    } else {
      return .elevation3
    }
  }
  
  func numberOfItems(_ stepProgressView: StepProgressView) -> Int {
    return totalSteps
  }
  
  func itemSpacing(_ stepProgressView: StepProgressView) -> CGFloat {
    return (stepProgressView.frame.width - CGFloat(totalSteps * 36)) / CGFloat(totalSteps - 1)
  }
  
}
