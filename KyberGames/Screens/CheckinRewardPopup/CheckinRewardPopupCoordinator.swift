//
//  CheckinRewardPopupCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import Foundation
import FittedSheets
import UIKit

class CheckinRewardPopupCoordinator: Coordinator {
  var parentCoordinator: Coordinator?
  var children: [Coordinator] = []
  var parentViewController: UIViewController
  
  init(parentViewController: UIViewController) {
    self.parentViewController = parentViewController
  }
  
  func start() {
    let vc = CheckinRewardPopupViewController.instantiateFromNib()
    let sheet = SheetViewController(controller: vc)
    sheet.contentViewController.pullBarView.isHidden = true
    parentViewController.present(sheet, animated: true)
  }

}
