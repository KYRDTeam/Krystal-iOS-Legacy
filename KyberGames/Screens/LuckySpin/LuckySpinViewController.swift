//
//  LuckySpinViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit
import SwiftFortuneWheel

struct LuckyReward {
  var title: String
  var color: UIColor
  
  static let mock: [LuckyReward] = [
    .init(title: "200 points", color: UIColor(hexString: "#5A9CFF")),
    .init(title: "5 KNC", color: UIColor(hexString: "#0A80D8")),
    .init(title: "120 points", color: UIColor(hexString: "#813B9D")),
    .init(title: "10 BUSD", color: UIColor(hexString: "#FF5353")),
    .init(title: "Lucky Wish", color: UIColor(hexString: "#8EAF30")),
    .init(title: "2 KNC", color: UIColor(hexString: "#C852B5")),
    .init(title: "30 points", color: UIColor(hexString: "#F5BA33"))
  ]
}

class LuckySpinViewController: BaseViewController {
  @IBOutlet weak var wheelView: SwiftFortuneWheel!
  var viewModel: LuckySpinViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureWheel()
  }
  
  func configureWheel() {
    let slices = LuckyReward.mock.map { reward -> Slice in
      let slice = Slice(contents: [.text(text: reward.title, preferences: TextPreferences(textColorType: .customPatternColors(colors: nil, defaultColor: .white), font: .coinyFont(ofSize: 14), verticalOffset: 24))])
      return slice
    }
    
    let sliceColorType = SFWConfiguration.ColorType.customPatternColors(colors: LuckyReward.mock.map(\.color), defaultColor: .black)
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
