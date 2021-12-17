//
//  KrytalViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import UIKit
import MBProgressHUD

class KrytalViewModel {
  var referralOverViewData: ReferralOverviewData?
  var wallet: Wallet?
  var tiers: ReferralTiers?
  var displayTotalReward: String {
    guard let unwrapped = self.referralOverViewData else { return "---" }
    return "\(unwrapped.rewardAmount) \(unwrapped.rewardToken.symbol)"
  }

  var displayReferralCodes: [KrytalCellViewModel] {
    guard let unwrapped = self.referralOverViewData else { return [] }
    let allHashs = unwrapped.codeStats.keys
    let sorted = allHashs.sorted { (left, right) -> Bool in
      return unwrapped.codeStats[left]?.ratio ?? 0 > unwrapped.codeStats[right]?.ratio ?? 0
    }
    return sorted.map { (refCode) -> KrytalCellViewModel in
      return KrytalCellViewModel(codeObject: unwrapped.codeStats[refCode] ?? Code(totalRefer: 0, vol: 0, ratio: 0), referralCode: refCode)
    }
  }
  
  var displayWalletString: String {
    guard let unwrapped = self.wallet else { return "" }
    return unwrapped.getWalletObject()?.name ?? "---"
  }
  
  var displayIntroAttributedString: NSAttributedString {
    let fullString = NSMutableAttributedString(string: "Copy below given Ref Code to share with your friends & start earning ".toBeLocalised())
    let image1Attachment = NSTextAttachment()
    image1Attachment.image = UIImage(named: "info_waring_blue_icon")
    let image1String = NSAttributedString(attachment: image1Attachment)
    fullString.append(image1String)
    return fullString
  }

  var bonusVol: String {
    guard let unwrapped = self.referralOverViewData else { return "---" }
    return "\(unwrapped.bonusVol)"
  }

  var displayTotalConfirmedVol: String {
    guard let unwrapped = self.referralOverViewData else { return "---" }
    return "\(unwrapped.totalVol)"
  }

  var nextRewardInfoString: String {
    guard let unwrapped = self.referralOverViewData else { return "---" }
    return "\(StringFormatter.usdString(value: unwrapped.volForNextReward)) more to unlock the next reward"
  }
  
  var shouldHideBonusVolume: Bool {
    guard let unwrapped = self.referralOverViewData else { return true }
    return unwrapped.bonusVol == 0
  }
}

enum KrytalViewEvent {
  case openShareCode(refCode: String, codeObject: Code)
  case openHistory
  case openWalletList
  case claim
  case showRefferalTiers(tiers: [Tier])
}

protocol KrytalViewControllerDelegate: class {
  func krytalViewController(_ controller: KrytalViewController, run event: KrytalViewEvent)
}

class KrytalViewController: KNBaseViewController {
  @IBOutlet weak var totalRewardLabel: UILabel!
  @IBOutlet weak var referralCodeTableView: UITableView!
  @IBOutlet weak var introLabel: UILabel!
  @IBOutlet weak var bonusVolLabel: UILabel!
  @IBOutlet weak var totalConfirmedVolLabel: UILabel!
  @IBOutlet weak var confirmVolTitleLabel: UILabel!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var nextRewardLabel: UILabel!
  @IBOutlet weak var bonusVolumeHeight: NSLayoutConstraint!
  @IBOutlet weak var bonusVolTitle: UILabel!
  @IBOutlet weak var infoViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var bonusVolHintImage: UIImageView!
  @IBOutlet weak var bonusVolHintButton: UIButton!
  let viewModel = KrytalViewModel()
  weak var delegate: KrytalViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: KrytalTableViewCell.className, bundle: nil)
    self.referralCodeTableView.register(nib, forCellReuseIdentifier: KrytalTableViewCell.cellID)
    self.referralCodeTableView.rowHeight = KrytalTableViewCell.cellHeight
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.walletListButton.setTitle(self.viewModel.displayWalletString, for: .normal)
    self.totalRewardLabel.text = self.viewModel.displayTotalReward
    self.introLabel.attributedText = self.viewModel.displayIntroAttributedString
    self.bonusVolLabel.text = self.viewModel.bonusVol
    self.totalConfirmedVolLabel.text = self.viewModel.displayTotalConfirmedVol
    self.nextRewardLabel.text = self.viewModel.nextRewardInfoString
    self.bonusVolumeHeight.constant = self.viewModel.shouldHideBonusVolume ? 0 : 53
    self.bonusVolTitle.isHidden = self.viewModel.shouldHideBonusVolume
    self.bonusVolLabel.isHidden = self.viewModel.shouldHideBonusVolume
    self.bonusVolHintImage.isHidden = self.viewModel.shouldHideBonusVolume
    self.bonusVolHintButton.isHidden = self.viewModel.shouldHideBonusVolume
    self.infoViewHeightContraint.constant = self.viewModel.shouldHideBonusVolume ? 335 : 388
    self.referralCodeTableView.reloadData()
  }

  func coordinatorDidUpdateOverviewReferral(_ referralOverViewData: ReferralOverviewData?) {
    self.viewModel.referralOverViewData = referralOverViewData
    guard self.isViewLoaded else { return }
    self.updateUI()
  }

  func coordinatorDidUpdateTiers(_ tiers: ReferralTiers?) {
    self.viewModel.tiers = tiers
  }

  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalViewController(self, run: .openHistory)
  }

  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalViewController(self, run: .openWalletList)
  }

  @IBAction func claimButtonTapped(_ sender: Any) {
    self.delegate?.krytalViewController(self, run: .claim)
  }

  @IBAction func showReferralTierButtonTapped(_ sender: Any) {
    if let tiersData = self.viewModel.tiers {
      self.delegate?.krytalViewController(self, run: .showRefferalTiers(tiers: tiersData.tiers))
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func helpIconTapped(_ sender: UITapGestureRecognizer) {
    self.navigationController?.showBottomBannerView(message: "Ask your friends to download Krystal App using your Referral Codes. If they enter your Referral Codes when importing/creating their wallets in Krystal, both you and your friends can start earning Referral Rewards.", icon: UIImage(named: "info_waring_blue_icon")!, time: 10, tapHandler: {
      self.openSafari(with: "https://support.krystal.app/support/solutions/articles/47001181546-referral-program")
    })
  }
  @IBAction func bonusVolumeButtonTapped(_ sender: Any) {
    // display in BPS style
    let bonusRatio = (self.viewModel.referralOverViewData?.bonusRatio ?? 0) * 100 / 10000
    self.navigationController?.showBottomBannerView(message: "This is shared by your referrer. \(bonusRatio)% of your trading volume will be counted in the total referral volume.", icon: UIImage(named: "info_waring_blue_icon")!, time: 10, tapHandler: {
      self.openSafari(with: "https://support.krystal.app/support/solutions/articles/47001181546-referral-program")
    })
  }
}

extension KrytalViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.displayReferralCodes.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KrytalTableViewCell.cellID,
      for: indexPath
    ) as! KrytalTableViewCell

    cell.updateCell(viewModel: self.viewModel.displayReferralCodes[indexPath.row])
    cell.delegate = self
    return cell
  }
}

extension KrytalViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let viewModel = self.viewModel.displayReferralCodes[indexPath.row]
    self.delegate?.krytalViewController(self, run: .openShareCode(refCode: viewModel.referralCode, codeObject: viewModel.codeObject))
  }
}

extension KrytalViewController: KrytalTableViewCellDelegate {
  func krytalTableViewCellDidSelectCopy(_ cell: KrytalTableViewCell, code: String) {
    UIPasteboard.general.string = code
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func krytalTableViewCellDidSelectShare(_ cell: KrytalTableViewCell, code: String, codeObject: Code) {

    let text = "Here's my referral code \(code) to earn bonus rewards on the Krystal app! Use the code when connecting your wallet in the app. Details: https://krystal.app"
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.view
    self.navigationController?.present(activitiy, animated: true, completion: nil)
  }
}
