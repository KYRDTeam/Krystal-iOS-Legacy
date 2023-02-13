//
//  PromoCodeDetailViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 16/03/2022.
//

import UIKit
import Kingfisher
import FittedSheets
import Moya

struct PromoCodeDetailViewModel {
  let item: PromoCode
  
  var displayTitle: String {
    return self.item.campaign.title
  }
  
  var displayDescription: String {
    return self.item.campaign.campaignDescription
  }
}

protocol PromoCodeDetailViewControllerDelegate: class {
  func promoCodeDetailViewController(_ controller: PromoCodeDetailViewController, claim code: String)
}

class PromoCodeDetailViewController: KNBaseViewController {
  
  @IBOutlet weak var bannerImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var useNowButton: UIButton!
  @IBOutlet weak var descriptionTextView: UITextView!
  
  let viewModel: PromoCodeDetailViewModel
  weak var delegate: PromoCodeDetailViewControllerDelegate?
  var redeemPopup: RedeemPopupViewController?
  
  var addressString: String {
    return AppDelegate.session.address.addressString
  }
  
  var timer: Timer?
  
  init(viewModel: PromoCodeDetailViewModel) {
    self.viewModel = viewModel
    super.init(nibName: PromoCodeDetailViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func setupViews() {
    self.titleLabel.text = self.viewModel.displayTitle
    self.descriptionTextView.text = self.viewModel.displayDescription
    self.useNowButton.isHidden = self.viewModel.item.getStatus() != .pending
    self.useNowButton.rounded(radius: 16)
    if let url = URL(string: self.viewModel.item.campaign.bannerURL) {
      self.bannerImageView.kf.setImage(with: url, placeholder: UIImage(named: "promo_code_default_banner"), options: [.cacheMemoryOnly])
    }
    self.useNowButton.setBackgroundColor(.Kyber.primaryGreenColor, forState: .normal)
    self.useNowButton.setBackgroundColor(.Kyber.evenBg, forState: .disabled)
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func useNowButtonTapped(_ sender: UIButton) {
    openRedeemPopup()
    requestClaim()
  }
  
}

extension PromoCodeDetailViewController: RedeemPopupViewControllerDelegate {
  
  func openRedeemPopup() {
    let popup = RedeemPopupViewController.instantiateFromNib()
    popup.promoCode = viewModel.item
    popup.delegate = self
    
    var options = SheetOptions()
    options.pullBarHeight = 0
    let sheet = SheetViewController(controller: popup, sizes: [.intrinsic], options: options)
    sheet.allowPullingPastMinHeight = false
    
    redeemPopup = popup
    present(sheet, animated: true)
  }
  
  func onOpenTxHash(popup: RedeemPopupViewController, txHash: String, chainID: Int) {
    popup.dismiss(animated: true) { [weak self] in
      self?.openTxHash(txHash: txHash, chainID: chainID)
    }
  }
  
  func onRedeemPopupClose() {
    redeemPopup = nil
  }
  
  @objc func checkstatus() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    guard let codePrefix = viewModel.item.code.split(separator: "-").first else { return }
    provider.requestWithFilter(.getPromotions(code: String(codePrefix), address: addressString)) { [weak self] result in
      switch result {
      case .success(let responseData):
        let promotions = try? JSONDecoder().decode(PromotionResponse.self, from: responseData.data)
        if let code = promotions?.codes.first(where: { $0.code == self?.viewModel.item.code }) {
          self?.redeemPopup?.updateTxHash(hash: code.claimTx)
          switch code.txnStatus {
          case "success":
            self?.requestClaimSuccess()
          default:
            return
          }
        }
      case .failure:
        return
      }
    }
  }
  
  func scheduleCheckStatus() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkstatus), userInfo: nil, repeats: true)
  }
  
  func requestClaim() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    provider.requestWithFilter(successCodes: 200...400, .claimPromotion(code: viewModel.item.code, address: addressString)) { [weak self] result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let _ = try decoder.decode(ClaimResponse.self, from: resp.data)
          self?.scheduleCheckStatus()
        } catch {
          do {
            let data = try decoder.decode(ClaimErrorResponse.self, from: resp.data)
            self?.requestClaimFailed(message: data.error.capitalized)
          } catch {
            self?.requestClaimFailed(message: "Can not decode data")
          }
        }
      case .failure(let error):
        self?.requestClaimFailed(message: error.localizedDescription)
      }
    }
  }
  
  func requestClaimFailed(message: String) {
    if let redeemPopup = self.redeemPopup {
      redeemPopup.status = .failure(message: message)
    } else {
      showTopBannerView(with: Strings.redeemFailed, message: message)
    }
    useNowButton.isEnabled = true
    useNowButton.setTitle(Strings.redeemNow, for: .normal)
  }
  
  func requestClaimSuccess() {
    if let redeemPopup = self.redeemPopup {
      redeemPopup.status = .success
    } else {
      showTopBannerView(message: Strings.redeemSuccessMessage)
    }
    useNowButton.isHidden = true
  }
  
}
