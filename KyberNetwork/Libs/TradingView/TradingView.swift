//
//  TradingView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 27/06/2022.
//

import Foundation
import UIKit
import WebKit

protocol TradingViewDelegate: AnyObject {
  func tradingView(_ tradingView: TradingView, handleAction action: TradingView.Action)
}

class TradingView: UIView {
  
  weak var delegate: TradingViewDelegate?
  
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
    addSubview(webView)
    
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: self.topAnchor),
      webView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
    ])
    
    webView.configuration.userContentController.add(self, name: TradingView.moduleName)
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
      self.delegate?.tradingView(self, handleAction: action)
    }
  }
  
}
