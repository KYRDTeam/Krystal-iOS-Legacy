//
//  ChallengeViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class ChallengeViewController: UIViewController {
  
  @IBOutlet weak var stepProgressView: StepProgressView!
  
  var viewModel: ChallengeViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupProgressView()
  }
  
  func setupProgressView() {
    stepProgressView.delegate = self
    stepProgressView.dataSource = self
    
    stepProgressView.direction = .vertical
    
    stepProgressView.registerCellNib(ChallengeInfoCell.self)
    stepProgressView.registerCellNib(ChallengeStartCell.self)
    stepProgressView.registerCellNib(ChallengeProgressCell.self)
    stepProgressView.registerCellNib(ChallengeFinishCell.self)
    stepProgressView.registerCellNib(ChallengeSingleRewardCell.self)
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    viewModel.onTapBack?()
  }
  
}

extension ChallengeViewController: StepProgressViewDelegate, StepProgressViewDataSource {
  
  func stepProgressView(_ stepProgressView: StepProgressView, sizeForItemAt index: Int) -> CGSize {
    let item = viewModel.items[index]
    
    switch item {
    case .info:
      return .init(width: stepProgressView.frame.width, height: 160)
    case .begin:
      return .init(width: stepProgressView.frame.width, height: 96)
    case .progress:
      return .init(width: stepProgressView.frame.width, height: 96)
    case .rewardTitle:
      return .init(width: stepProgressView.frame.width, height: 48)
    case .reward:
      return .init(width: stepProgressView.frame.width, height: 64)
    }
    
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, frameForConnectionLineAfter index: Int) -> CGRect {
    if index + 1 <= viewModel.items.count - 1 {
      switch viewModel.items[index] {
      case .info:
        return .zero
      default:
        switch viewModel.items[index + 1] {
        case .reward:
          return .zero
        default:
          let frame1 = stepProgressView.frame(ofItemAt: index)
          let frame2 = stepProgressView.frame(ofItemAt: index + 1)
          
          let minY = frame1.origin.y + 40
          let height = (frame2.origin.y + 16) - minY
          return .init(x: 39, y: minY, width: 2, height: height)
        }
      }
    }
    
    return .zero
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, colorForConnectionLineAfter index: Int) -> UIColor {
    return .elevation5
  }
  
  func numberOfItems(_ stepProgressView: StepProgressView) -> Int {
    return viewModel.items.count
  }
  
  func stepProgressView(_ stepProgressView: StepProgressView, cellForItemAt index: Int) -> UICollectionViewCell {
    let item = viewModel.items[index]
    
    switch item {
    case .info:
      let cell = stepProgressView.dequeueReusableCell(ChallengeInfoCell.self, for: index)!
      return cell
    case .begin:
      let cell = stepProgressView.dequeueReusableCell(ChallengeStartCell.self, for: index)!
      return cell
    case .progress(let step):
      let cell = stepProgressView.dequeueReusableCell(ChallengeProgressCell.self, for: index)!
      return cell
    case .rewardTitle:
      let cell = stepProgressView.dequeueReusableCell(ChallengeFinishCell.self, for: index)!
      return cell
    case .reward(let reward):
      let cell = stepProgressView.dequeueReusableCell(ChallengeSingleRewardCell.self, for: index)!
      return cell
    }
  }
  
  func insets(_ stepProgressView: StepProgressView) -> UIEdgeInsets {
    return .init(top: 0, left: 0, bottom: 24, right: 0)
  }
  
}
