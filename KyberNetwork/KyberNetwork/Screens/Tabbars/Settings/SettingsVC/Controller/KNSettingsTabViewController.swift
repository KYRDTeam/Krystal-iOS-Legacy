// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import LocalAuthentication
import KrystalWallets
import BaseModule
import Dependencies

enum KNSettingsTabViewEvent {
  case manageWallet
  case contact
  case support
  case changePIN
  case community
  case shareWithFriends
  case telegram
  case twitter
  case medium
  case reddit
  case rateOurApp
  case termOfUse
  case privacyPolicy
  case fingerPrint(status: Bool)
  case refPolicy
}

protocol KNSettingsTabViewControllerDelegate: class {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent)
}

class KNSettingsTabViewController: InAppBrowsingViewController {

  weak var delegate: KNSettingsTabViewControllerDelegate?
  @IBOutlet weak var addWalletView: UIView!
  @IBOutlet weak var securitySectionHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var securityViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var shareWithFriendsButton: UIButton!
  @IBOutlet weak var fingerprintSwitch: UISwitch!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var fingerprintButton: UIButton!
  @IBOutlet weak var securityView: UIView!
  @IBOutlet weak var updateButton: UIButton!
    
  var error: NSError?
  let context = LAContext()

  override func viewDidLoad() {
    super.viewDidLoad()

    tabBarItem.accessibilityIdentifier = "menuSetting"
    
    self.fingerprintSwitch.isOn = UserDefaults.standard.object(forKey: "bio-auth") as? Bool ?? true
    
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      self.versionLabel.text = version + "-\(KNEnvironment.default.displayName)"
    }

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      self.fingerprintSwitch.isHidden = true
      self.fingerprintButton.isHidden = true
      self.securitySectionHeightContraint.constant = 90
      return
    }
    
    self.fingerprintButton.setImage(
      UIImage(named: context.biometryType == LABiometryType.faceID ? "faceid_blue_icon" : "touchid_blue_icon"),
      for: .normal
    )
    
    self.fingerprintButton.setTitle(context.biometryType == LABiometryType.faceID ? "FaceID" : "Fingerprint", for: .normal)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    updateButton.isHidden = VersionManager.shared.getCurrentVersionStatus() != .canUpdate
      
    MixPanelManager.track("settings_open", properties: ["screenid": "settings"])
    updateUIForBrowsingModeIfNeed()
  }
  
  func updateUIForBrowsingModeIfNeed() {
    addWalletView.isHidden = !KNGeneralProvider.shared.isBrowsingMode
    securityView.isHidden = KNGeneralProvider.shared.isBrowsingMode
    securitySectionHeightContraint.constant = KNGeneralProvider.shared.isBrowsingMode ? 0 : context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ? 120 : 90
    securityViewTopConstraint.constant = KNGeneralProvider.shared.isBrowsingMode ? 0 : 18
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }

  func coordinatorAppSwitchAddress() {
    updateUIForBrowsingModeIfNeed()
  }
    
  @IBAction func updateTapped(_ sender: Any) {
    AppDependencies.router.openAppstore()
  }
  
  @IBAction func fingerprintValueChanged(_ sender: UISwitch) {
    if sender.isOn {
      context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("use.touchid/faceid.to.secure.your.account", value: "Use touchID/faceID to secure your account", comment: "")) { [weak self] (success, error) in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if success {
            self.delegate?.settingsTabViewController(self, run: .fingerPrint(status: sender.isOn))
          } else {
            sender.isOn = !sender.isOn
          }
        }
      }
    } else {
      self.delegate?.settingsTabViewController(self, run: .fingerPrint(status: sender.isOn))
      MixPanelManager.track("settings_fingerprint", properties: ["screenid": "settings"])
    }
  }
  
  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .manageWallet)
    MixPanelManager.track("settings_manage_wallets", properties: ["screenid": "settings"])
  }

  @IBAction func contactButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .contact)
    MixPanelManager.track("settings_manage_contacts", properties: ["screenid": "settings"])
  }

  @IBAction func supportButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .support)
    MixPanelManager.track("settings_email", properties: ["screenid": "settings"])
  }

  @IBAction func changePasscodeButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .changePIN)
    MixPanelManager.track("settings_change_pin", properties: ["screenid": "settings"])
  }

  @IBAction func communityButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .community)
  }

  @IBAction func shareWithFriendButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .shareWithFriends)
    MixPanelManager.track("settings_share", properties: ["screenid": "settings"])
  }

  @IBAction func telegramButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }

  @IBAction func mediumButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .medium)
  }

  @IBAction func rateOurAppButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .rateOurApp)
  }
  
  @IBAction func referralPolicyButtonTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .refPolicy)
  }

  @IBAction func termOfUseButtonTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .termOfUse)
  }
  
  @IBAction func privacyPolicyTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .privacyPolicy)
  }
  
  @IBAction func telegramButtonTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }
  
  @IBAction func twitterButtonTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }
  
  @IBAction func mediumButtonTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .medium)
  }
  
  override func handleAddWalletTapped() {
    super.handleAddWalletTapped()
    MixPanelManager.track("settings_connect_wallet", properties: ["screenid": "settings"])
  }
  
  func errorMessageForLAErrorCode(_ errorCode: Int ) -> String? {
    if #available(iOS 11.0, *) {
      switch errorCode {
      case LAError.biometryLockout.rawValue:
        return NSLocalizedString(
          "too.many.failed.attempts",
          value: "Too many failed attempts. Please try to use PIN",
          comment: ""
        )
      case LAError.biometryNotAvailable.rawValue:
        return NSLocalizedString(
          "touchid.faceid.is.not.available",
          value: "TouchID/FaceID is not available on the device",
          comment: ""
        )
      default:
        break
      }
    }
    switch errorCode {
    case LAError.authenticationFailed.rawValue:
      return NSLocalizedString(
        "invalid.authentication",
        value: "Invalid authentication.",
        comment: ""
      )
    case LAError.passcodeNotSet.rawValue:
      return NSLocalizedString(
        "pin.is.not.set.on.the.device",
        value: "PIN is not set on the device",
        comment: ""
      )
    case LAError.biometryLockout.rawValue:
      return NSLocalizedString(
        "too.many.failed.attempts",
        value: "Too many failed attempts. Please try to use PIN",
        comment: ""
      )
    case LAError.biometryNotAvailable.rawValue:
      return NSLocalizedString(
        "touchid.faceid.is.not.available",
        value: "TouchID/FaceID is not available on the device",
        comment: ""
      )
    case LAError.appCancel.rawValue, LAError.userCancel.rawValue, LAError.userFallback.rawValue:
      return nil
    default:
      return NSLocalizedString(
        "something.went.wrong.try.to.use.pin",
        value: "Something went wrong. Try to use PIN",
        comment: ""
      )
    }
  }
}
