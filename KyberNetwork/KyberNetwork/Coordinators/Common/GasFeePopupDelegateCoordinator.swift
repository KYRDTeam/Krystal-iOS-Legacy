//
//  GasFeePopupDelegateCoordinator.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation
import UIKit

protocol GasFeePopupDelegateCoordinator {
  var navigationController: UINavigationController { get }
  var session: KNSession { get }
  
  func handleGasFeePopupEvent(event: GasFeeSelectorPopupViewEvent)
  func openTransactionStatusPopUp(transaction: InternalHistoryTransaction)
  func handleTransactionStatusPopUpEvent(event: KNTransactionStatusPopUpEvent)
}

extension Coordinator where Self: GasFeePopupDelegateCoordinator {
  
  func handleGasFeePopupEvent(event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .helpPressed(let tag):
      var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
      switch tag {
      case 1:
        message = KNGeneralProvider.shared.isUseEIP1559 ? "gas.limit.help".toBeLocalised() : "gas.limit.legacy.help".toBeLocalised()
      case 2:
        message = "max.priority.fee.help".toBeLocalised()
      case 3:
        message = KNGeneralProvider.shared.isUseEIP1559 ? "max.fee.help".toBeLocalised() : "gas.price.legacy.help".toBeLocalised()
      case 4:
        message = "nonce.help".toBeLocalised()
      default:
        break
      }
      self.navigationController.showBottomBannerView(
        message: message,
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .speedupTransactionSuccessfully(let speedupTransaction):
      self.openTransactionStatusPopUp(transaction: speedupTransaction)
    case .cancelTransactionSuccessfully(let cancelTransaction):
      self.openTransactionStatusPopUp(transaction: cancelTransaction)
    case .speedupTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .cancelTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    default:
      break
    }
  }
  
}
