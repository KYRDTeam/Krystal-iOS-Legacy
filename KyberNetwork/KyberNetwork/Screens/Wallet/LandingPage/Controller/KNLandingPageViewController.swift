// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNLandingPageViewEvent {
  case openCreateWallet
  case openImportWallet
  case openTermAndCondition
  case openMigrationAlert
  case getStarted
}

protocol KNLandingPageViewControllerDelegate: class {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent)
}

class KNLandingPageViewController: KNBaseViewController {
  let collectionViewLeadTrailPadding = CGFloat(20)
  weak var delegate: KNLandingPageViewControllerDelegate?
  @IBOutlet weak var welcomeScreenCollectionView: KNWelcomeScreenCollectionView!
  @IBOutlet weak var createWalletButton: UIButton!
  @IBOutlet weak var importWalletButton: UIButton!
  @IBOutlet weak var termAndConditionButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()

//    self.createWalletButton.setTitle(
//      NSLocalizedString("create.wallet", value: "Create Wallet", comment: ""),
//      for: .normal
//    )
    self.importWalletButton.setTitle(
      NSLocalizedString("import.wallet", value: "Import Wallet", comment: ""),
      for: .normal
    )
    self.importWalletButton.addTextSpacing()
    self.createWalletButton.rounded(radius: 16)
    self.importWalletButton.rounded(radius: 16)
    self.welcomeScreenCollectionView.paggerViewLeadingConstraint.constant = (UIScreen.main.bounds.width - collectionViewLeadTrailPadding * 2 - KNWelcomeScreenCollectionView.paggerWidth) / 2
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .getStarted)
//    self.delegate?.landinagePageViewController(self, run: .openCreateWallet)
  }

  @IBAction func importWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openImportWallet)
  }

  @IBAction func termAndConditionButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openTermAndCondition)
  }
}
