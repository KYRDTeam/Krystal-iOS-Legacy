// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import MBProgressHUD
import SafariServices

enum ConfirmationError: LocalizedError {
    case cancel
}

public extension UIViewController {

  
    func displaySuccess(title: String? = .none, message: String? = .none) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.popoverPresentationController?.sourceView = self.view
      alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", value: "OK", comment: ""), style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

//    func displayError(error: Error) {
//      displayAlert(message: error.prettyError)
//    }
//
//    func displayAlert(message: String) {
//      let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
//      alertController.popoverPresentationController?.sourceView = self.view
//      alertController.addAction(UIAlertAction(title: Strings.ok, style: UIAlertAction.Style.default, handler: nil))
//      present(alertController, animated: true, completion: nil)
//    }

//    func confirm(
//        title: String? = .none,
//        message: String? = .none,
//        okTitle: String = NSLocalizedString("ok", value: "OK", comment: ""),
//      okStyle: UIAlertAction.Style = .default,
//        completion: @escaping (Result<Void, ConfirmationError>) -> Void
//    ) {
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.popoverPresentationController?.sourceView = self.view
//        alertController.addAction(UIAlertAction(title: okTitle, style: okStyle, handler: { _ in
//            completion(.success(()))
//        }))
//        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: { _ in
//            completion(.failure(ConfirmationError.cancel))
//        }))
//        self.present(alertController, animated: true, completion: nil)
//    }

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
