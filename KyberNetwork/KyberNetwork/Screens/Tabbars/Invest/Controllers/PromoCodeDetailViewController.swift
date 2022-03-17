//
//  PromoCodeDetailViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 16/03/2022.
//

import UIKit
import Kingfisher

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
  
  init(viewModel: PromoCodeDetailViewModel) {
    self.viewModel = viewModel
    super.init(nibName: PromoCodeDetailViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.titleLabel.text = self.viewModel.displayTitle
    self.descriptionTextView.text = self.viewModel.displayDescription
    self.useNowButton.isHidden = self.viewModel.item.getStatus() != .pending
    self.useNowButton.rounded(radius: 16)
    if let url = URL(string: self.viewModel.item.campaign.bannerURL) {
      self.bannerImageView.kf.setImage(with: url, placeholder: UIImage(named: "promo_code_default_banner"), options: [.cacheMemoryOnly])
    }
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func useNowButtonTapped(_ sender: UIButton) {
    self.delegate?.promoCodeDetailViewController(self, claim: self.viewModel.item.code)
  }
}
