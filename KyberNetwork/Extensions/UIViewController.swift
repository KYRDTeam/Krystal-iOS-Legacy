// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import Result
import MBProgressHUD
import SafariServices
import AppState

enum ConfirmationError: LocalizedError {
    case cancel
}

extension UIViewController {
  
    func openTxHash(txHash: String, chainID: Int) {
      guard let endpoint = ChainType.getChain(id: chainID)?.customRPC().etherScanEndpoint else {
        return
      }
      guard let url = URL(string: endpoint + "tx/" + txHash) else {
        return
      }
      let vc = SFSafariViewController(url: url)
      present(vc, animated: true, completion: nil)
    }
    
    func openAddress(address: String, chainID: Int) {
      guard let endpoint = ChainType.getChain(id: chainID)?.customRPC().etherScanEndpoint else {
        return
      }
      guard let url = URL(string: endpoint + "address/" + address) else {
        return
      }
      let vc = SFSafariViewController(url: url)
      present(vc, animated: true, completion: nil)
    }
  
    func displaySuccess(title: String? = .none, message: String? = .none) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.popoverPresentationController?.sourceView = self.view
      alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", value: "OK", comment: ""), style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func displayError(error: Error) {
      displayAlert(message: error.prettyError)
    }
  
    func displayAlert(message: String) {
      let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
      alertController.popoverPresentationController?.sourceView = self.view
      alertController.addAction(UIAlertAction(title: Strings.ok, style: UIAlertAction.Style.default, handler: nil))
      present(alertController, animated: true, completion: nil)
    }

    func confirm(
        title: String? = .none,
        message: String? = .none,
        okTitle: String = NSLocalizedString("ok", value: "OK", comment: ""),
      okStyle: UIAlertAction.Style = .default,
        completion: @escaping (Result<Void, ConfirmationError>) -> Void
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.addAction(UIAlertAction(title: okTitle, style: okStyle, handler: { _ in
            completion(.success(()))
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: { _ in
            completion(.failure(ConfirmationError.cancel))
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    func displayLoading(
        text: String = NSLocalizedString("loading", value: "Loading", comment: ""),
        animated: Bool = true
    ) {
      let hud = MBProgressHUD.showAdded(to: self.view, animated: animated)
      hud.label.text = text
      hud.isUserInteractionEnabled = false
    }

    func showLoadingHUD(animated: Bool = true) {
      let hud = MBProgressHUD.showAdded(to: self.view, animated: animated)
      hud.isUserInteractionEnabled = false
    }

    func hideLoading(animated: Bool = true) {
        MBProgressHUD.hide(for: view, animated: animated)
    }
}

extension UIViewController {
  func topMostViewController() -> UIViewController? {
    if self.presentedViewController == nil {
      return self
    }
    if let navigation = self.presentedViewController as? UINavigationController {
      return navigation.visibleViewController?.topMostViewController()
    }
    if let tab = self.presentedViewController as? UITabBarController {
      if let selectedTab = tab.selectedViewController {
        return selectedTab.topMostViewController()
      }
      return tab.topMostViewController()
    }
    return self.presentedViewController!.topMostViewController()
  }
}

extension UIApplication {
  func topMostViewController() -> UIViewController? {
    return self.keyWindow?.rootViewController?.topMostViewController()
  }
}

extension UIViewController {
  func showSwitchChainAlert(_ chain: ChainType,_ message: String? = nil, completion: @escaping () -> Void = {}) {
    let msg = message ?? "Please switch to \(chain.chainName()) to continue".toBeLocalised()
    
    let alertController = KNPrettyAlertController(
      title: "",
      message: msg,
      secondButtonTitle: Strings.ok,
      firstButtonTitle: Strings.cancel,
      secondButtonAction: {
        AppState.shared.updateChain(chain: chain)
//        KNGeneralProvider.shared.currentChain = chain
        KNNotificationUtil.postNotification(for: kChangeChainNotificationKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          completion()
        }
      },
      firstButtonAction: {
        
      }
    )
    alertController.popupHeight = 220
    self.present(alertController, animated: true, completion: nil)
  }
}
