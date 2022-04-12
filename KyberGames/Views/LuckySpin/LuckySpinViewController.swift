//
//  LuckySpinViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit
import SwiftFortuneWheel

class LuckySpinViewController: BaseViewController {
  @IBOutlet weak var wheelView: SwiftFortuneWheel!
  var viewModel: LuckySpinViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureWheel()
  }
  
  func configureWheel() {
    let slices = GameReward.mock.map { reward -> Slice in
      let slice = Slice(contents: [.text(text: reward.title, preferences: TextPreferences(textColorType: .customPatternColors(colors: nil, defaultColor: .white), font: .coinyFont(ofSize: 14), verticalOffset: 24))])
      return slice
    }
    let colors = GameReward.mock.map(\.uiColor)
    
    let sliceColorType = SFWConfiguration.ColorType.customPatternColors(colors: colors, defaultColor: .black)
    let slicePreferences = SFWConfiguration.SlicePreferences(backgroundColorType: sliceColorType, strokeWidth: 0, strokeColor: .black)
    let circlePreferences = SFWConfiguration.CirclePreferences()
    let wheelPreferences = SFWConfiguration.WheelPreferences(circlePreferences: circlePreferences, slicePreferences: slicePreferences, startPosition: .top)

    let configuration = SFWConfiguration(wheelPreferences: wheelPreferences)
    
    wheelView.configuration = configuration
    wheelView.slices = slices
  }
  
  @IBAction func spinWasTapped(_ sender: Any) {
    wheelView.startRotationAnimation(finishIndex: 2) { finish in
      print(finish)
    }
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    viewModel.onTapBack?()
  }
  
  @IBAction func addTurnsWasTapped(_ sender: Any) {
    viewModel.onTapAddTurns?()
  }
}
