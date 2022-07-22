//
//  RewardHuntingViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation
import WebKit

class RewardHuntingViewController: WebViewController {
  
  var viewModel: RewardHuntingViewModel!
  
  convenience init() {
    self.init(nibName: String(describing: WebViewController.self), bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bindViewModel()
    viewModel.onViewLoaded()
    reloadWebView()
  }
  
  override func setupNavigationBar() {
    navigationBar.rightButtonImage = Images.giftIcon
    navigationBar.setLeftButtonAction { [weak self] in
      guard let self = self else { return }
      if self.webView.canGoBack {
        self.webView.goBack()
      } else {
        self.viewModel.didTapBack()
      }
    }
    navigationBar.setRightButtonAction { [weak self] in
      self?.viewModel.didTapRewards()
    }
  }
  
  func reloadWebView() {
    loadNewPage(webType: .link(url: viewModel.url))
  }
  
  func bindViewModel() {
    viewModel.onSwitchAddress = { [weak self] in
      self?.reloadWebView()
    }
  }
  
}
