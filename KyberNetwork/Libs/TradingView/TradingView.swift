//
//  TradingView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 27/06/2022.
//

import Foundation
import UIKit
import WebKit

class TradingView: UIView {
  
  let webView: WKWebView = {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.isOpaque = false
    webView.backgroundColor = .clear
    return webView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    commonInit()
  }
  
  func commonInit() {
    addWebView()
    
    webView.configuration.userContentController.add(self, name: TradingView.moduleName)
  }
  
  func addWebView() {
    addSubview(webView)
    
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: self.topAnchor),
      webView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
    ])
  }
  
  func load(request: ChartLoadRequest) {
    guard let baseURL = Bundle(for: TradingView.self).url(forResource: "mobile-charting-library/trading_view", withExtension: "html") else { return }
    let url = request.buildChartURL(withBaseURL: baseURL)
    webView.load(URLRequest(url: url))
  }
  
}

extension TradingView: WKScriptMessageHandler {
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == TradingView.moduleName {
      guard let body = message.body as? NSDictionary else { return }
      guard let actionString = body["action"] as? String else { return }
      guard let action = Action(rawValue: actionString) else { return }
      guard let data = body["data"] as? NSDictionary else { return }
      self.handle(action: action, data: data)
    }
  }
  
  func handle(action: Action, data: NSDictionary) {
    switch action {
    case .toggleFullscreen:
      guard let isFullscreen = data["isFullscreen"] as? Bool else { return }
      guard let window = UIApplication.shared.keyWindow else { return }
      if isFullscreen {
        webView.removeFromSuperview()
        window.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = true
        UIView.animate(withDuration: 0.5) {
          let width = UIScreen.main.bounds.height
          let height = UIScreen.main.bounds.width
          self.webView.frame = CGRect(
            x: -self.bounds.width / 2,
            y: self.bounds.height / 2 + UIScreen.statusBarHeight,
            width: width,
            height: height
          )
          self.webView.rotate(angle: 90)
        }
      } else {
        webView.removeFromSuperview()
        addWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        UIView.animate(withDuration: 0.5) {
          self.webView.rotate(angle: -90.0)
        }
      }
    }
  }
  
}

extension TradingView {
  
  static let moduleName = "tradingView"
  
  enum Action: String {
    case toggleFullscreen = "toggleFullscreen"
  }
  
}

extension UIView {
  func rotate(angle: CGFloat) {
    let radians = angle / 180.0 * CGFloat.pi
    let rotation = self.transform.rotated(by: radians)
    self.transform = rotation
  }
}
