//
//  EarnModule.swift
//  EarnModule
//
//  Created by Com1 on 25/10/2022.
//

import UIKit
import BaseWallet
typealias ChainType = BaseWallet.ChainType

public class EarnModule {
  static let bundle = Bundle(for: EarnModule.self)
  
  public static func createEarnOverViewController() -> UIViewController {
    let viewModel = EarnOverViewModel()
    let viewController = EarnOverviewController.instantiateFromNib()
    viewController.viewModel = viewModel
//      let vc = SwapV2ViewController.instantiateFromNib()
//      vc.viewModel = viewModel
    return viewController
  }
}
