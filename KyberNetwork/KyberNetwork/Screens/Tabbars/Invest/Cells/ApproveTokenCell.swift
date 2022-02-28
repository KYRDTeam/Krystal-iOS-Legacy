//
//  ApproveTokenCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/02/2022.
//

import UIKit
enum AppproveState {
  case notStart
  case start
  case done
}

class ApproveTokenCellModel {
  var token: Token
  var state: AppproveState = .notStart
  
  init(token: Token) {
    self.token = token
  }
}

class ApproveTokenCell: UITableViewCell {
  
  static let cellHeight: CGFloat = 36
  static let cellID: String = "ApproveTokenCell"
  
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var loadingView: SRCountdownTimer!
  @IBOutlet weak var doneIconImgView: UIImageView!
  
  
  var cellModel: ApproveTokenCellModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.loadingView.lineWidth = 2
    self.loadingView.lineColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingView.labelTextColor = UIColor(named: "buttonBackgroundColor")!
    self.loadingView.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    self.loadingView.isLoadingIndicator = true
    self.loadingView.isLabelHidden = true
    self.loadingView.delegate = self
  }
  
  func updateCellModel(_ model: ApproveTokenCellModel) {
    self.tokenNameLabel.text = model.token.name
    self.doneIconImgView.isHidden = model.state != .done
    
    switch model.state {
    case .notStart:
      self.loadingView.pause()
    case .start:
      self.loadingView.start(beginingValue: 1)
    case .done:
      self.loadingView.pause()
    }
    
    self.cellModel = model
  }
}

extension ApproveTokenCell: SRCountdownTimerDelegate {
  @objc func timerDidStart(sender: SRCountdownTimer) {
    sender.isHidden = false
  }

  @objc func timerDidPause(sender: SRCountdownTimer) {
    sender.isHidden = true
  }

  @objc func timerDidResume(sender: SRCountdownTimer) {
    sender.isHidden = false
  }
}
