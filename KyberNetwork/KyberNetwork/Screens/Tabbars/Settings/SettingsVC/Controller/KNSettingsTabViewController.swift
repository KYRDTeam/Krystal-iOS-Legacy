// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSettingsTabViewEvent {
  case manageWallet
  case manageAlerts
  case alertMethods
  case contact
  case support
  case changePIN
  case about
  case community
  case shareWithFriends
  case telegram
  case github
  case twitter
  case facebook
  case medium
  case reddit
  case linkedIn
  case reportBugs
  case rateOurApp
  case liveChat
  case addCustomToken
  case manangeCustomToken
  case termOfUse
  case privacyPolicy
  case fingerPrint(status: Bool)
}

protocol KNSettingsTabViewControllerDelegate: class {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent)
}

class KNSettingsTabViewController: KNBaseViewController {

  weak var delegate: KNSettingsTabViewControllerDelegate?

  @IBOutlet weak var shareWithFriendsButton: UIButton!
  @IBOutlet weak var fingerprintSwitch: UISwitch!
  @IBOutlet weak var versionLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
//    self.navTitleLabel.text = NSLocalizedString("settings", value: "Settings", comment: "")
//    self.manageWalletButton.setTitle(
//      NSLocalizedString("manage.wallet", value: "Manage Wallet", comment: ""),
//      for: .normal
//    )
//    self.manageWalletButton.addTextSpacing()
//    self.manageAlerts.setTitle(NSLocalizedString("Manage Alert", comment: ""), for: .normal)
//    self.manageAlerts.addTextSpacing()
//    self.manageAlerts.isHidden = !KNAppTracker.isPriceAlertEnabled
//    self.alertMethodsButton.setTitle(NSLocalizedString("Alert Method", comment: ""), for: .normal)
//    self.alertMethodsButton.addTextSpacing()
//    self.alertMethodsButton.isHidden = !KNAppTracker.isPriceAlertEnabled
//    self.contactButton.setTitle(
//      NSLocalizedString("contact", value: "Contact", comment: ""),
//      for: .normal
//    )
//    self.contactButton.addTextSpacing()
//    self.supportButton.setTitle(
//      NSLocalizedString("support", value: "Support", comment: ""),
//      for: .normal
//    )
//    self.supportButton.addTextSpacing()
//    self.changePINButton.setTitle(
//      NSLocalizedString("change.pin", value: "Change PIN", comment: ""),
//      for: .normal
//    )
//    self.changePINButton.addTextSpacing()
//    self.aboutButton.setTitle(
//      NSLocalizedString("Get Started", value: "Get Started", comment: ""),
//      for: .normal
//    )
//    self.aboutButton.addTextSpacing()
//    self.community.setTitle(
//      NSLocalizedString("community", value: "Community", comment: ""),
//      for: .normal
//    )
//    self.community.addTextSpacing()
//    self.shareWithFriendsButton.setTitle(
//      NSLocalizedString("share.with.friends", value: "Share with friends", comment: ""),
//      for: .normal
//    )
//    self.reportBugsButton.setTitle(
//      NSLocalizedString("report.bugs", value: "Report Bugs", comment: ""),
//      for: .normal
//    )
//    self.rateOurAppButton.setTitle(
//      NSLocalizedString("rate.our.app", value: "Rate our App", comment: ""),
//      for: .normal
//    )
//    self.shareWithFriendsButton.addTextSpacing()
//    var version = Bundle.main.versionNumber ?? ""
//    version += " - \(Bundle.main.buildNumber ?? "")"
//    version += " - \(KNEnvironment.default.displayName)"
//    self.versionLabel.text = "\(NSLocalizedString("version", value: "Version", comment: "")) \(version)"
//
//    self.unreadBadgeLabel.rounded(color: .white, width: 1, radius: self.unreadBadgeLabel.frame.height / 2)
//
//    NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name(FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED), object: nil)
    self.fingerprintSwitch.isOn = UserDefaults.standard.bool(forKey: "bio-auth")
    
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      self.versionLabel.text = version + "-\(KNEnvironment.default.displayName)"
       }
  }

//  deinit {
//    let name = Notification.Name(FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED)
//    NotificationCenter.default.removeObserver(self, name: name, object: nil)
//  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
//    self.checkUnreadMessage()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
//    self.headerContainerView.removeSublayer(at: 0)
//    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }
  
  @IBAction func fingerprintValueChanged(_ sender: UISwitch) {
    self.delegate?.settingsTabViewController(self, run: .fingerPrint(status: sender.isOn))
  }
  

  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_manage_wallet", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .manageWallet)
  }

  @IBAction func manageAlertsButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_manage_alert", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .manageAlerts)
  }

  @IBAction func notificationsButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_alert_method", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .alertMethods)
  }

  @IBAction func contactButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_contact", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .contact)
  }

  @IBAction func supportButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_support", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .support)
  }

  @IBAction func changePasscodeButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_change_pin", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .changePIN)
  }

  @IBAction func aboutButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_get_started", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .about)
  }

  @IBAction func communityButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .community)
  }

  @IBAction func shareWithFriendButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_shareapp", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .shareWithFriends)
  }

  @IBAction func telegramButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "telegram group"])
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }

  @IBAction func githubButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "github"])
    self.delegate?.settingsTabViewController(self, run: .github)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "twitter"])
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }

  @IBAction func facebookButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "facebook"])
    self.delegate?.settingsTabViewController(self, run: .facebook)
  }

  @IBAction func mediumButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "medium"])
    self.delegate?.settingsTabViewController(self, run: .medium)
  }

  @IBAction func linkedInButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_community", customAttributes: ["community_icon": "linkedin"])
    self.delegate?.settingsTabViewController(self, run: .linkedIn)
  }

  @IBAction func reportBugsButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .reportBugs)
  }

  @IBAction func rateOurAppButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_rating", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .rateOurApp)
  }

  @IBAction func liveChatButtonPressed(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_livechat", customAttributes: nil)
    self.delegate?.settingsTabViewController(self, run: .liveChat)
  }
  
  @IBAction func addCustomTokenTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .addCustomToken)
  }
  
  @IBAction func manageCustomTokenTapped(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .manangeCustomToken)
  }
  
  

//  fileprivate func checkUnreadMessage() {
//    Freshchat.sharedInstance().unreadCount { (num: Int) -> Void in
//      if num > 0 {
//        self.unreadBadgeLabel.isHidden = false
//        self.unreadBadgeLabel.text = num.description
//        self.navigationController?.tabBarItem.badgeValue = num.description
//      } else {
//        self.unreadBadgeLabel.isHidden = true
//        self.navigationController?.tabBarItem.badgeValue = nil
//      }
//    }
//  }
//
//  @objc func methodOfReceivedNotification(notification: Notification) {
//    self.checkUnreadMessage()
//  }
  
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
  
  
}
