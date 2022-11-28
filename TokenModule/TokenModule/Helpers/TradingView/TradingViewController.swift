//
//  TradingViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 05/07/2022.
//

import Foundation
import UIKit

class TradingViewController: UIViewController {
  
  let request: ChartLoadRequest
  
  init(request: ChartLoadRequest) {
    self.request = request
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  let tradingView: TradingView = {
    let tradingView = TradingView(frame: .zero)
    tradingView.translatesAutoresizingMaskIntoConstraints = true
    return tradingView
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(hex: "181A23")
    setupTradingView()
    tradingView.load(request: self.request)
  }
  
  func setupTradingView() {
    let h = view.frame.height
    let w = view.frame.width
    let s = UIScreen.statusBarHeight
    let b = UIScreen.bottomPadding
    tradingView.frame = CGRect(
      x: (w + s + b - h) / 2,
      y: (h + s - b - w) / 2,
      width: h - s - b,
      height: w
    )
    view.addSubview(tradingView)
    tradingView.rotate(angle: 90)
    tradingView.delegate = self
  }
  
}

extension TradingViewController: TradingViewDelegate {
  
  func tradingView(_ tradingView: TradingView, handleAction action: TradingView.Action) {
    switch action {
    case .toggleFullscreen:
      self.dismiss(animated: true)
    }
  }
  
}
