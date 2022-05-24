//
//  MiniAppDetailViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit

class MiniAppDetailViewController: KNBaseViewController {
  @IBOutlet weak var fiveStarButton: UIButton!
  @IBOutlet weak var fourStarButton: UIButton!
  @IBOutlet weak var threeStarButton: UIButton!
  @IBOutlet weak var twoStarButton: UIButton!
  @IBOutlet weak var oneStarButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var reviewsLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var chainLabel: UILabel!
  var currentMiniApp: MiniApp
  
  init(miniApp: MiniApp) {
    self.currentMiniApp = miniApp
    super.init(nibName: MiniAppDetailViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.titleLabel.text = self.currentMiniApp.category
    self.nameLabel.text = self.currentMiniApp.name
    if let url = URL(string: self.currentMiniApp.icon) {
      self.icon.setImage(with: url, placeholder: nil)
    }
    self.reviewsLabel.text = "\(self.currentMiniApp.numberOfReviews) Ratings"
    self.chainLabel.text = "Available on: \(self.currentMiniApp.chains)"
    self.detailLabel.text = self.currentMiniApp.description
    
    let rate = self.currentMiniApp.rating
    self.oneStarButton.setImage(rate >= 0.5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.twoStarButton.setImage(rate >= 1.5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.threeStarButton.setImage(rate >= 2.5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.fourStarButton.setImage(rate >= 3.5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    self.fiveStarButton.setImage(rate >= 4.5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
    
  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func onOpenDappTapped(_ sender: Any) {
    if let url = URL(string: self.currentMiniApp.url) {
      self.navigationController?.openSafari(with: url)
    }
  }
  
}
