//
//  AlertPopupCoordinator.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import Foundation
import FittedSheets
import UIKit

class AlertPopupCoordinator: BaseCoordinator {
  var parentViewController: UIViewController
  
  init(parentViewController: UIViewController) {
    self.parentViewController = parentViewController
  }
  
  override func start() {
    let vc = AlertPopupViewController.instantiateFromNib()
    let sheet = SheetViewController(controller: vc)
    sheet.contentViewController.pullBarView.isHidden = true
    
    sheet.didDismiss = { [weak self] _ in
      self?.onCompleted?()
    }
    
    parentViewController.present(sheet, animated: true)
  }

}
