// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import AVFoundation

class KNOpenSettingsAllowCamera {
  static func openCameraNotAllowAlertIfNeeded(baseVC: UIViewController) -> Bool {
    let cameraType = AVMediaType.video
    let authorizedStatus = AVCaptureDevice.authorizationStatus(for: cameraType)
    switch authorizedStatus {
    case .denied, .restricted:
      let alertController = UIAlertController(
        title: "Camera is not allowed".toBeLocalised(),
        message: "Please open your Settings to allow KyberSwap to use camera".toBeLocalised(),
        preferredStyle: .actionSheet
      )
      alertController.addAction(UIAlertAction(title: "Open Settings".toBeLocalised(), style: .default, handler: { _ in
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
          return
        }
        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
      }))
      alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
      baseVC.present(alertController, animated: true, completion: nil)
      return true
    default: return false
    }
  }
}
